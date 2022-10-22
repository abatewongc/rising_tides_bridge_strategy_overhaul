
class RTUIScreenListener_OneSmallFavor_CI extends UIScreenListener config(ProgramCIBridge);

var UICheckbox						Checkbox;
var UIBGBox							CheckboxBG;
var UICovertActionsGeoscape         UICAG;
var StateObjectReference			ActionRef;
var bool							bDebugging;
var bool							OSFActivated;
var array<int> 						OptionalStaffSlotIndices;
var bool 							isAbort;

// oof...
var bool 							bRecursionGuard;

var config float 					OSFCheckboxDistortOnClickDuration;

var private float CHECKBOX_MARGIN;
var private float CHECKBOX_HEIGHT_OFFSET;

// Was SquadSelect confirmed
var bool bConfirmScreenWasOpened;

var string ControllerButtonIconPath;

delegate OldOnClickedDelegate(UIButton Button);

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none

	CHECKBOX_HEIGHT_OFFSET=20
	CHECKBOX_MARGIN=5

	bRecursionGuard=false
	ControllerButtonIconPath = "";
}

event OnInit(UIScreen Screen)
{
	local RTGameState_ProgramFaction Program;
	local Object ThisObj;

	if(!`DLCINFO.IsModLoaded('CovertInfiltration')) {
		return;
	}

    if(UICovertActionsGeoscape(Screen) == none) {
		return;
	}

	if(ControllerButtonIconPath == "") {
        ControllerButtonIconPath = class'UIUtilities_Input'.const.ICON_X_SQUARE;
    }
	
	
	Program = RTGameState_ProgramFaction(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	if(Program == none) {
		return;
	}

	if(!Program.bMetXCom) {
		return;
	}

	bDebugging = false;

	UICAG = UICovertActionsGeoscape(Screen);
	AddOneSmallFavorSelectionCheckBox();
	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'CI_UICovertActionsGeoscape_PostUpdateData', CI_UICAG_PostUpdateDataListener, ELD_Immediate, /*Priority*/, /*PreFilterObj*/, /**bPersistent*/, /*CallbackObj*/ ThisObj);
}

event OnRemoved(UIScreen Screen) {
	local UISquadSelect ss;
	local StateObjectReference EmptyRef;
	local Object ThisObj;

	if(!`DLCINFO.IsModLoaded('CovertInfiltration')) {
		return;
	}

	bRecursionGuard = false;

	if(UISquadSelect(Screen) != none) {
		ss = UISquadSelect(Screen);
		// If the mission was launched, we don't want to clean up the XCGS_MissionSite
		if(!bConfirmScreenWasOpened && ActionRef.ObjectID != 0) {
			if(Checkbox.bChecked) {
				`RTLOG("We didn't launch, cleaning up OSF from UISS!");
				RemoveOneSmallFavor();
			}
		} else {
			bConfirmScreenWasOpened = false;
			`RTLOG("We launched, not cleaning up OSF from UISS!");
		}

		ActionRef = EmptyRef;
		// Uncheck the checkbox
		Checkbox.SetChecked(false);
		// Normally we go back to UIGeoscape, where we don't want the checkbox
		// However, in this case we go back to UICovertActionsGeoscape, where we still need it
		//ManualGC();
	}

	if(UICovertActionsGeoscape(Screen) != none) {
		// Just avoiding a RedScreen here, not necessarily a useful check
		if(!UICAG.GetAction().bStarted && !bConfirmScreenWasOpened && ActionRef.ObjectID != 0) {
			`RTLOG("We didn't launch, cleaning up OSF from UICAG!");
			RemoveOneSmallFavor();	
		} else {
			bConfirmScreenWasOpened = false;
			`RTLOG("We launched, not cleaning up OSF from UICAG!");
		}

		ThisObj = self;
		`XEVENTMGR.UnRegisterFromEvent(ThisObj, 'CI_UICovertActionsGeoscape_UpdateData');
		ActionRef = EmptyRef;
		ManualGC();
	}
}

simulated function ManualGC() {
	`RTLOG("RTCI: ManualGC called!");
	OldOnClickedDelegate = none;
    UICAG = none;
	HandleInput(false);
	if(Checkbox != none) {
		Checkbox.Remove();
		Checkbox = none;
	}

	if(CheckboxBG != none) {
		CheckboxBG.Remove();
		CheckboxBG = none;
	}
}

function HandleInput(bool bIsSubscribing)
{
	local delegate<UIScreenStack.CHOnInputDelegate> inputDelegate;
	inputDelegate = OnUnrealCommand;
	if(bIsSubscribing)
	{
		`SCREENSTACK.SubscribeToOnInput(inputDelegate);
	}
	else
	{
		`SCREENSTACK.UnsubscribeFromOnInput(inputDelegate);
	}
}

protected function bool OnUnrealCommand(int cmd, int arg)
{
	local bool isCheckboxDisabled;

	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_X && arg == class'UIUtilities_Input'.const.FXS_ACTION_RELEASE)
	{
		// Cannot open screen during flight
		if (class'XComEngine'.static.GetHQPres().StrategyMap2D.m_eUIState != eSMS_Flight)
		{
			// flip the checkbox
			isCheckboxDisabled = Checkbox.bIsDisabled || Checkbox.bReadOnly;
			if(Checkbox != none && !isCheckboxDisabled)
			{
				Checkbox.SetChecked(!Checkbox.bChecked);
			}
			
		}
		return true;
	}
	return false;
}

simulated function AddOneSmallFavorSelectionCheckBox() {
	local RTGameState_ProgramFaction Program;
	
	Program = RTGameState_ProgramFaction(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	if(Program == none) {
		return;
	}

	if(!Program.bMetXCom) {
		return;
	}

	// immediately execute the init code if we're somehow late to the initialization party
	if(UICAG.MainActionButton.bIsVisible) {
		if(UICAG.MainActionButton.bIsInited) {
			OnMainActionButtonInited(UICAG.MainActionButton);
		} else {
			// otherwise add the button to the init delegates
			UICAG.MainActionButton.AddOnInitDelegate(OnMainActionButtonInited);	
		}
	}
	else {
		`RTLOG("Could not find a confirm button for the mission!", true);
		UICAG.MainActionButton.AddOnInitDelegate(OnMainActionButtonInited);	
	}
}

function OnMainActionButtonInited(UIPanel Panel) {
	local bool bReadOnly;
	local RTGameState_ProgramFaction Program;
	local UIButton Button;
	local UIImage ControllerIcon;
	local float PosX, PosY, LocHeight, LocWidth;
	local string strCheckboxDesc;

	if(UICAG == none) {
		`RedScreen("Error, parent is not of class 'UIMission'");
		return;
	}

	Program = RTGameState_ProgramFaction(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	Button = UIButton(Panel);
	if(Button == none) {
		`RTLOG("This isn't a button!");
	}

	// the checkbox shouldn't be clickable if the favor isn't available
	bReadOnly = !(Program.IsOneSmallFavorAvailable() == eAvailable);

	if(Button.isDisabled || UICAG.GetAction().bStarted) {
		`RTLOG("RTCI: MainActionButton is disabled or the current action is in progress, disable checkbox");
		bReadOnly = true;
	}

	if(bReadOnly) {
		strCheckboxDesc = class'RTGameState_ProgramFaction'.default.OSFCheckboxUnavailable;
	} else {
		strCheckboxDesc = class'RTGameState_ProgramFaction'.default.OSFCheckboxAvailable;
	}

	PosX = -65;
	PosY = 43;

	LocWidth = 65;
	LocHeight = 77;

	CheckboxBG = UICAG.Spawn(class'UIBGBox', UICAG.ButtonGroupWrap);
	CheckboxBG.bAnimateOnInit = false;
	CheckboxBG.InitBG('CheckboxBG');
	CheckboxBG.SetPosition(PosX, PosY);
	CheckboxBG.SetSize(LocWidth, LocHeight);

	PosX = -70;
	PosY = 66;

	Checkbox = UICAG.Spawn(class'UICheckbox', UICAG.ButtonGroupWrap);	
	Checkbox.InitCheckbox('OSFActivateCheckbox', , false, OnCheckboxChange, bReadOnly)
		.SetSize(Button.Height, Button.Height)
		//.OriginTopLeft()
		.SetPosition(PosX, PosY)
		.SetColor(class'UIUtilities_Colors'.static.ColorToFlashHex(Program.GetMyTemplate().FactionColor))
		.SetTooltipText(strCheckboxDesc, , , 10, , , true, 0.0f);
	`RTLOG("Created a checkbox at position " $ PosX $ " x and " $ PosY $ " y for UICovertActionsGeoscape");

	if(`ISCONTROLLERACTIVE) {
		ControllerIcon = UICAG.Spawn(class'UIImage', UICAG.ButtonGroupWrap);
		ControllerIcon.InitImage('RT_UICAGOSF_Checkbox_ControllerIcon', "img:///gfxGamepadIcons." $ class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ ControllerButtonIconPath);
		ControllerIcon.SetSize(25, 25);
		ControllerIcon.SetPosition(PosX + (Button.Height / 2), PosY + (Button.Height / 2));
	}

	HandleInput(true);

	// Modify the OnLaunchButtonClicked Delegate
	if(Button == none) {
		`RTLOG("Panel was not a button?", true);
	} else {
		`RTLOG("Trying to modify the go to loadout/launch button...");
		if(Button.OnClickedDelegate != ModifiedLaunchButtonClicked) {
			`RTLOG("Successfully modified!");
			OldOnClickedDelegate = Button.OnClickedDelegate;
			Button.OnClickedDelegate = ModifiedLaunchButtonClicked;
		} else {
			`RTLOG("Attempt failed. We had already modified the button.");
		}
	}
}

simulated function OnCheckboxChange(UICheckbox checkboxControl)
{
	UICAG.Movie.Pres.StartDistortUI(default.OSFCheckboxDistortOnClickDuration);
}


// EventData = UICAG
// EventSource = UICAG
// XComGameState = none
// EventID = CI_UICovertActionsGeoscape_PostUpdateData
// CallbackData = this
static function EventListenerReturn CI_UICAG_PostUpdateDataListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData) {
	local UICovertActionsGeoscape LocUICAG;
	local RTUIScreenListener_OneSmallFavor_CI thisObj;
	local RTGameState_ProgramFaction Program;
	local XComGameState_CovertAction ActionState;
	local UIButton Button;
	local bool bCheckboxNeededCreation;

	`RTLOG("CI_UICAG_PostUpdateDataListener");
	thisObj = RTUIScreenListener_OneSmallFavor_CI(CallbackData);
	LocUICAG = UICovertActionsGeoscape(EventSource);
	if(LocUICAG == none) {
		`RTLOG("Received " $ EventID $ " from a source that isn't an instance of UICovertActionsGeoscape?!");
		return ELR_NoInterrupt;
	}
	Button = LocUICAG.MainActionButton;

	bCheckboxNeededCreation = false;
	if(thisObj.Checkbox == none) {
		thisObj.UICAG = LocUICAG;
		thisObj.AddOneSmallFavorSelectionCheckBox();
		bCheckboxNeededCreation = true;
	}

	ActionState = LocUICAG.GetAction();

	if(Button.isDisabled || ActionState.bStarted) {
		`RTLOG("RTCI: MainActionButton is disabled or the current action is in progress, disable checkbox");
		thisObj.Checkbox.SetReadOnly(true);
		return ELR_NoInterrupt;
	}

	Program = `RTS.GetProgramState();
	if(Program.IsOneSmallFavorAvailable() != eAvailable) {
		`RTLOG("RTCI: Favor is not available, disable checkbox");
		thisObj.Checkbox.SetReadOnly(true);
		return ELR_NoInterrupt;
	}

	if(class'RTGameState_ProgramFaction'.default.InvalidCovertActions.Find(ActionState.GetMyTemplateName()) != INDEX_NONE) {
		`RTLOG("RTCI: Favor cannot be called on this type of CA, disable checkbox");
		thisObj.Checkbox.SetReadOnly(true);
		return ELR_NoInterrupt;
	}

	if(class'X2Helper_Infiltration'.static.IsInfiltrationAction(ActionState)) {
		if(!Program.IsThereAnAvailableSquadForMission(class'X2Helper_Infiltration'.static.GetMissionSiteFromAction(ActionState))) {
			`RTLOG("RTCI: No squad available for this infiltration, disable checkbox");
			thisObj.Checkbox.SetReadOnly(true);
			return ELR_NoInterrupt;
		 }
	} else {
		 if(!Program.IsThereAnAvailableSquadForCovertAction(ActionState)) {
			`RTLOG("RTCI: No squad available for this CA, disable checkbox");
			thisObj.Checkbox.SetReadOnly(true);
			return ELR_NoInterrupt;
		 }
	}

	thisObj.Checkbox.SetReadOnly(false);
	// Modify the OnLaunchButtonClicked Delegate
	if(Button == none) {
		`RTLOG("Panel was not a button?", true);
	} else {
		`RTLOG("Trying to modify the go to loadout/launch button...");
		if(!bCheckboxNeededCreation) {
			`RTLOG("Successfully modified!");
			thisObj.OldOnClickedDelegate = Button.OnClickedDelegate;
			Button.OnClickedDelegate = thisObj.ModifiedLaunchButtonClicked;
		} else {
			`RTLOG("Attempt failed. We had already modified the button.");
		}
	}

	`RTLOG("RTCI: Successfully updated button for OSF!");

	return ELR_NoInterrupt;
}

function ModifiedLaunchButtonClicked(UIButton Button) {
	`RTLOG("ModifiedLaunchButtonClicked!");
	if(bRecursionGuard) {
		return;
	}

	ActionRef = UICAG.GetAction().GetReference();
	if(UICAG == none) {
		`RTLOG("RTUIScreenListener_OneSmallFavor_CI::ModifiedLaunchButtonClicked: UICAG is none?!", true, false);
	}

	if(Checkbox == none) {
		`RTLOG("RTUIScreenListener_OneSmallFavor_CI::ModifiedLaunchButtonClicked: Checkbox is none?!", true, false);
	}

	if(ActionRef.ObjectID == 0) {
		`RTLOG("RTUIScreenListener_OneSmallFavor_CI::ModifiedLaunchButtonClicked: ActionRef is none?!", true, false);
	}

	if(Checkbox.bChecked) {
		OSFActivated = DoOneSmallFavor();
		OpenProgramLoadoutForCurrentAction();
	} else {
		OSFActivated = false;
		if(OldOnClickedDelegate != ModifiedLaunchButtonClicked) {
			bRecursionGuard = true;
			OldOnClickedDelegate(Button);
		}
	}
}

function bool DoOneSmallFavor() {
	local RTGameState_ProgramFaction			Program;
	local XComGameStateHistory					History;
	local XComGameState_MissionSite				MissionState;
	local XComGameState_CovertAction			ActionState;

	History = `XCOMHISTORY;
	Program = RTGameState_ProgramFaction(History.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	if(Program == none) {
		return false;
	}

	if(Program.IsOneSmallFavorAvailable() != eAvailable) {
		return false;
	}

	ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
	if(ActionState == none) {
		`RTLOG("Did not find ActionState for OSF, returning...");
		return false;
	}

	if(!class'X2Helper_Infiltration'.static.IsInfiltrationAction(ActionState)) {
		`RTLOG("RTCI: Handling OSF Covert Action!");
		return DoOneSmallFavor_CovertAction(Program, ActionState);
	} else {
		`RTLOG("Handling OSF Infiltration!");
		MissionState = class'X2Helper_Infiltration'.static.GetMissionSiteFromAction(ActionState);
		if(MissionState == none) {
			`RTLOG("RTCI: MissionState for OSF Infiltration was none?!", true, false);
			return false;
		}

		if(MissionState.GeneratedMission.SitReps.Find('RTOneSmallFavor') != INDEX_NONE) {
			`RTLOG("RTCI: This map already has the One Small Favor tag!", true);
			return false;
		}

		if(MissionState.TacticalGameplayTags.Find('RTOneSmallFavor') != INDEX_NONE) {
			`RTLOG("RTCI: This mission is already tagged for one small favor!");
			return false;
		}

		return DoOneSmallFavor_Infiltration(Program, ActionState, MissionState);
	}
}

protected function bool DoOneSmallFavor_CovertAction(RTGameState_ProgramFaction Program, XComGameState_CovertAction ActionState) {
	local XComGameState							NewGameState;

	NewGameState = `CreateChangeState("Rising Tides: Cashing in One Small Favor For Covert Action");
	Program = RTGameState_ProgramFaction(NewGameState.ModifyStateObject(Program.class, Program.ObjectID));
	ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));

	Program.CashOneSmallFavorForCovertAction(NewGameState, ActionState); // we're doing it boys
	//MakeStaffSlotsOptionalForCovertAction(NewGameState, ActionState);
	
	if (NewGameState.GetNumGameStateObjects() > 0) {
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	} else {
		`RTLOG("Warning: One Small Favor activated but didn't add any objects to the GameState?!", true);
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	return true; 
}

protected function bool DoOneSmallFavor_Infiltration(RTGameState_ProgramFaction Program, XComGameState_CovertAction ActionState, XComGameState_MissionSite MissionState) {
	local XComGameState							NewGameState;
	local XComGameState_HeadquartersXCom		XComHQ; //because the game stores a copy of mission data and this is where its stored in

	NewGameState = `CreateChangeState("Rising Tides: Cashing in One Small Favor For Infiltration");
	Program = RTGameState_ProgramFaction(NewGameState.ModifyStateObject(Program.class, Program.ObjectID));
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.class, XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));

	MissionState.TacticalGameplayTags.AddItem('RTOneSmallFavor');
	Program.CashOneSmallFavorForMission(NewGameState, MissionState); // we're doing it boys
	ModifyOneSmallFavorSitrepForGeneratedMission(Program, MissionState, true);
	ModifyMissionData(XComHQ, MissionState);
	MakeStaffSlotsOptionalForProgramInfiltration(NewGameState, ActionState);
	
	if (NewGameState.GetNumGameStateObjects() > 0) {
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	} else {
		`RTLOG("Warning: One Small Favor activated but didn't add any objects to the GameState?!", true);
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	return true;
}

function RemoveOneSmallFavor() {
	local RTGameState_ProgramFaction			Program;
	local XComGameStateHistory					History;
	local XComGameState_MissionSite				MissionState;
	local XComGameState_CovertAction			ActionState;

	History = `XCOMHISTORY;
	ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
	Program = RTGameState_ProgramFaction(History.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));

	if(ActionState == none) {
		return;
	}

	if(!class'X2Helper_Infiltration'.static.IsInfiltrationAction(ActionState)) {
		`RTLOG("RTCI: Removing OSF from Covert Action!");
		RemoveOneSmallFavor_CovertAction(Program, ActionState);
		return;
	} else {
		`RTLOG("RTCI: Removing OSF from Infiltration");
		MissionState = class'X2Helper_Infiltration'.static.GetMissionSiteFromAction(ActionState);
		if(MissionState == none) {
			`RTLOG("RTCI: MissionState for OSF Infiltration was none?!", true, false);
			return;
		}

		if(MissionState.GeneratedMission.SitReps.Find('RTOneSmallFavor') != INDEX_NONE
			&& MissionState.TacticalGameplayTags.Find('RTOneSmallFavor') != INDEX_NONE
		) {
			`RTLOG("RTCI: MissionState for OSF Infiltration was none?!", true, false);
			return;
		}

		RemoveOneSmallFavor_Infiltration(Program, ActionState, MissionState);
		return;
	}

	return;
}

protected function bool RemoveOneSmallFavor_CovertAction(RTGameState_ProgramFaction Program, XComGameState_CovertAction ActionState) {
	local XComGameState							NewGameState;

	NewGameState = `CreateChangeState("Rising Tides: Cashing in One Small Favor For Covert Action");
	Program = RTGameState_ProgramFaction(NewGameState.ModifyStateObject(Program.class, Program.ObjectID));
	ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));

	Program.UncashOneSmallFavorForCovertAction(NewGameState, ActionState); // we're doing it boys
	//RevertStaffSlotsForXComCovertAction(NewGameState, ActionState);
	
	if (NewGameState.GetNumGameStateObjects() > 0) {
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	} else {
		`RTLOG("Warning: One Small Favor activated but didn't add any objects to the GameState?!", true);
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	OSFActivated = false;

	return true; 
}

private function RemoveOneSmallFavor_Infiltration(RTGameState_ProgramFaction Program, XComGameState_CovertAction ActionState, XComGameState_MissionSite MissionState) {
	local XComGameState							NewGameState;
	local XComGameState_HeadquartersXCom		XComHQ; //because the game stores a copy of mission data and this is where its stored in

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	RemoveTag(MissionState.GeneratedMission.SitReps, 'RTOneSmallFavor');
	RemoveTag(MissionState.TacticalGameplayTags, 'RTOneSmallFavor');

	NewGameState = `CreateChangeState("Rising Tides: Uncashing in One Small Favor for Infiltration");
	Program = RTGameState_ProgramFaction(NewGameState.ModifyStateObject(Program.class, Program.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.class, XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));

	Program.UncashOneSmallFavorForMission(NewGameState, MissionState);
	ModifyOneSmallFavorSitrepForGeneratedMission(Program, MissionState, false);
	ModifyMissionData(XComHQ, MissionState);
	RevertStaffSlotsForXComInfiltration(NewGameState, ActionState);

	if (NewGameState.GetNumGameStateObjects() > 0) {
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	} else {
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	OSFActivated = false;
}

simulated function ModifyOneSmallFavorSitrepForGeneratedMission(RTGameState_ProgramFaction Program, XComGameState_MissionSite MissionState, bool bAdd = true) {
	if(bAdd) { MissionState.GeneratedMission.SitReps.AddItem(Program.GetSquadForMission(MissionState.GetReference(), false).GetAssociatedSitRepTemplateName()); }
	else { MissionState.GeneratedMission.SitReps.RemoveItem(Program.GetSquadForMission(MissionState.GetReference(), false).GetAssociatedSitRepTemplateName()); }
}

function ModifyMissionData(XComGameState_HeadquartersXCom NewXComHQ, XComGameState_MissionSite NewMissionState)
{
	local int MissionDataIndex;

	MissionDataIndex = NewXComHQ.arrGeneratedMissionData.Find('MissionID', NewMissionState.GetReference().ObjectID);

	if(MissionDataIndex != INDEX_NONE)
	{
		NewXComHQ.arrGeneratedMissionData[MissionDataIndex] = NewMissionState.GeneratedMission;
	}
}

// Record a list of all of the Covert Action Staff Slots that were optional beforehand, then make them all optional
// so that we can launch
simulated function MakeStaffSlotsOptionalForProgramInfiltration(XComGameState NewGameState, XComGameState_CovertAction ActionState) {
	local CovertActionStaffSlot Slot, EmptySlot;
	local int i;

	for(i = 0; i < ActionState.StaffSlots.Length; ++i) {
		if(ActionState.StaffSlots[i].bOptional) {
			OptionalStaffSlotIndices.AddItem(i);
		}
		ActionState.StaffSlots[i].bOptional = true;
	}
}

// Record a list of all of the Covert Action Staff Slots that were optional beforehand, then make them all optional
simulated function RevertStaffSlotsForXComInfiltration(XComGameState NewGameState, XComGameState_CovertAction ActionState) {
	local CovertActionStaffSlot Slot, EmptySlot;
	local int i;

	`RTLOG("RevertStaffSlotsForXComInfiltration");

	for(i = 0; i < ActionState.StaffSlots.Length; ++i) {
		ActionState.StaffSlots[i].bOptional = false;	
	}

	`RTLOG("Reseting optional staff slot indices...");
	foreach OptionalStaffSlotIndices(i) {
		`RTLOG("Making slot " $ i $ " optional");
		ActionState.StaffSlots[i].bOptional = true;
	}
}

private function RemoveTag(out array<name> Tags, name TagToRemove) {
	Tags.RemoveItem(TagToRemove);
}


simulated function OpenProgramLoadoutForCurrentAction(optional bool SkipIntro = false)
{
	local RTUISSManager_CovertAction SSManager;

	SSManager = new class'RTUISSManager_CovertAction';
	SSManager.Activated = OSFActivated;
	SSManager.CovertOpsScreen = UICAG;
	SSManager.OSFListener = self;
	SSManager.SkipIntro = SkipIntro;
	SSManager.OpenSquadSelect();

	UICAG.SSManager = SSManager;
}