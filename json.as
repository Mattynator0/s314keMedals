namespace MyJson
{
    // Json::Value data_json = Json::Object();
    array<Json::Value> campaign_jsons;

    // const string data_path = IO::FromStorageFolder("s314kemedal.json");
    const array<string> json_paths = {  IO::FromStorageFolder("nadeo.json"),
                                        IO::FromStorageFolder("totd.json"),
                                        IO::FromStorageFolder("other.json") };
    const string test_path = IO::FromStorageFolder("test.json");

    dictionary map_uid_to_handle;

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

    void InitCampaignList(array<array<Campaign@>>@ campaigns_master_array)
    {
        for (uint i = 0; i < CampaignType::Count; i++) 
        {
            campaigns_master_array.InsertLast(array<Campaign@>());
            campaign_jsons.InsertLast(Json::Object());
        }

        // TODO make use of caching
        if (reload_campaigns)
        {
            for (uint i = 0; i < CampaignType::Count; i++) 
            {
                Api::LoadCampaignList(campaigns_master_array[i], CampaignType(i));
            }
            return;
        }

        // if (IO::FileExists(nadeo_path))
        // {
        //     nadeo_json = Json::FromFile(nadeo_path);

        //     LoadCampaignsFromJson(nadeo, CampaignType::Nadeo);
        // }
        // else 
        //     Api::LoadCampaigns(nadeo, CampaignType::Nadeo);

        // if (IO::FileExists(totd_path))
        // {
        //     totd_json = Json::FromFile(totd_path);

        //     LoadCampaignsFromJson(totd, CampaignType::Totd);
        // }
        // else 
        //     Api::LoadCampaigns(totd, CampaignType::Totd);
    }

    void LoadCampaignListFromJson(Json::Value@ json, array<Campaign@>@ campaigns, const CampaignType&in campaign_type)
    {
        // save the json for caching purposes
        campaign_jsons[campaign_type] = json;
        Json::ToFile(json_paths[campaign_type], campaign_jsons[campaign_type]);
        
        if (campaign_type == CampaignType::Nadeo)
        {
            auto @nadeo_json = campaign_jsons[CampaignType::Nadeo];
            for (uint i = 0; i < nadeo_json["campaignList"].Length; i++)
            {
                Campaign campaign(nadeo_json["campaignList"][i]["name"], campaign_type, i);

                campaigns.InsertLast(campaign);
            }
        }
        else if (campaign_type == CampaignType::Totd)
        {
            auto @totd_json = campaign_jsons[CampaignType::Totd];
            array<string> month_names = {"January", "February", "March", "April", "May", "June", 
                                         "July", "August", "September", "October", "November", "December"};
            for (uint i = 0; i < totd_json["monthList"].Length; i++)
            {
                Campaign campaign(month_names[uint(totd_json["monthList"][i]["month"]) - 1] // -1 because in the json, January is 1
                                    + " " + tostring(uint(totd_json["monthList"][i]["year"])), campaign_type, i);

                campaigns.InsertLast(campaign);
            }
        }
        else if (campaign_type == CampaignType::Other)
        {
            auto @other_json = campaign_jsons[CampaignType::Other];
            for (uint i = 0; i < other_json["campaignList"].Length; i++)
            {
                Campaign campaign(other_json["campaignList"][i]["name"], campaign_type, i, other_json["campaignList"][i]["shortName"]);

                campaigns.InsertLast(campaign);
            }
        }
    }

    string GetMapUidsAsString(Campaign@ campaign)
    {
        string result = "";
        Json::Value json = campaign_jsons[campaign.type];
        switch (campaign.type)
        {
            case CampaignType::Nadeo:
                json = json["campaignList"][campaign.json_index]["playlist"];
                break;
            case CampaignType::Totd:
                json = json["monthList"][campaign.json_index]["days"];
                break;
            case CampaignType::Other:
                json = json["campaignList"][campaign.json_index]["campaign"]["playlist"];
                break;
        }

        uint n_maps = json.Length;
        for (uint i = 0; i < n_maps - 1; i++)
        {
            result += json[i]["mapUid"];
            result += ",";
        }
        result += json[n_maps - 1]["mapUid"];
        return result;
    }

    void LoadCampaignContents(Campaign@ campaign, Json::Value@ maps_info)
    {
        campaign.maps.Resize(0);
        for (uint i = 0; i < maps_info["mapList"].Length; i++)
        {
            Map map;
            map.name = maps_info["mapList"][i]["name"];
            map.uid = maps_info["mapList"][i]["uid"];
            map.id = maps_info["mapList"][i]["mapId"];
            campaign.mapid_to_maps_array_index.Set(map.id, i);
            map.download_url = maps_info["mapList"][i]["downloadUrl"];
            @map.campaign = campaign;

            map_uid_to_handle.Set(map.uid, @map);

            campaign.maps.InsertLast(map);
        }
    }

    void LoadMapRecords(Campaign@ campaign, Net::HttpRequest@ req)
    {
        Json::Value map_times = req.Json();
        if (map_times.GetType() == Json::Type::Object && map_times.HasKey("message")) {
            warn("LoadMapRecords: API request returned an error message: " + string(map_times["message"]));
            return;
        }

        for (uint i = 0; i < map_times.Length; i++)
        {
            uint j;
            campaign.mapid_to_maps_array_index.Get(map_times[i]["mapId"], j);
            if (map_times[i]["accountId"] == Api::s314ke_id)
                campaign.maps[j].s314ke_medal_time = map_times[i]["recordScore"]["time"];
            if (map_times[i]["accountId"] == Api::GetWSID())
                campaign.maps[j].pb_time = map_times[i]["recordScore"]["time"];
        }
        campaign.RecalculateMedalsCounts();
    }
}