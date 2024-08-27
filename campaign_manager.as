namespace CampaignManager
{
    bool initialized = false;

    array<CampaignCategory@> campaign_categories;
	Campaign@ chosen;

    void Init()
    {
        // CategoryNadeo nadeo();
        CampaignManager::campaign_categories.InsertLast(CategoryNadeo());
        CampaignManager::campaign_categories.InsertLast(CategoryTotd());
        CampaignManager::campaign_categories.InsertLast(CategoryOther());
        initialized = true;
    }

    void ReloadOtherCampaignsList()
    {
        campaign_categories[CampaignType::Other].FetchListOfCampaigns();
    }

    void ChooseCampaign(const CampaignType&in campaign_type, uint index)
    {
        @chosen = GetCampaign(campaign_type, index);

        if (!chosen.maps_loaded)
            startnew(CoroutineFunc(LoadChosenCampaignMaps));
    }

    void LoadChosenCampaignMaps()
    {
        Api::FetchMapsInfo(chosen);
    }

    void ReloadChosenCampaignMaps()
    {
        if (chosen.type == CampaignType::Other)
        {
            chosen.maps_loaded = false;
            startnew(CoroutineFunc(LoadChosenCampaignMaps));
            return;
        }

        if (!ChosenCategory().medals_calculating) // prevent setting the flag back to false after the maps already got loaded by a different coroutine
        {
            chosen.maps_loaded = false;
            ChosenCategory().medals_counts_uptodate = false;
        }
        UpdateMedalsCounts(chosen.type);
    }

    void ReloadAllCampaignMaps(const CampaignType&in campaign_type)
    {
        if (!ChosenCategory().medals_calculating) // prevent setting the flag back to false after the maps already got loaded by a different coroutine
        {
            for (uint i = 0; i < campaign_categories[campaign_type].campaigns_list.Length; i++)
                campaign_categories[campaign_type].campaigns_list[i].maps_loaded = false;

            ChosenCategory().medals_counts_uptodate = false;
        }
        UpdateMedalsCounts(campaign_type);
    }

    void UpdateMedalsCounts(const CampaignType&in campaign_type)
    {
        if (campaign_type == CampaignType::Other)
            return;

        if (!ChosenCategory().medals_counts_uptodate && 
            !ChosenCategory().medals_calculating)
            startnew(CoroutineFuncUserdata(UpdateMedalsCountsCoroutine), UpdateMedalsCountsCoroutineData(campaign_type));
    }

    class UpdateMedalsCountsCoroutineData
    {
        CampaignType campaign_type;
        UpdateMedalsCountsCoroutineData(const CampaignType&in campaign_type) {this.campaign_type = campaign_type;}
    }

    void UpdateMedalsCountsCoroutine(ref@ _campaign_type)
    {
        CampaignType campaign_type = cast<UpdateMedalsCountsCoroutineData>(_campaign_type).campaign_type;
        campaign_categories[campaign_type].medals_calculating = true;

        // wait for the category of campaigns to load
        while (!campaign_categories[campaign_type].campaigns_loaded)
            yield();

        campaign_categories[campaign_type].medals_achieved = 0;
        campaign_categories[campaign_type].medals_total = 0;
        for (uint i = 0; i < campaign_categories[campaign_type].campaigns_list.Length; i++)
        {
            Campaign@ campaign = campaign_categories[campaign_type].campaigns_list[i];
            // campaign loads the maps data from plugin storage in the constructor, so if it's not loaded then that data is not locally available
            if (!campaign.maps_loaded)
                Api::FetchMapsInfo(campaign);

            // wait for the map-record-fetching coroutines to all finish to prevent spamming the API too much
            while (!campaign.AreRecordsReady())
                yield();

            campaign.RecalculateMedalsCounts();
            campaign_categories[campaign_type].medals_achieved += campaign.medals_achieved;
            campaign_categories[campaign_type].medals_total += campaign.medals_total;
        }

        campaign_categories[campaign_type].medals_counts_uptodate = true;
        campaign_categories[campaign_type].medals_calculating = false;
    }

    uint GetCampaignsCount(const CampaignType&in campaign_type)
    {
        return campaign_categories[campaign_type].campaigns_list.Length;
    }

    Campaign@ GetCampaign(const CampaignType&in campaign_type, uint index)
    {
        return campaign_categories[campaign_type].campaigns_list[index];
    }

    string GetChosenCampaignName()
    {
        return chosen.name;
    }

    Map GetMap(uint index)
    {
        return chosen.maps[index];
    }

    uint GetMapsCount()
    {
        return chosen.maps.Length;
    }

    bool AreRecordsLoading()
    {
        return chosen.AreRecordsLoading();
    }

    CampaignCategory@ GetCategory(CampaignType campaign_type)
    {
        return campaign_categories[campaign_type];
    }

    CampaignCategory@ ChosenCategory() 
    {
        if (chosen is null)
            return campaign_categories[CampaignType::Nadeo];
        return campaign_categories[chosen.type];
    }
}