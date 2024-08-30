namespace Api
{
    const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";
    
    string GetWSID() { return cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId; }
    string GetRecordsReqUrlBase() { return "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" 
                                        + GetWSID() + "," + s314ke_id + "&mapId=";}
    
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
        startnew(CoroutineFuncUserdata(FetchRecordsForSingleMapCoro), 
                 FetchRecordsForSingleMapCoroData(last_map, true));
    }

    // ---------------------------------------------------------------------------------------------
    // ------------------------------------- LOADING MAPS DATA -------------------------------------
    // ---------------------------------------------------------------------------------------------

    bool fetch_maps_lock = false;
    // loads maps data (including records) for the specified campaign
    void FetchMapsInfo(Campaign@ campaign)
    {
        // prevents loading the same campaign multiple times after spamming the button before the 'maps_loaded' flag is set
        while (fetch_maps_lock) yield();

        if (campaign.maps_loaded || campaign.AreRecordsLoading()) return;
        fetch_maps_lock = true;

        string req_url = "https://live-services.trackmania.nadeo.live/api/token/map/get-multiple?mapUidList=";
        req_url += MyJson::GetMapUidsAsString(campaign);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", req_url);
        AddUserAgent(req);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadMapsInfo(campaign, req.Json());
        startnew(CoroutineFuncUserdata(FetchMapsInfoCoro), campaign);
        
    }

    void FetchMapsInfoCoro(ref@ _data)
    {
        Campaign@ campaign = cast<Campaign>(_data);
        auto @maps = campaign.maps;
        
        campaign.map_records_coroutines_running = maps.Length;
        for (uint i = 0; i < maps.Length; i++)
            startnew(CoroutineFuncUserdata(FetchRecordsForSingleMapCoro), 
                     FetchRecordsForSingleMapCoroData(maps[i], true));

        while (campaign.AreRecordsLoading()) yield(); // wait for the map records before saving data
        
        campaign.maps_loaded = true;
        fetch_maps_lock = false;
        MyJson::SaveMapsDataToJson(campaign);
    }
    
    class FetchRecordsForSingleMapCoroData
    {
        Map@ map;
        bool decrement_counter;

        FetchRecordsForSingleMapCoroData(Map@ map, bool decrement_counter) {
            @this.map = map;
            this.decrement_counter = decrement_counter;
        }
    }

    void FetchRecordsForSingleMapCoro(ref@ _data)
    {
        auto data = cast<FetchRecordsForSingleMapCoroData>(_data);
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
