namespace MyJson
{
    Json::Value data_json = Json::Object();
    Json::Value nadeo_json = Json::Object();
    Json::Value totd_json = Json::Object();

    string data_path = IO::FromStorageFolder("s314kemedal.json");
    string nadeo_path = IO::FromStorageFolder("nadeo.json");
    string totd_path = IO::FromStorageFolder("totd.json");

    bool reload_campaigns = true;

    
    void SavePluginStorageData()
    {
        // for future use

        // Json::ToFile(data_path, data_json);
    }

    void LoadPluginStorageData()
    {
        // for future use
        
        // if (IO::FileExists(data_path))
        // {
        //     data_json = Json::FromFile(data_path);
        // }
    }

    void InitCampaigns(array<Campaign@>& nadeo, array<Campaign@>& totd)
    {
        // TODO only load non-cached campaigns
        if (reload_campaigns)
        {
            Api::LoadCampaigns(nadeo, CampaignType::Nadeo);
            Api::LoadCampaigns(totd, CampaignType::Totd);
            return;
        }

        if (IO::FileExists(nadeo_path))
        {
            nadeo_json = Json::FromFile(nadeo_path);

            LoadCampaignsFromJson(nadeo, CampaignType::Nadeo);
        }
        else 
            Api::LoadCampaigns(nadeo, CampaignType::Nadeo);

        if (IO::FileExists(totd_path))
        {
            totd_json = Json::FromFile(totd_path);

            LoadCampaignsFromJson(totd, CampaignType::Totd);
        }
        else 
            Api::LoadCampaigns(totd, CampaignType::Totd);
    }
    
    void ParseAndLoadCampaignsFromJson(Net::HttpRequest@ req, array<Campaign@>& campaigns, CampaignType campaign_type)
    {
        if (campaign_type == CampaignType::Nadeo)
        {
            nadeo_json = Json::Parse(req.String());
            Json::ToFile(nadeo_path, nadeo_json);
        }
        else
        {
            totd_json = Json::Parse(req.String());
            Json::ToFile(totd_path, totd_json);
        }

        LoadCampaignsFromJson(campaigns, campaign_type);
    }

    void LoadCampaignsFromJson(array<Campaign@>& campaigns, CampaignType campaign_type)
    {
        if (campaign_type == CampaignType::Nadeo)
        {
            for (uint i = 0; i < nadeo_json["campaignList"].Length; i++)
            {
                Campaign campaign(nadeo_json["campaignList"][i]["name"], campaign_type, i);

                campaigns.InsertLast(campaign);
            }
        }
        else
        {
             // in the json file, month "1" is January
            array<string> month_names = {"", "January", "February", "March", "April", "May", "June", 
                                         "July", "August", "September", "October", "November", "December"};
            for (uint i = 0; i < totd_json["monthList"].Length; i++)
            {
                Campaign campaign(month_names[uint(totd_json["monthList"][i]["month"])] 
                                    + " " + tostring(uint(totd_json["monthList"][i]["year"])), campaign_type, i);


                campaigns.InsertLast(campaign);
            }
        }
    }

    string GetMapUidsAsString(Campaign@ campaign)
    {
        string res = "";
        if (campaign.type == CampaignType::Nadeo)
        {
            for (uint i = 0; i < 24; i++)
            {
                res += nadeo_json["campaignList"][campaign.json_index]["playlist"][i]["mapUid"];
                res += ",";
            }
            res += nadeo_json["campaignList"][campaign.json_index]["playlist"][24]["mapUid"];
        }
        else
        {
            uint totds_in_month = totd_json["monthList"][campaign.json_index]["days"].Length;
            for (uint i = 0; i < totds_in_month - 1; i++)
            {
                res += totd_json["monthList"][campaign.json_index]["days"][i]["mapUid"];
                res += ",";
            }
            res += totd_json["monthList"][campaign.json_index]["days"][totds_in_month - 1]["mapUid"];
        }
        return res;
    }

    void LoadCampaignContents(Campaign@ campaign, Net::HttpRequest@ req)
    {
        Json::Value maps_info = req.Json();
        Json::ToFile(IO::FromStorageFolder("test.json"), maps_info);
        
        campaign.maps.Resize(0);
        for (uint i = 0; i < maps_info["mapList"].Length; i++)
        {
            Map map;
            map.name = maps_info["mapList"][i]["name"];
            map.uid = maps_info["mapList"][i]["uid"];
            map.id = maps_info["mapList"][i]["mapId"];
            campaign.mapid_to_array_index.Set(map.id, i);
            map.download_url = maps_info["mapList"][i]["downloadUrl"];

            campaign.maps.InsertLast(map);
        }
    }

    void LoadMapRecords(Campaign@ campaign, Net::HttpRequest@ req)
    {
        Json::Value map_times = req.Json();
        //Json::ToFile(IO::FromStorageFolder("test.json"), map_times);

        for (uint i = 0; i < map_times.Length; i++)
        {
            uint j;
            campaign.mapid_to_array_index.Get(map_times[i]["mapId"], j);

            if (map_times[i]["accountId"] == Api::s314ke_id)
                campaign.maps[j].s314ke_medal_time = map_times[i]["recordScore"]["time"];
            else
                campaign.maps[j].pb_time = map_times[i]["recordScore"]["time"];
        }
    }
}