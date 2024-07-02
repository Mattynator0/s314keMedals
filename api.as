namespace Api
{
    // TODO line 77 of https://gitlab.com/naninf/champion-medals/-/blob/main/src/data/Api.as?ref_type=heads
    //      does something interesting with sending a json file using Post() and gets the specified data back

    const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";

    void LoadCampaigns(array<Campaign@>& campaigns, CampaignType campaign_type)
    {
        string req_url;
        if (campaign_type == CampaignType::Nadeo)
            req_url = "https://live-services.trackmania.nadeo.live/api/token/campaign/official?offset=0&length=1000"; // 1000 to get all of them
        else
            req_url = "https://live-services.trackmania.nadeo.live/api/token/campaign/month?offset=0&length=1000"; // 1000 to get all of them
            
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", req_url);
        req.Start();
        while (!req.Finished()) yield();

        MyJson::ParseAndLoadCampaignsFromJson(req, campaigns, campaign_type);
    }

    //FIXME lock might be unnecessary/badly implemented
    bool load_maps_lock = false;
    void LoadMaps(Campaign@ campaign)
    {
        while (load_maps_lock) yield();

        if (campaign.maps_loaded) return; // prevents loading the same campaign multiple times after spamming the button before the flag is set
        load_maps_lock = true;

        string req_url = "https://live-services.trackmania.nadeo.live/api/token/map/get-multiple?mapUidList=";

        req_url += MyJson::GetMapUidsAsString(campaign);

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", req_url);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadCampaignContents(campaign, req);

        LoadS314keMedalsAndPBs(campaign);

        campaign.maps_loaded = true;
        load_maps_lock = false;
        campaign.RecalculateMedalsCounts();
    }

    void LoadS314keMedalsAndPBs(Campaign@ campaign)
    {
        string req_url = "https://prod.trackmania.core.nadeo.online/mapRecords/?accountIdList=";

        req_url += cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId;
        req_url += ",";
        req_url += s314ke_id;

        req_url += "&mapIdList=";
        for (uint i = 0; i < campaign.maps.Length - 1; i++)
        {
            req_url += campaign.maps[i].id;
            req_url += ",";
        }
        req_url += campaign.maps[campaign.maps.Length - 1].id;

        Net::HttpRequest@ req = NadeoServices::Get("NadeoServices", req_url);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadMapRecords(campaign, req);
    }
}
