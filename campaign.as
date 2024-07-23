enum CampaignType
{
    Nadeo = 0,
    Totd = 1,
    Other = 2,
    Count = 3
}

class Campaign
{
    uint json_index;
    string name;
    string short_name;
    array<Map> maps;
    bool maps_loaded;
    CampaignType type;
    dictionary mapid_to_maps_array_index;

    uint medals_achieved = 0;
    uint medals_total = 0;

    Campaign(const string&in name, const CampaignType&in type, uint json_index, const string&in short_name = "")
    {
        this.name = name;
        this.short_name = (type != CampaignType::Other) ? CreateShortName() : short_name;
        maps_loaded = false;
        this.type = type;
        this.json_index = json_index;
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
        uint counter = 0;
        for (uint i = 0; i < maps.Length; i++)
        {
            if (maps[i].MedalAchieved())
                counter++;
        }
        medals_achieved = counter;

        counter = 0;
        for (uint i = 0; i < maps.Length; i++)
        {
            if (maps[i].MedalExists())
                counter++;
        }
        medals_total = counter;
    }
}