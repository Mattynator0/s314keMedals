class CategoryNadeo : CampaignCategory
{
    CategoryNadeo()
    {
        super(CampaignType::Nadeo);
        category_name = "Campaigns";
    }

    string GetCampaignsReqUrlBase() override
    {
        return "https://live-services.trackmania.nadeo.live/api/campaign/official?offset=0&length=1000"; // 1000 to get all of them
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