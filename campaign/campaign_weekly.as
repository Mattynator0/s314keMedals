class CategoryWeekly : CampaignCategory
{
    CategoryWeekly()
    {
        super(CampaignType::Weekly);
        category_name = "Weekly Shorts";
    }

    string GetCampaignsReqUrlBase() override
    {
        // offset by 1 to skip maps with hidden records, length 1000 to get all weeks (enough for about 19 years)
        return "https://live-services.trackmania.nadeo.live/api/campaign/weekly-shorts?offset=1&length=1000";
    }

    void LoadListOfCampaignsFromJson(Json::Value@ json) override
    {
        campaigns_json = json;
        Json::ToFile(IO::FromStorageFolder("campaigns/" + tostring(CampaignType::Weekly) + ".json"), campaigns_json);

        for (uint i = 0; i < campaigns_json["campaignList"].Length; i++)
        {
            string name = campaigns_json["campaignList"][i]["name"];
            Campaign campaign(name, name, CampaignType::Weekly, i, this, "Week");
            campaigns_list.InsertLast(campaign);
        }

        campaigns_loaded = true;
    }
}