namespace Api
{
    const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";
    const string local_user_id = cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId;

    const string records_req_url_base = "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" 
                                        + local_user_id + "," + s314ke_id + "&mapId=";
    
    void WatchForMapChange() 
    {
        string current_map_uid;
        string last_map_uid;
        auto app = cast<CGameManiaPlanet>(GetApp());

        while (true) {
            yield();
            // case 1: exiting from a map to main menu
            if (app.RootMap is null && current_map_uid != "") {
                last_map_uid = current_map_uid;
                current_map_uid = "";
                OnMapChanged(last_map_uid);
            // case 2: loading a new map while already playing a map
            } else if (app.RootMap !is null && app.RootMap.EdChallengeId != current_map_uid) {
                last_map_uid = current_map_uid;
                current_map_uid = app.RootMap.EdChallengeId;
                OnMapChanged(last_map_uid);
            }
        }
    }
    // refreshes records on the last played map
    void OnMapChanged(const string &in last_map_uid) 
    {
        // find the map uid, request records and load them into the campaign data structure
        // TODO
        Map@ last_map;

        if (!MyJson::map_uid_to_handle.Exists(last_map_uid))
            return;

        MyJson::map_uid_to_handle.Get(last_map_uid, @last_map);
        string req_url = records_req_url_base + last_map.id;

        LoadCampaignRecordsCoroutineData map_data(req_url, last_map.campaign);
        startnew(LoadCampaignRecordsCoroutine, map_data);
    }

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
        while (load_maps_lock) yield(); // prevents loading the same campaign multiple times after spamming the button before the flag is set

        if (campaign.maps_loaded) return;
        load_maps_lock = true;

        string req_url = "https://live-services.trackmania.nadeo.live/api/token/map/get-multiple?mapUidList=";

        req_url += MyJson::GetMapUidsAsString(campaign);

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", req_url);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadCampaignContents(campaign, req);

        LoadCampaignRecords(campaign);

        campaign.maps_loaded = true;
        load_maps_lock = false;
        campaign.RecalculateMedalsCounts();
    }

    class LoadCampaignRecordsCoroutineData
    {
        string req_url;
        Campaign@ campaign;

        LoadCampaignRecordsCoroutineData(const string &in req_url, Campaign@ campaign) {
            this.req_url = req_url;
            @this.campaign = campaign;
        }
    }

    void LoadCampaignRecords(Campaign@ campaign)
    {
        for (uint i = 0; i < campaign.maps.Length; i++)
        {
            string req_url = records_req_url_base;
            req_url += campaign.maps[i].id;

            LoadCampaignRecordsCoroutineData coroutine_data(req_url, campaign);

            startnew(CoroutineFuncUserdata(LoadCampaignRecordsCoroutine), coroutine_data);
        }
    }

    // requests records for a single map and puts them into a data structure
    void LoadCampaignRecordsCoroutine(ref@ _data) 
    {
        auto data = cast<LoadCampaignRecordsCoroutineData>(_data);

        Net::HttpRequest@ req = NadeoServices::Get("NadeoServices", data.req_url);
        // req.Headers['User-Agent'] = "contact here";
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadMapRecords(data.campaign, req);
    }
}
