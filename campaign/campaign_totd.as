class CategoryTotd : CampaignCategory
{
    CategoryTotd()
    {
        super(CampaignType::Totd);
        category_name = "Track of the Day";
    }

    string GetCampaignsReqUrlBase() override
    {
        return "https://live-services.trackmania.nadeo.live/api/token/campaign/month?offset=0&length=1000"; // 1000 to get all of them
    }

    void LoadListOfCampaignsFromJson(Json::Value@ json) override
    {
        campaigns_json = json;
        Json::ToFile(IO::FromStorageFolder("campaigns/" + tostring(CampaignType::Totd) + ".json"), campaigns_json);

        array<string> month_names = {"January", "February", "March", "April", "May", "June", 
                                        "July", "August", "September", "October", "November", "December"};
        for (uint i = 0; i < campaigns_json["monthList"].Length; i++)
        {
            string name = month_names[uint(campaigns_json["monthList"][i]["month"]) - 1] // -1 because in the json, January is 1
                                + " " + Json::Write(campaigns_json["monthList"][i]["year"]);
            Campaign campaign(name, name, campaign_type, i, this);
            campaigns_list.InsertLast(campaign);
        }

        campaigns_loaded = true;
    }
}