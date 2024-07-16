enum CampaignType
{
    Nadeo,
    Totd
}

class Campaign
{
    uint json_index;
    string name;
    array<Map> maps;
    bool maps_loaded;
    CampaignType type;
    dictionary mapid_to_array_index;

    uint medals_achieved = 0;
    uint medals_total = 0;

    Campaign(const string&in name, const CampaignType&in type, uint json_index)
    {
        this.name = name;
        maps_loaded = false;
        this.type = type;
        this.json_index = json_index;
    }

    string GetSeasonName()
    {
        return Regex::Replace(name, "\\s+[A-Za-z0-9]+", "");
    }

    string GetFirstThreeLetters()
    {
        return name.SubStr(0, 3);
    }

    string GetShortName()
    {
        return (type == CampaignType::Nadeo) ? GetSeasonName() : GetFirstThreeLetters();
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