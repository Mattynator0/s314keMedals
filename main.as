// s314ke Medals by Mattynator

Browser@ browser;
bool user_has_permissions;

void Main()
{
	user_has_permissions = Permissions::PlayLocalMap() && Permissions::PlayTOTDChannel();

	NadeoServices::AddAudience("NadeoLiveServices");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	NadeoServices::AddAudience("NadeoServices");
    while (!NadeoServices::IsAuthenticated("NadeoServices")) yield();

	MyJson::CreatePluginStorageFolders();

	@browser = Browser();
	startnew(Api::WatchForMapChange);
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
