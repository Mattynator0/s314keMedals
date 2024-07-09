// Ideas:
//
// - add overall counters for nadeo and totd campaign selection tabs
//
// - add a list/tile display modes to DrawCampaignSelectionMenu, where list would also show the medals progress for each campaign
//
// - add a checkbox for only displaying the maps where a s314ke medal exists and another one for only displaying unbeaten s314ke medals
//
// - cache some information like medal counts for each campaign
//
// - add some kind of styling to campaign selection buttons and highlight the chosen campaign button for visual clarity
//
// - tie the number of buttons per row in campaign selection menu to the window width (remove the first button offset?)
//
// - reduce the cached jsons' contents to only what is actually used in the code
//
// - add additional permission checks (e.g. Permissions::PlayPastOfficialQuarterlyCampaign())
//   (might not actually do anything, idk)
//

Browser@ browser;
bool user_has_permissions;

void Main()
{
	user_has_permissions = Permissions::PlayLocalMap() && Permissions::PlayTOTDChannel();

	NadeoServices::AddAudience("NadeoLiveServices");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	NadeoServices::AddAudience("NadeoServices");
    while (!NadeoServices::IsAuthenticated("NadeoServices")) yield();

	@browser = Browser();
}

void RenderInterface()
{
	if (browser is null)
	{
		UI::SetNextWindowSize(100, 60);
		UI::Begin("s314ke Medals");
		UI::Text("Loading...");
		UI::End();
		return;
	}
	browser.Draw();
}

void RenderMenu() {
    if (browser !is null)
		browser.RenderMenu();
}
