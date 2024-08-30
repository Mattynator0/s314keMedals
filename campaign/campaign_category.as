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
    
    void LoadListOfCampaignsFromJson(Json::Value@ json)
    {}
    
    void ReloadAllCampaignMaps()
    {
        if (!medals_calculating) // prevent setting the flags back to false after the maps already got loaded by a different coroutine
        {
            for (uint i = 0; i < campaigns_list.Length; i++)
                campaigns_list[i].maps_loaded = false;

            medals_counts_uptodate = false;
        }
        UpdateMedalsCounts(campaign_type);
    }

    void UpdateMedalsCounts()
    {
        if (!medals_counts_uptodate && 
            !medals_calculating)
            startnew(UpdateMedalsCountsCoroutine);
    }

    void UpdateMedalsCountsCoroutine()
    {
        medals_calculating = true;

        // wait for the category of campaigns to load
        while (!campaigns_loaded)
            yield();

        medals_achieved = 0;
        medals_total = 0;
        for (uint i = 0; i < campaigns_list.Length; i++)
        {
            Campaign@ campaign = campaigns_list[i];
            // campaign loads the maps data from plugin storage in the constructor, so if it's not loaded then that data is not locally available
            if (!campaign.maps_loaded)
                Api::FetchMapsInfo(campaign);

            // wait for the map-record-fetching coroutines to all finish to prevent spamming the API too much
            while (!campaign.AreRecordsReady())
                yield();

            campaign.RecalculateMedalsCounts();
            medals_achieved += campaign.medals_achieved;
            medals_total += campaign.medals_total;
        }

        medals_counts_uptodate = true;
        medals_calculating = false;
    }
}