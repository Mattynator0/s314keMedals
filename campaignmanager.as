class CampaignManager
{
	array<Campaign@> nadeo;
	array<Campaign@> totd;
	Campaign@ chosen;

    //uint medals_achieved = 0;
    //uint medals_total = 0;
    //bool medals_counts_uptodate = true;

    CampaignManager()
    {
        MyJson::LoadPluginStorageData();
        MyJson::InitCampaigns(nadeo, totd);
        MyJson::SavePluginStorageData();
    }

    void ChooseCampaign(CampaignType campaign_type, uint index)
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
        chosen.maps_loaded = false;
        Api::LoadMaps(chosen);
    }

    bool IsEmpty(CampaignType campaign_type)
    {
        return (campaign_type == CampaignType::Nadeo) ? nadeo.IsEmpty() : totd.IsEmpty();
    }

    uint GetCampaignsCount(CampaignType campaign_type)
    {
        return (campaign_type == CampaignType::Nadeo) ? nadeo.Length : totd.Length;
    }

    Campaign@ GetCampaign(CampaignType campaign_type, uint index)
    {
        return (campaign_type == CampaignType::Nadeo) ? nadeo[index] : totd[index];
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

    /*
    uint GetAchievedMedalsCount()
    {
        if (medals_counts_uptodate)
            return medals_achieved;
        
        medals_achieved = 0;
        for (uint i = 0; i < nadeo.Length; i++)
        {
            medals_achieved += nadeo[i].medals_achieved;
        }
        for (uint i = 0; i < totd.Length; i++)
        {
            medals_achieved += totd[i].medals_achieved;
        }
        medals_counts_uptodate = true;
        return medals_achieved;
    }

    uint GetTotalMedalsCount()
    {
        if (medals_counts_uptodate)
            return medals_total;
        
        medals_total = 0;
        for (uint i = 0; i < nadeo.Length; i++)
        {
            medals_total += nadeo[i].medals_total;
        }
        for (uint i = 0; i < totd.Length; i++)
        {
            medals_total += totd[i].medals_total;
        }
        medals_counts_uptodate = true;
        return medals_total;
    }
    */
}