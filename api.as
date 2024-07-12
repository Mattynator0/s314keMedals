namespace Api
{
    // TODO line 77 of https://gitlab.com/naninf/champion-medals/-/blob/main/src/data/Api.as?ref_type=heads
    //      does something interesting with sending a json file using Post() and gets the specified data back

    const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";
    const string local_user_id = cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId;

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

    class LoadRecordsCoroutineData
    {
        string req_url;
        Campaign@ campaign;

        LoadRecordsCoroutineData(const string &in req_url, Campaign@ campaign) {
            this.req_url = req_url;
            @this.campaign = campaign;
        }
    }

    void LoadS314keMedalsAndPBs(Campaign@ campaign)
    {
        string req_url_base = "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=";

        req_url_base += local_user_id;
        req_url_base += ",";
        req_url_base += s314ke_id;
        req_url_base += "&mapId=";

        for (uint i = 0; i < campaign.maps.Length; i++)
        {
            string req_url = req_url_base;
            req_url += campaign.maps[i].id;

            LoadRecordsCoroutineData coroutine_data(req_url, campaign);

            startnew(CoroutineFuncUserdata(LoadS314keMedalsAndPBsCoroutine), coroutine_data);
        }
    }

    void LoadS314keMedalsAndPBsCoroutine(ref@ _data) {
        auto data = cast<LoadRecordsCoroutineData>(_data);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoServices", data.req_url);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadMapRecords(data.campaign, req);
    }
}
