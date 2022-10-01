class OVERRIDE_UICovertActionsGeoscape extends UICovertActionsGeoscape;

// Used to update the screen to show new covert action
simulated function UpdateData()
{
	super.UpdateData();

	if (bDontUpdateData) return;

	`XEVENTMGR.TriggerEvent('CI_UICovertActionsGeoscape_PostUpdateData', self, self, none);
}