enum CampaignType
{
    Nadeo = 0,
    Totd = 1,
    Weekly = 2,
    Other = 3,
    Count = 4
}

class Campaign
{
    string name;
    CampaignType type;
    string file_name;
    uint json_index;
    string short_name;

    array<Map@> maps;
    bool maps_loaded = false;
    dictionary mapid_to_maps_array_index;
    CampaignCategory@ campaign_category;

    uint map_records_coroutines_running = 0;

    uint medals_achieved = 0;
    uint medals_total = 0;

    Campaign(const string&in name, const string&in file_name, const CampaignType&in type, uint json_index, 
                CampaignCategory@ campaign_category, const string&in short_name = "")
    {
        this.name = name;
        this.file_name = file_name;
        this.type = type;
        this.json_index = json_index;
        @this.campaign_category = campaign_category;
        this.short_name = short_name == "" ? CreateShortName() : short_name;

        MyJson::LoadMapsDataFromJson(@this);
        RecalculateMedalsCounts();
    }

    bool AreRecordsLoading()
    {
        return map_records_coroutines_running > 0;
    }

    bool AreRecordsReady()
    {
        return maps_loaded && !AreRecordsLoading();
    }

    private string CreateShortName()
    {
        if (type == CampaignType::Nadeo) 
            return Regex::Replace(name, "\\s+[A-Za-z0-9]+", "");

        if (type == CampaignType::Totd)
            return name.SubStr(0, 3);

        error("CreateShortName() should not be called for this type of campaign. Campaign type: " + tostring(type));
        return name;
    }

    string GetTwoLastDigitsOfYear()
    {
        return Regex::Replace(name, "^.+(?=..$)", "");
    }

    void RecalculateMedalsCounts()
    {
        uint counter_achieved = 0;
        uint counter_total = 0;
        for (uint i = 0; i < maps.Length; i++)
        {
            if (maps[i].MedalAchieved())
                counter_achieved++;
            
            if (maps[i].MedalExists())
                counter_total++;
        }
        medals_achieved = counter_achieved;
        medals_total = counter_total;

        campaign_category.medals_counts_uptodate = false;
        campaign_category.UpdateMedalsCounts();
    }

    void ReloadMaps()
    {
        if (type == CampaignType::Other)
        {
            maps_loaded = false;
            startnew(CoroutineFunc(FetchMapsCoro));
            return;
        }

        if (!campaign_category.medals_calculating) // prevent setting the flag back to false after the maps already got loaded by a different coroutine
        {
            maps_loaded = false;
            campaign_category.medals_counts_uptodate = false;
        }
        campaign_category.UpdateMedalsCounts();
    }

    private void FetchMapsCoro()
    {
        Api::FetchMapsInfo(this);
    }
}