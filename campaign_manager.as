namespace CampaignManager
{
    bool initialized = false;

    array<CampaignCategory@> campaign_categories;
	Campaign@ selected_campaign;
	CampaignCategory@ selected_category;

    void Init()
    {
        CampaignManager::campaign_categories.InsertLast(CategoryNadeo());
        CampaignManager::campaign_categories.InsertLast(CategoryTotd());
        CampaignManager::campaign_categories.InsertLast(CategoryOther());
        SelectCategory(CampaignType::Nadeo);
        initialized = true;

        for (uint i = 0; i < campaign_categories.Length; i++)
		{
			campaign_categories[i].UpdateMedalsCounts();
		}
    }

    void ReloadOtherCampaignsList()
    {
        // TODO check if this still works the way it should
        campaign_categories[CampaignType::Other].FetchListOfCampaigns();
    }

    void SelectCategory(const CampaignType&in campaign_type)
    {
        @selected_category = campaign_categories[campaign_type];
    }

    void SelectCampaign(uint index)
    {
        @selected_campaign = selected_category.campaigns_list[index];

        if (!selected_campaign.maps_loaded)
            startnew(CoroutineFunc(FetchSelectedCampaignMaps));
    }

    void ReloadCampaignMaps(uint index)
    {
        Campaign@ campaign = selected_category.campaigns_list[index];
        if (campaign.type == CampaignType::Other)
        {
            campaign.maps_loaded = false;
            startnew(CoroutineFunc(FetchSelectedCampaignMaps));
            return;
        }

        if (!selected_category.medals_calculating) // prevent setting the flag back to false after the maps already got loaded by a different coroutine
        {
            campaign.maps_loaded = false;
            selected_category.medals_counts_uptodate = false;
        }
        selected_category.UpdateMedalsCounts();
    }

    void FetchSelectedCampaignMaps()
    {
        Api::FetchMapsInfo(selected_campaign);
    }

    void ReloadSelectedCampaignMaps()
    {
        selected_campaign.ReloadMaps();
    }

    void ReloadCurrentCategory()
    {
        selected_category.ReloadAllCampaignMaps();
    }

    uint GetCampaignsCount()
    {
        return selected_category.campaigns_list.Length;
    }

    CampaignCategory@ GetSelectedCategory()
    {
        return selected_category;
    }

    Campaign@ GetCampaign(uint index)
    {
        return selected_category.campaigns_list[index];
    }

    string GetCampaignName()
    {
        return selected_campaign.name;
    }

    Map GetMap(uint index)
    {
        return selected_campaign.maps[index];
    }

    uint GetMapsCount()
    {
        return selected_campaign.maps.Length;
    }

    bool AreCampaignRecordsLoading()
    {
        return selected_campaign.AreRecordsLoading();
    }
}