class RTUISSManager_CovertAction extends UISSManager_CovertAction;

var array<name> SpecialSoldiers;
var bool Activated;
var int DefaultDesiredSlotsForOSFInfiltration;
var localized string strSlotProgramNote;
var RTUIScreenListener_OneSmallFavor_CI OSFListener;

defaultproperties 
{
	DefaultDesiredSlotsForOSFInfiltration=3
}

simulated protected function ModifyConfiguration(SSAAT_SquadSelectConfiguration LocConfiguration) {
    //Configuration.SpecialSoldiers = Soldiers;
}

simulated protected function AugmentFakeMissionSite(XComGameState_MissionSite FakeMissionSite)
{
	local XComGameState_CovertAction CovertAction;
	local name SpecialSoldier;
	local XComGameState_MissionSite MissionSiteState;

	`RTLOG("RTCI: AugmentFakeMissionSite is activated: " $ Activated);

	CovertAction = GetAction();
	if (isInfiltration()) {
		// Show the enviromental sitreps on loadout
		FakeMissionSite.GeneratedMission.SitReps = class'X2Helper_Infiltration'.static.GetMissionSiteFromAction(CovertAction).GeneratedMission.SitReps;
		if(Activated && SpecialSoldiers.Length == 0) {
			MissionSiteState = class'X2Helper_Infiltration'.static.GetMissionSiteFromAction(CovertAction);
			SpecialSoldiers = `RTS.GetProgramState().GetSquadForMission(MissionSiteState.GetReference()).GetSoldiersAsSpecial();
		}
	} else {
		if(Activated && SpecialSoldiers.Length == 0) {
			SpecialSoldiers = `RTS.GetProgramState().GetSquadForCovertAction(CovertAction.GetReference()).GetSoldiersAsSpecial();
		}
	}
	
	if(Activated) {
		foreach SpecialSoldiers(SpecialSoldier) {
			`RTLOG("RTCI: AugmentFakeMissionSite: Adding a " $ SpecialSoldier $ " to the SpecialSoldiers for Mission " $ FakeMissionSite.GeneratedMission.Mission.MissionName);
			FakeMissionSite.GeneratedMission.Mission.SpecialSoldiers.AddItem(SpecialSoldier);
		}
	}
}

simulated function bool isInfiltration() {
	return class'X2Helper_Infiltration'.static.IsInfiltrationAction(GetAction());
}

simulated protected function OnLaunch()
{
	super.OnLaunch();

	OSFListener.bConfirmScreenWasOpened = true;
}


simulated protected function BuildConfiguration()
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_CovertAction CovertAction;
	local XComGameState_Reward RewardState;

	local array<SSAAT_SlotConfiguration> Slots;
	local int i;

	Configuration = new class'SSAAT_SquadSelectConfiguration';
	History = `XCOMHISTORY;

	CovertAction = GetAction();
	
	if(!Activated) {
		`RTLOG("OSF was not activated, building default slots");
		Slots = BuildDefaultSlots();
	} else if(Activated && isInfiltration()) {
		`RTLOG("OSF was activated for Infiltration, building infiltration slots");
		Slots = BuildOSFInfiltrationSlots();
	} else if(Activated && !isInfiltration()) {
		`RTLOG("OSF was activated for CA, building CA slots");
		Slots = BuildOSFCovertActionSlots();
	} else {
		`RTLOG("RTCI: Failed to build slots!", true, true);
		Slots = BuildDefaultSlots();
	}

	Configuration.SetDisallowAutoFill(true);
	Configuration.SetSkipIntroAnimation(SkipIntro);

	`RTLOG("RTCI: Slots.Length = " $ Slots.Length);

	Configuration.SetSlots(Slots);
	Configuration.SetHideMissionInfo(true);
	Configuration.RemoveTerrainAndEnemiesPanels();
	
	Configuration.SetCanClickLaunchFn(CanClickLaunch);
	Configuration.SetLaunchBehaviour(OnLaunch, false);

	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(CovertAction))
	{
		Configuration.EnableLaunchLabelReplacement(strConfirmInfiltration, "");
	}
	else
	{
		Configuration.EnableLaunchLabelReplacement(class'UICovertActions'.default.CovertActions_LaunchAction, "");
	}
	
	Configuration.SetAugmentFakeMissionSiteFn(AugmentFakeMissionSite);
	Configuration.SetPreventOnSizeLimitedEvent(true);
	Configuration.SetPreventOnSuperSizeEvent(true);

    ModifyConfiguration(Configuration);

    Configuration.SetFrozen();
}

