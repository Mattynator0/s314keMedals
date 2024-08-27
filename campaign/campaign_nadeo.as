class CategoryNadeo : CampaignCategory
{
    CategoryNadeo()
    {
        super(CampaignType::Nadeo);
        // FetchListOfCampaigns();
    }

    string GetCampaignsReqUrlBase() override
    {
        return "https://live-services.trackmania.nadeo.live/api/token/campaign/official?offset=0&length=1000"; // 1000 to get all of them
    }

    void FetchListOfCampaigns() override
    {
        campaigns_list.Resize(0);
        string req_url = GetCampaignsReqUrlBase();

        startnew(CoroutineFuncUserdataString(FetchListOfCampaignsCoro), req_url);
    }

    void FetchListOfCampaignsCoro(const string&in req_url) override
    {
        auto @req = NadeoServices::Get("NadeoLiveServices", req_url);
        Api::AddUserAgent(req);
        req.Start();
        while (!req.Finished()) yield();

        LoadListOfCampaignsFromJson(req.Json());
    }

    void LoadListOfCampaignsFromJson(Json::Value@ json) override
    {
        campaigns_json = json;
        Json::ToFile(IO::FromStorageFolder("campaigns/" + tostring(CampaignType::Nadeo) + ".json"), campaigns_json);

        for (uint i = 0; i < campaigns_json["campaignList"].Length; i++)
        {
            string name = campaigns_json["campaignList"][i]["name"];
            Campaign campaign(name, name, CampaignType::Nadeo, i, this);
            campaigns_list.InsertLast(campaign);
        }

        campaigns_loaded = true;
    }
}