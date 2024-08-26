namespace Api
{
    const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";
    
    string GetWSID() { return cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId; }
    string GetRecordsReqUrlBase() { return "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" 
                                        + GetWSID() + "," + s314ke_id + "&mapId=";}
    string GetCampaignsReqUrlBase(const CampaignType&in campaign_type)
    {
        if (campaign_type == CampaignType::Nadeo)
            return "https://live-services.trackmania.nadeo.live/api/token/campaign/official?offset=0&length=1000"; // 1000 to get all of them
        else if (campaign_type == CampaignType::Totd)
            return "https://live-services.trackmania.nadeo.live/api/token/campaign/month?offset=0&length=1000"; // 1000 to get all of them
        else if (campaign_type == CampaignType::Other)
            return "https://openplanet.dev/plugin/s314kemedals/config/other_campaigns";
        else 
            return "";
    }
    
    void AddUserAgent(Net::HttpRequest@ req)
    {
        req.Headers['User-Agent'] = "Openplanet plugin: " + Meta::ExecutingPlugin().Name + 
                                    " / made by " + Meta::ExecutingPlugin().Author + " / contact: mm6205@duck.com";
    }

    // -----------------------------------------------------------------------------------------------
    // ------------------------------------- PB UPDATE COROUTINE -------------------------------------
    // -----------------------------------------------------------------------------------------------

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
    void OnMapChanged(const string&in last_map_uid) 
    {
        Map@ last_map;
        if (!MyJson::map_uid_to_handle.Exists(last_map_uid))
            return;

        MyJson::map_uid_to_handle.Get(last_map_uid, @last_map);

        last_map.campaign.map_records_coroutines_running++;
        startnew(CoroutineFuncUserdata(LoadRecordsForSingleMapCoro), LoadRecordsForSingleMapCoroData(last_map, true));
    }

    // -------------------------------------------------------------------------------------------------
    // ------------------------------------- LOADING CAMPAIGNS DATA -------------------------------------
    // -------------------------------------------------------------------------------------------------

    void LoadListOfCampaigns(array<Campaign@>@ campaigns_list, const CampaignType&in campaign_type)
    {
        campaigns_list.Resize(0);
        string req_url = GetCampaignsReqUrlBase(campaign_type);

        LoadListOfCampaignsCoroutineData data(req_url, campaigns_list, campaign_type);
        if (campaign_type == CampaignType::Other)
            startnew(CoroutineFuncUserdata(LoadListOfCampaignsCoroutineOther), data);
        else
            startnew(CoroutineFuncUserdata(LoadListOfCampaignsCoroutine), data);
    }

    class LoadListOfCampaignsCoroutineData
    {
        string req_url;
        array<Campaign@>@ campaigns_list;
        CampaignType campaign_type;

        LoadListOfCampaignsCoroutineData(const string &in req_url, array<Campaign@>@ campaigns_list, const CampaignType&in campaign_type) {
            this.req_url = req_url;
            @this.campaigns_list = campaigns_list;
            this.campaign_type = campaign_type;
        }
    }

    void LoadListOfCampaignsCoroutine(ref@ _data)
    {
        auto data = cast<LoadListOfCampaignsCoroutineData>(_data);

        auto @req = NadeoServices::Get("NadeoLiveServices", data.req_url);
        AddUserAgent(req);
        req.Start();
        while (!req.Finished()) yield();

        MyJson::LoadListOfCampaignsFromJson(req.Json(), data.campaigns_list, data.campaign_type);
    }

    void LoadListOfCampaignsCoroutineOther(ref@ _data)
    {
        auto data = cast<LoadListOfCampaignsCoroutineData>(_data);

        auto @op_req = Net::HttpGet(data.req_url);
        while (!op_req.Finished()) yield();

        Json::Value config = op_req.Json();
        for (uint i = 0; i < config.Length; i++)
        {
            data.req_url = "https://live-services.trackmania.nadeo.live/api/token/club/" +
                        string(config[i]["clubID"]) + "/campaign/" + string(config[i]["campaignID"]);

            // TODO if this is done by coroutines, the list of campaigns will have to be sorted or else the order will change every time
            auto @req = NadeoServices::Get("NadeoLiveServices", data.req_url);
            AddUserAgent(req);
            req.Start();
            while (!req.Finished()) yield();

            auto other_json = req.Json();
            other_json["shortName"] = config[i]["shortName"];
            MyJson::LoadListOfCampaignsFromJson(other_json, data.campaigns_list, CampaignType::Other);
        }
    }

    // ---------------------------------------------------------------------------------------------
    // ------------------------------------- LOADING MAPS DATA -------------------------------------
    // ---------------------------------------------------------------------------------------------

    bool load_maps_lock = false;
    // loads maps data (including records) for the specified campaign
    void LoadMaps(Campaign@ campaign)
    {
        // prevents loading the same campaign multiple times after spamming the button before the 'maps_loaded' flag is set
        while (load_maps_lock) yield();

        if (campaign.maps_loaded || campaign.AreRecordsLoading()) return;
        load_maps_lock = true;

        string req_url = "https://live-services.trackmania.nadeo.live/api/token/map/get-multiple?mapUidList=";
        req_url += MyJson::GetMapUidsAsString(campaign);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", req_url);
        AddUserAgent(req);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadCampaignContents(campaign, req.Json());
        startnew(CoroutineFuncUserdata(LoadMapsCoro), LoadMapsCoroData(campaign));
        
        load_maps_lock = false;
    }

    
    class LoadMapsCoroData
    {
        Campaign@ campaign;

        LoadMapsCoroData(Campaign@ campaign) {
            @this.campaign = campaign;
        }
    }

    void LoadMapsCoro(ref@ _data)
    {
        auto data = cast<LoadMapsCoroData>(_data);
        auto @maps = data.campaign.maps;
        
        data.campaign.map_records_coroutines_running = maps.Length;
        for (uint i = 0; i < maps.Length; i++)
            startnew(CoroutineFuncUserdata(LoadRecordsForSingleMapCoro), LoadRecordsForSingleMapCoroData(maps[i], true));

        while (data.campaign.AreRecordsLoading()) yield(); // wait for the map records before saving data
        
        data.campaign.maps_loaded = true;
        MyJson::SaveMapsDataToJson(data.campaign);
    }
    
    class LoadRecordsForSingleMapCoroData
    {
        Map@ map;
        bool decrement_counter;

        LoadRecordsForSingleMapCoroData(Map@ map, bool decrement_counter) {
            @this.map = map;
            this.decrement_counter = decrement_counter;
        }
    }

    void LoadRecordsForSingleMapCoro(ref@ _data)
    {
        auto data = cast<LoadRecordsForSingleMapCoroData>(_data);
        string req_url = GetRecordsReqUrlBase() + data.map.id;
        Net::HttpRequest@ req = NadeoServices::Get("NadeoServices", req_url);
        AddUserAgent(req);
        req.Start();
        while (!req.Finished()) yield();

        MyJson::LoadRecordsForSingleMap(data.map, req.Json());

        if (data.decrement_counter)
        {
            if (data.map.campaign is null)
            {
                error("Map is not a part of campaign.");
                return;
            }
            data.map.campaign.map_records_coroutines_running--;
            // save records data when all coroutines finish
            if (!data.map.campaign.AreRecordsLoading())
            {
                data.map.campaign.RecalculateMedalsCounts();
                MyJson::SaveMapsDataToJson(data.map.campaign);
            }
        }
    }
}
