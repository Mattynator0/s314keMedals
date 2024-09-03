class CategoryOther : CampaignCategory
{
    CategoryOther()
    {
        super(CampaignType::Other);
        campaigns_json["campaignList"] = Json::Array();
    }

    string GetCampaignsReqUrlBase() override
    {
        return "https://openplanet.dev/plugin/s314kemedals/config/other_campaigns";
    }

    void FetchListOfCampaignsCoro() override
    {
        campaigns_list.Resize(0);
        string config_url = GetCampaignsReqUrlBase();
        
        auto @config_req = Net::HttpGet(config_url);
        while (!config_req.Finished()) yield();

        auto config = config_req.Json();
        for (uint i = 0; i < config.Length; i++)
        {
            string req_url = "https://live-services.trackmania.nadeo.live/api/token/club/" +
                        string(config[i]["clubID"]) + "/campaign/" + string(config[i]["campaignID"]);

            // !!! if this is ever done by coroutines, the list of campaigns will have to be sorted or else the order will change every time
            auto @req = NadeoServices::Get("NadeoLiveServices", req_url);
            Api::AddUserAgent(req);
            req.Start();
            while (!req.Finished()) yield();

            auto other_json = req.Json();
            other_json["shortName"] = config[i]["shortName"];
            LoadListOfCampaignsFromJson(other_json);
        }
    }

    void LoadListOfCampaignsFromJson(Json::Value@ json) override
    {
        // already keep track of the index because more elements may get added before the index is used
        uint other_index = campaigns_json["campaignList"].Length;

        campaigns_json["campaignList"].Add(json);
        Json::ToFile(IO::FromStorageFolder("campaigns/" + tostring(CampaignType::Other) + ".json"), campaigns_json);

        string file_name = string(json["name"]) + " " + Json::Write(json["campaignId"]);
        Campaign campaign(json["name"], file_name, campaign_type, other_index, this, json["shortName"]);
        campaigns_list.InsertLast(campaign);
        Api::FetchMapsInfo(campaign);

        // setting the flag here makes the campaigns start appearing one by one in a nice looking way
        campaigns_loaded = true;
    }

    void ReloadMostRecentCampaign() override
    {
        return;
    }

    void UpdateMedalsCounts() override 
    {
        return;
    }
}