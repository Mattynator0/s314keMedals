namespace Api
{
    const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";
    
    string GetWSID() { return cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId; }
    string GetRecordsReqUrlBase() { return "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" 
                                        + GetWSID() + "," + s314ke_id + "&mapId=";}
    
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
        string req_url = GetRecordsReqUrlBase() + last_map.id;

        LoadCampaignRecordsCoroutineData map_data(req_url, last_map.campaign);
        startnew(LoadCampaignRecordsCoroutine, map_data);
    }

    void LoadCampaignList(array<Campaign@>@ campaigns, const CampaignType&in campaign_type)
    {
        if (campaign_type == CampaignType::Other) 
        {
            LoadCampaignListOther(campaigns);
            return;
        }

        string req_url;
        if (campaign_type == CampaignType::Nadeo)
            req_url = "https://live-services.trackmania.nadeo.live/api/token/campaign/official?offset=0&length=1000"; // 1000 to get all of them
        else if (campaign_type == CampaignType::Totd)
            req_url = "https://live-services.trackmania.nadeo.live/api/token/campaign/month?offset=0&length=1000"; // 1000 to get all of them

        auto req = NadeoServices::Get("NadeoLiveServices", req_url);
        req.Start();
        while (!req.Finished()) yield();

        MyJson::LoadCampaignListFromJson(req.Json(), campaigns, campaign_type);
    }

    void LoadCampaignListOther(array<Campaign@>@ campaigns)
    {
        string req_url = "https://openplanet.dev/plugin/s314kemedals/config/other_campaigns";
        auto @op_req = Net::HttpGet(req_url);
        while (!op_req.Finished()) yield();

        Json::Value config = op_req.Json();
        Json::Value@ other_campaigns_json = Json::Object();
        other_campaigns_json["campaignList"] = Json::Array();
        for (uint i = 0; i < config.Length; i++)
        {
            req_url = "https://live-services.trackmania.nadeo.live/api/token/club/";
            req_url += config[i]["clubID"];
            req_url += "/campaign/";
            req_url += config[i]["campaignID"];

            // FIXME this is fine for very few campaigns, otherwise it's too slow to do it one by one
            auto @req = NadeoServices::Get("NadeoLiveServices", req_url);
            req.Start();
            while (!req.Finished()) yield();

            auto temp_json = req.Json();
            temp_json["name"] = config[i]["name"];
            temp_json["shortName"] = config[i]["shortName"];
            other_campaigns_json["campaignList"].Add(temp_json);
        }

        //Json::ToFile(MyJson::test_path, other_campaigns_json);

        MyJson::LoadCampaignListFromJson(other_campaigns_json, campaigns, CampaignType::Other);
    }

    bool load_maps_lock = false;
    void LoadMaps(Campaign@ campaign) // TODO adapt to the new campaign type
    {
        while (load_maps_lock) yield(); // prevents loading the same campaign multiple times after spamming the button before the flag is set

        if (campaign.maps_loaded) return;
        load_maps_lock = true;

        string req_url = "https://live-services.trackmania.nadeo.live/api/token/map/get-multiple?mapUidList=";

        req_url += MyJson::GetMapUidsAsString(campaign);

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", req_url);
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadCampaignContents(campaign, req.Json());

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
            string req_url = GetRecordsReqUrlBase();
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
        // the line below should be used if I ever decide to add a global medal counter (meaning 1000+ API calls when activating the plugin)
        // req.Headers['User-Agent'] = "contact here";
        req.Start();
        while (!req.Finished()) yield();
        
        MyJson::LoadMapRecords(data.campaign, req);
    }
}
