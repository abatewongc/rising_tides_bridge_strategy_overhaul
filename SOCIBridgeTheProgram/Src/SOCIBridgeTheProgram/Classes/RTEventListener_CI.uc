class RTEventListener_CI extends X2EventListener config(ProgramFaction);

// Stolen from RealityMachina
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(HandleCovertActionCompleted());

	return Templates;
}

//`XEVENTMGR.TriggerEvent('CovertActionCompleted', , self, NewGameState);
static function CHEventListenerTemplate HandleCovertActionCompleted()
{

    local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'RTSOCI_CovertActionCompleted');
	Template.AddCHEvent('CovertActionCompleted', OnCovertActionCompleted, ELD_Immediate, 90);
	Template.RegisterInStrategy = true;

	return Template;
}

// EventData is none
// EventSource is the XCGS_CovertAction
// GameState is New
static protected function EventListenerReturn OnCovertActionCompleted(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
    local RTGameState_ProgramFaction ProgramState;
    local RTGameState_PersistentGhostSquad SquadState, NewSquadState;
    local XComGameState_CovertAction ActionState;
    local StateObjectReference EmptyRef;

    `RTLOG("OnCovertActionComplete");
    
    ActionState = XComGameState_CovertAction(EventSource);
    if(ActionState == none) {
        `RTLOG("OnCovertActionCompleted recieved a none ActionState?!");
        return ELR_NoInterrupt;
    }

    ProgramState = `RTS.GetProgramState();
    SquadState = ProgramState.GetSquadForCovertAction(ActionState.GetReference(), true);
    if(SquadState == none) {
        // this is the usual outcome. return 
        `RTLOG("Did not find a deployed Program Squad for Covert Action with ObjectID " $ ActionState.GetReference().ObjectID);
        return ELR_NoInterrupt;
    }

    `RTLOG("Found a deployed squad. Recovering them.");
    // we were deployed on this CA. Need to modify the gamestate.
    ProgramState = `RTS.GetNewProgramState(NewGameState);
    SquadState = RTGameState_PersistentGhostSquad(NewGameState.ModifyStateObject(class'RTGameState_PersistentGhostSquad', SquadState.ObjectID));
    SquadState.DeploymentRef = EmptyRef;

    // we don't need to submit anything because we receieved a NewGameState
	return ELR_NoInterrupt;
}