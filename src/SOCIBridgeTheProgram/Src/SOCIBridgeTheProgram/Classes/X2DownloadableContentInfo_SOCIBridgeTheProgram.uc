class X2DownloadableContentInfo_SOCIBridgeTheProgram extends X2DownloadableContentInfo;

static function RTLog(string message, optional bool bShouldRedScreenToo = false, optional bool bShouldOutputToConsoleToo = false) {
	local name mod;

	mod = 'RisingTidesSOCIBridge';

	`LOG(message, true, mod);
	if(bShouldRedScreenToo) {
		`RedScreen(mod $ ": " $ message);
	}
	if(bShouldOutputToConsoleToo) {
		class'Helpers'.static.OutputMsg(mod $ ": " $ message);
	}
}

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
//static event OnLoadedSavedGame()
//{
//
//}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
//static event OnLoadedSavedGameToStrategy()
//{
//
//}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
//static event InstallNewCampaign(XComGameState StartState)
//{
//
//}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
//static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
//{
//
//}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
//static event OnPostMission()
//{
//
//}

/// <summary>
/// Called when the player is doing a direct tactical->tactical mission transfer. Allows mods to modify the
/// start state of the new transfer mission if needed
/// </summary>
//static event ModifyTacticalTransferStartState(XComGameState TransferStartState)
//{
//
//}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
//static event OnExitPostMissionSequence()
//{
//
//}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
    `RTLOG("Strategy Overhaul: Covert Infiltration Bridge Loading...");
    PatchCICovertActionsWithProgramNarratives();
    `RTLOG("Strategy Overhaul: Covert Infiltration Bridge Loaded.");
}

static function PatchCICovertActionsWithProgramNarratives() {
	local X2StrategyElementTemplateManager Manager;
	local array<X2StrategyElementTemplate> AllActionTemplates;
	local X2StrategyElementTemplate DataTemplate;
	local X2CovertActionTemplate ActionTemplate;

	Manager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	AllActionTemplates = Manager.GetAllTemplatesOfClass(class'X2CovertActionTemplate');

	foreach AllActionTemplates(DataTemplate)
	{
		ActionTemplate = X2CovertActionTemplate(DataTemplate);
		if (ActionTemplate != none)
		{
			if(ActionTemplate.DataName == 'CovertAction_UtilityItems') {
                `RTLOG("Found CovertAction_UtilityItems, patching...");
				ActionTemplate.Narratives.AddItem('CovertActionNarrative_UtilityItems_Program');
            }

			if(ActionTemplate.DataName == 'CovertAction_ExperimentalItem') {
                `RTLOG("Found CovertAction_ExperimentalItem, patching...");
				ActionTemplate.Narratives.AddItem('CovertActionNarrative_ExperimentalItem_Program');
            }

			if(ActionTemplate.DataName == 'CovertAction_ExhaustiveTraining') {
                `RTLOG("Found CovertAction_ExhaustiveTraining, patching...");
				ActionTemplate.Narratives.AddItem('CovertActionNarrative_ExhaustiveTraining_Program');
            }

			if(ActionTemplate.DataName == 'CovertAction_PatrolWilderness') {
                `RTLOG("Found CovertAction_PatrolWilderness, patching...");
				ActionTemplate.Narratives.AddItem('CovertActionNarrative_AlienCorpses_Program');
            }

			if(ActionTemplate.DataName == 'CovertAction_IncreaseIncome') {
                `RTLOG("Found CovertAction_IncreaseIncome, patching...");
				ActionTemplate.Narratives.AddItem('CovertActionNarrative_PatrolWilderness_Program');
            }

			if(ActionTemplate.DataName == 'CovertAction_BlackMarket') {
                `RTLOG("Found CovertAction_BlackMarket, patching...");
				ActionTemplate.Narratives.AddItem('CovertActionNarrative_BlackMarket_Program');
            }
		}
	}
}

exec function DebugBridgeMod() {
	local name n;

	foreach class'X2StrategyElement_DefaultCovertActionNarratives'.default.CovertActionNarratives(n) {
		`RTLOG("" $ n);
	}
}


/// <summary>
/// Called when the difficulty changes and this DLC is active
/// </summary>
//static event OnDifficultyChanged()
//{
//
//}

/// <summary>
/// Called by the Geoscape tick
/// </summary>
//static event UpdateDLC()
//{
//
//}

/// <summary>
/// Called after HeadquartersAlien builds a Facility
/// </summary>
//static event OnPostAlienFacilityCreated(XComGameState NewGameState, StateObjectReference MissionRef)
//{
//
//}

/// <summary>
/// Called after a new Alien Facility's doom generation display is completed
/// </summary>
//static event OnPostFacilityDoomVisualization()
//{
//
//}

/// <summary>
/// Called when viewing mission blades with the Shadow Chamber panel, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
//static function bool UpdateShadowChamberMissionInfo(StateObjectReference MissionRef)
//{
//	return false;
//}

/// <summary>
/// A dialogue popup used for players to confirm or deny whether new gameplay content should be installed for this DLC / Mod.
/// </summary>
//static function EnableDLCContentPopup()
//{
//	local TDialogueBoxData kDialogData;
//
//	kDialogData.eType = eDialog_Normal;
//	kDialogData.strTitle = default.EnableContentLabel;
//	kDialogData.strText = default.EnableContentSummary;
//	kDialogData.strAccept = default.EnableContentAcceptLabel;
//	kDialogData.strCancel = default.EnableContentCancelLabel;
//
//	kDialogData.fnCallback = EnableDLCContentPopupCallback_Ex;
//	`HQPRES.UIRaiseDialog(kDialogData);
//}

//simulated function EnableDLCContentPopupCallback_Ex(eUIAction eAction)
//{
//	
//}



/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
//static function bool ShouldUpdateMissionSpawningInfo(StateObjectReference MissionRef)
//{
//	return false;
//}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
//static function bool UpdateMissionSpawningInfo(StateObjectReference MissionRef)
//{
//	return false;
//}

/// <summary>
/// Called when viewing mission blades, used to add any additional text to the mission description
/// </summary>
//static function string GetAdditionalMissionDesc(StateObjectReference MissionRef)
//{
//	return "";
//}

/// <summary>
/// Called from X2AbilityTag:ExpandHandler after processing the base game tags. Return true (and fill OutString correctly)
/// to indicate the tag has been expanded properly and no further processing is needed.
/// </summary>
//static function bool AbilityTagExpandHandler(string InString, out string OutString)
//{
//	return false;
//}

/// <summary>
/// Called from XComGameState_Unit:GatherUnitAbilitiesForInit after the game has built what it believes is the full list of
/// abilities for the unit based on character, class, equipment, et cetera. You can add or remove abilities in SetupData.
/// </summary>
//static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
//{
//
//}

/// <summary>
/// Calls DLC specific popup handlers to route messages to correct display functions
/// </summary>
//static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
//{
//
//}