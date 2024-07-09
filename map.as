class Map
{
    string uid;
    string id;
    string name;
    uint s314ke_medal_time = 0;
    uint pb_time = uint(-1) - 1;
    string download_url;

    bool MedalAchieved()
    {
        return pb_time <= s314ke_medal_time;
    }

    bool MedalExists()
    {
        return s314ke_medal_time > 0;
    }

    bool PbExists()
    {
        return pb_time != uint(-1) - 1;
    }

    void PlayCoroutine()
    {
        if(!(Permissions::PlayLocalMap() && Permissions::PlayTOTDChannel())) {
            user_has_permissions = false;
            return;
        }
        
		auto app = cast<CTrackMania>(GetApp());
        if (app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed) 
        {
            app.Network.PlaygroundInterfaceScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Quit);
        }
        app.BackToMainMenu();
        while (!app.ManiaTitleControlScriptAPI.IsReady) yield();
		app.ManiaTitleControlScriptAPI.PlayMap(download_url, "", "");
    }
}