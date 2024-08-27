// FIXME make this abstract once the keyword is supported by the vscode extension
class CampaignCategory
{
    array<Campaign@> campaigns_list;
    CampaignType campaign_type;
    Json::Value campaigns_json;
    
    bool campaigns_loaded = false;
    uint medals_achieved = 0;
    uint medals_total = 0;
    bool medals_counts_uptodate = false;
    bool medals_calculating = false;

    CampaignCategory(CampaignType campaign_type)
    {
        this.campaign_type = campaign_type;
        campaigns_json = Json::Object();
        FetchListOfCampaigns();
    }

    string GetCampaignsReqUrlBase()
    {
        return "";
    }

    void FetchListOfCampaigns()
    {
        error("Calling base function FetchListOfCampaigns()");
    }

    void FetchListOfCampaignsCoro(const string&in req_url)
    {}

    void LoadListOfCampaignsFromJson(Json::Value@ json)
    {}
}
