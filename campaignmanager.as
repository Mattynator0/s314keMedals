namespace CampaignManager
{
    bool initialized = false;

    array<array<Campaign@>> campaigns_master_array;
	Campaign@ chosen;
    array<bool> campaigns_loaded;

    array<uint> medals_achieved = {0,0,0};
    array<uint> medals_total = {0,0,0};
    array<bool> medals_counts_uptodate = {false, false, false};
    array<bool> medals_calculating = {false, false, false};

    void Init()
    {
        for (uint i = 0; i < CampaignType::Count; i++) 
        {
            campaigns_loaded.InsertLast(false);
        }

        MyJson::InitCampaigns();
        initialized = true;
    }

    void ChooseCampaign(const CampaignType&in campaign_type, uint index)
    {
        @chosen = GetCampaign(campaign_type, index);

        if (!chosen.maps_loaded)
            startnew(CoroutineFunc(LoadChosenCampaignMaps));
    }

    void LoadChosenCampaignMaps()
    {
        Api::LoadMaps(chosen);
    }

    void ReloadChosenCampaignMaps()
    {
        if (!medals_calculating[chosen.type]) // prevent setting the flag back to false after the maps already got loaded by a different coroutine
        {
            chosen.maps_loaded = false;
            medals_counts_uptodate[chosen.type] = false;
        }
        UpdateMedalsCounts(chosen.type);
    }

    void ReloadAllCampaignMaps(const CampaignType&in campaign_type)
    {
        if (!medals_calculating[campaign_type]) // prevent setting the flag back to false after the maps already got loaded by a different coroutine
        {
            for (uint i = 0; i < campaigns_master_array[campaign_type].Length; i++)
            {
                campaigns_master_array[campaign_type][i].maps_loaded = false;
            }
            medals_counts_uptodate[campaign_type] = false;
        }
        UpdateMedalsCounts(campaign_type);
    }

    void UpdateMedalsCounts(const CampaignType&in campaign_type)
    {
        if (campaign_type == CampaignType::Other)
            return;

        if (!medals_counts_uptodate[campaign_type] && !medals_calculating[campaign_type])
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
        medals_calculating[campaign_type] = true;

        // wait for the category of campaigns to load
        while (!campaigns_loaded[campaign_type])
            yield();

        medals_achieved[campaign_type] = 0;
        medals_total[campaign_type] = 0;
        for (uint i = 0; i < campaigns_master_array[campaign_type].Length; i++)
        {
            Campaign@ campaign = campaigns_master_array[campaign_type][i];
            // campaign loads the maps data from plugin storage in the constructor, so if it's not loaded then that data is not locally available
            if (!campaign.maps_loaded)
                Api::LoadMaps(campaign);

            // wait for the map-record-fetching coroutines to all finish to prevent spamming the API too much
            while (!campaign.maps_loaded || campaign.AreRecordsLoading())
                yield();
            campaign.RecalculateMedalsCounts();
            medals_achieved[campaign_type] += campaign.medals_achieved;
            medals_total[campaign_type] += campaign.medals_total;
        }

        medals_counts_uptodate[campaign_type] = true;
        medals_calculating[campaign_type] = false;
    }

    uint GetCampaignsCount(const CampaignType&in campaign_type)
    {
        return campaigns_master_array[campaign_type].Length;
    }

    Campaign@ GetCampaign(const CampaignType&in campaign_type, uint index)
    {
        return campaigns_master_array[campaign_type][index];
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
}