simulated protected function array<SSAAT_SlotConfiguration> BuildDefaultSlots(optional array<int> OverrideSlots) {
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_CovertAction CovertAction;
	local XComGameState_Reward RewardState;
	local array<SSAAT_SlotConfiguration> Slots;
	local int i;

	CovertAction = GetAction();

	Slots.Length = CovertAction.StaffSlots.Length;
	History = `XCOMHISTORY;

	for (i = 0; i < Slots.Length; ++i)
	{
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(CovertAction.StaffSlots[i].StaffSlotRef.ObjectID));
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(CovertAction.StaffSlots[i].RewardRef.ObjectID));

		if (RewardState != none) Slots[i].Notes.AddItem(ConvertRewardToNote(RewardState));
		if (CovertAction.StaffSlots[i].bOptional) Slots[i].Notes.AddItem(CreateOptionalNote());
		if (StaffSlotState.RequiredClass != '') Slots[i].Notes.AddItem(CreateClassNote(StaffSlotState.RequiredClass));
		// The original covert action staff slot code never passed a class here. We're passing one. If `RequiredClass` == '' or the class doesn't
		// have explicit rank names set up, it'll use the standard code path of falling back to the default ranks.
		if (StaffSlotState.RequiredMinRank > 0) Slots[i].Notes.AddItem(CreateRankNote(StaffSlotState.RequiredMinRank, StaffSlotState.RequiredClass));
		
		if(OverrideSlots.Length > 0) {
			if(OverrideSlots.Find(i) != INDEX_NONE) {
				Slots[i].Notes.AddItem(CreateProgramNote());
			}
		}

		// Change the slot type if needed
		if (StaffSlotState.IsEngineerSlot())
		{
			Slots[i].PersonnelType = eUIPersonnel_Engineers;
		}
		else if (StaffSlotState.IsScientistSlot())
		{
			Slots[i].PersonnelType = eUIPersonnel_Scientists;
		}

		Slots[i].CanUnitBeSelectedFn = CanSelectUnit;
	}

	return Slots;
}

simulated protected function array<SSAAT_SlotConfiguration> BuildOSFCovertActionSlots() {
	local array<int> OverrideSlots;

	OverrideSlots.AddItem(0);

	return BuildDefaultSlots(OverrideSlots);
}

simulated protected function array<SSAAT_SlotConfiguration> BuildOSFInfiltrationSlots() {
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_CovertAction CovertAction;
	local XComGameState_Reward RewardState;
	local array<SSAAT_SlotConfiguration> Slots;
	local SSAAT_SlotConfiguration NewSlot, EmptySlot;
	local int DesiredSlots, i;

	History = `XCOMHISTORY;
	CovertAction = GetAction();

	`RTLOG("Building SSAAT Slots for OSF Infiltration!");

	for (i = 0; i < CovertAction.StaffSlots.Length; ++i)
	{
		`RTLOG("Adding a slot!");
		NewSlot = EmptySlot;
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(CovertAction.StaffSlots[i].StaffSlotRef.ObjectID));
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(CovertAction.StaffSlots[i].RewardRef.ObjectID));

		if (RewardState != none) NewSlot.Notes.AddItem(ConvertRewardToNote(RewardState));
		if (CovertAction.StaffSlots[i].bOptional) NewSlot.Notes.AddItem(CreateProgramNote());
		if (StaffSlotState.RequiredClass != '') NewSlot.Notes.AddItem(CreateClassNote(StaffSlotState.RequiredClass));
		// The original covert action staff slot code never passed a class here. We're passing one. If `RequiredClass` == '' or the class doesn't
		// have explicit rank names set up, it'll use the standard code path of falling back to the default ranks.
		if (StaffSlotState.RequiredMinRank > 0) NewSlot.Notes.AddItem(CreateRankNote(StaffSlotState.RequiredMinRank, StaffSlotState.RequiredClass));
		
		// Change the slot type if needed
		if (StaffSlotState.IsEngineerSlot())
		{
			NewSlot.PersonnelType = eUIPersonnel_Engineers;
		}
		else if (StaffSlotState.IsScientistSlot())
		{
			NewSlot.PersonnelType = eUIPersonnel_Scientists;
		}

		NewSlot.CanUnitBeSelectedFn = CanSelectUnit;

		Slots.AddItem(NewSlot);
		`RTLOG("Added a slot!");
	}

	DesiredSlots = max(`RTS.GetProgramState().GetSquadForMission(class'X2Helper_Infiltration'.static.GetMissionSiteFromAction(GetAction()).GetReference()).Operatives.Length, default.DefaultDesiredSlotsForOSFInfiltration);
	`RTLOG("Removing slots, DesiredSlots =" $ DesiredSlots);
	while(Slots.Length > DesiredSlots) {
		RemoveSlotByImportance(Slots);
		`RTLOG("Removed a slot, Slots.Length=" $ Slots.Length);
	}

	return Slots;
}

