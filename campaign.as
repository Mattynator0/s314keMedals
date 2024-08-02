enum CampaignType
{
    Nadeo = 0,
    Totd = 1,
    Other = 2,
    Count = 3
}

class Campaign
{
    string name;
    CampaignType type;
    string file_name;
    uint json_index;
    string short_name;

    array<Map> maps;
    bool maps_loaded = false;
    dictionary mapid_to_maps_array_index;

    uint coroutines_running = 0;

    uint medals_achieved = 0;
    uint medals_total = 0;

    Campaign(const string&in name, const string&in file_name, const CampaignType&in type, uint json_index, const string&in short_name = "")
    {
        this.name = name;
        this.file_name = file_name;
        this.type = type;
        this.json_index = json_index;
        this.short_name = (type != CampaignType::Other) ? CreateShortName() : short_name;

        MyJson::LoadMapsDataFromJson(@this);
        RecalculateMedalsCounts();
    }

    bool AreRecordsLoading()
    {
        return coroutines_running > 0;
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

        CampaignManager::medals_counts_uptodate[type] = false;
        CampaignManager::UpdateMedalsCounts(type);
    }
}