simulated protected function RemoveSlotByImportance(out array<SSAAT_SlotConfiguration> Slots) {
	local int i;

	if(Slots.Length == 0) return;

	// first remove 'basic' (optional, no rewards) soldier slots
	for(i = 0; i < Slots.Length; ++i) {
		if(IsBasicSlotFromNotes(Slots[i])) {
			Slots.Remove(i, 1);
			return;
		}
	}

	// then remove soldier slots without rewards
	for(i = 0; i < Slots.Length; ++i) {
		if(IsSoldierSlotFromNotes(Slots[i], false)) {
			Slots.Remove(i, 1);
			return;
		}
	}

	// then remove soldier slots with rewards
	for(i = 0; i < Slots.Length; ++i) {
		if(IsSoldierSlotFromNotes(Slots[i], true)) {
			Slots.Remove(i, 1);
			return;
		}
	}

	// then remove nonsoldier slots without rewards
	for(i = 0; i < Slots.Length; ++i) {
		if(IsNoncombatantSlotFromNotes(Slots[i], false)) {
			Slots.Remove(i, 1);
			return;
		}
	}
	// then remove nonsoldier slots with rewards
	for(i = 0; i < Slots.Length; ++i) {
		if(IsNoncombatantSlotFromNotes(Slots[i], true)) {
			Slots.Remove(i, 1);
			return;
		}
	}
	// then just remove a slot
	for(i = 0; i < Slots.Length; ++i) {
		Slots.Remove(i, 1);
		return;
	}
}

simulated protected function bool IsBasicSlotFromNotes(SSAAT_SlotConfiguration Slot) {
	local SSAAT_SlotNote IteratorNote;
	local bool OptionalNoteFound;

	foreach Slot.Notes(IteratorNote) {
		if(IteratorNote.Text == default.strSlotOptionalNote) {
			OptionalNoteFound = true;
		}
	}

	return OptionalNoteFound && IsSoldierSlotFromNotes(Slot, false);
}

simulated protected function bool IsSoldierSlotFromNotes(SSAAT_SlotConfiguration Slot, bool HasReward) {
	local SSAAT_SlotNote IteratorNote;
	local bool RewardNoteFound;

	if(Slot.PersonnelType != eUIPersonnel_Soldiers) { return false; }

	foreach Slot.Notes(IteratorNote) {
		// Wow, is it brittle or what
		if(IteratorNote.BGColor == class'UIUtilities_Colors'.const.GOOD_HTML_COLOR) {
			RewardNoteFound = true;
		}
	}

	return HasReward == RewardNoteFound;
}

simulated protected function bool IsNoncombatantSlotFromNotes(SSAAT_SlotConfiguration Slot, bool HasReward) {
	local SSAAT_SlotNote IteratorNote;
	local bool RewardNoteFound;

	if(Slot.PersonnelType == eUIPersonnel_Soldiers) { return false; }

	foreach Slot.Notes(IteratorNote) {
		// Wow, is it brittle or what
		if(IteratorNote.BGColor == class'UIUtilities_Colors'.const.GOOD_HTML_COLOR) {
			RewardNoteFound = true;
		}
	}

	return HasReward == RewardNoteFound;
}

simulated protected function bool IsBasicSlot(XComGameState_Reward RewardState, XComGameState_StaffSlot StaffSlotState, CovertActionStaffSlot Slot) {
	return RewardState == none && StaffSlotState.isSoldierSlot() && Slot.bOptional && StaffSlotState.RequiredMinRank < 1;
}

static function SSAAT_SlotNote CreateProgramNote()
{
	local SSAAT_SlotNote Note;
	
	Note.Text = default.strSlotProgramNote; // The localized text reads "PROGRAM"
	Note.TextColor = `RTS.GetProgramColor(eRTColor_ProgramRed);
	Note.BGColor = `RTS.GetProgramColor(eRTColor_ProgramWhite);

	return Note;
}