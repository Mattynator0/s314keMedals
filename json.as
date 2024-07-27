namespace MyJson
{
    array<Json::Value> campaign_jsons;
    const string test_path = IO::FromStorageFolder("test.json");

    dictionary map_uid_to_handle;
    bool reload_campaigns = true;

    // ----------------------------------------------------------------------------------------
    // ------------------------------------- DATA CACHING -------------------------------------
    // ----------------------------------------------------------------------------------------

    void CreatePluginStorageFolders()
    {
        if (!IO::FolderExists(IO::FromStorageFolder("campaigns")))
            IO::CreateFolder(IO::FromStorageFolder("campaigns"));
        if (!IO::FolderExists(IO::FromStorageFolder("maps")))
            IO::CreateFolder(IO::FromStorageFolder("maps"));
        for (uint i = 0; i < CampaignType::Count; i++)
        {
            if (!IO::FolderExists(IO::FromStorageFolder("maps/" + tostring(CampaignType(i)))))
                IO::CreateFolder(IO::FromStorageFolder("maps/" + tostring(CampaignType(i))));
        }
    }

    void SaveMapsDataToJson(Campaign@ campaign)
    {
        Json::Value save_json = Json::Array();

        for (uint i = 0; i < campaign.maps.Length; i++)
        {
            save_json.Add(Json::Object());
            save_json[i]["uid"] = campaign.maps[i].uid;
            save_json[i]["id"] = campaign.maps[i].id;
            save_json[i]["name"] = campaign.maps[i].name;
            save_json[i]["s314keMedal"] = campaign.maps[i].s314ke_medal_time;
            save_json[i]["pb"] = campaign.maps[i].pb_time;
            save_json[i]["downloadUrl"] = campaign.maps[i].download_url;
        }

        string save_path = IO::FromStorageFolder("maps/" + tostring(campaign.type) + "/" + campaign.file_name + ".json");
        Json::ToFile(save_path, save_json);
    }

    void LoadMapsDataFromJson(Campaign@ campaign)
    {
        string save_path = IO::FromStorageFolder("maps/" + tostring(campaign.type) + "/" + campaign.file_name + ".json");
        if (!IO::FileExists(save_path)) 
            return;

        Json::Value loaded_json = Json::FromFile(save_path);
        campaign.maps.Resize(0);
        for (uint i = 0; i < loaded_json.Length; i++)
        {
            Map map;
            map.uid = loaded_json[i]["uid"];
            map.id = loaded_json[i]["id"];
            map.name = loaded_json[i]["name"];
            map.s314ke_medal_time = loaded_json[i]["s314keMedal"];
            map.pb_time = loaded_json[i]["pb"];
            map.download_url = loaded_json[i]["downloadUrl"];
            @map.campaign = campaign;
            campaign.maps.InsertLast(map);
        }
        campaign.maps_loaded = true;
    }
    
    // ----------------------------------------------------------------------------------------------------
    // ------------------------------------- CAMPAIGNS INITIALIZATION -------------------------------------
    // ----------------------------------------------------------------------------------------------------

    void InitCampaigns()
    {
        for (uint i = 0; i < CampaignType::Count; i++) 
        {
            CampaignManager::campaigns_master_array.InsertLast(array<Campaign@>());
            campaign_jsons.InsertLast(Json::Object());
        }
        campaign_jsons[CampaignType::Other]["campaignList"] = Json::Array();

        if (reload_campaigns)
        {
            for (uint i = 0; i < CampaignType::Count; i++) 
            {
                Api::LoadListOfCampaigns(CampaignManager::campaigns_master_array[i], CampaignType(i));
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
    }

    void LoadListOfCampaignsFromJson(Json::Value@ json, array<Campaign@>@ campaigns, const CampaignType&in campaign_type)
    {
        int other_index;
        if (campaign_type == CampaignType::Other)
        {
            // already keep track of the index because more jsons may get added before the index is used
            other_index = campaign_jsons[campaign_type]["campaignList"].Length;
            campaign_jsons[campaign_type]["campaignList"].Add(json);
        }
        else
            campaign_jsons[campaign_type] = json;

        Json::ToFile(IO::FromStorageFolder("campaigns/" + tostring(campaign_type) + ".json"), campaign_jsons[campaign_type]);

        if (campaign_type == CampaignType::Nadeo)
        {
            auto @campaign_json = campaign_jsons[CampaignType::Nadeo];
            for (uint i = 0; i < campaign_json["campaignList"].Length; i++)
            {
                string name = campaign_json["campaignList"][i]["name"];
                Campaign campaign(name, name, campaign_type, i);
                campaigns.InsertLast(campaign);
            }
        }
        else if (campaign_type == CampaignType::Totd)
        {
            auto @campaign_json = campaign_jsons[CampaignType::Totd];
            array<string> month_names = {"January", "February", "March", "April", "May", "June", 
                                         "July", "August", "September", "October", "November", "December"};
            for (uint i = 0; i < campaign_json["monthList"].Length; i++)
            {
                string name = month_names[uint(campaign_json["monthList"][i]["month"]) - 1] // -1 because in the json, January is 1
                                    + " " + Json::Write(campaign_json["monthList"][i]["year"]);
                Campaign campaign(name, name, campaign_type, i);
                campaigns.InsertLast(campaign);
            }
        }
        else if (campaign_type == CampaignType::Other)
        {
            string file_name = string(json["name"]) + " " + Json::Write(json["campaignId"]);
            Campaign campaign(json["name"], file_name, campaign_type, other_index, json["shortName"]);
            campaigns.InsertLast(campaign);
        }
        
        CampaignManager::campaigns_loaded[campaign_type] = true;
    }

    // -----------------------------------------------------------------------------------------------
    // ------------------------------------- MAPS INITIALIZATION -------------------------------------
    // -----------------------------------------------------------------------------------------------

    string GetMapUidsAsString(Campaign@ campaign)
    {
        string result = "";
        Json::Value @json;
        switch (campaign.type)
        {
            case CampaignType::Nadeo:
                @json = campaign_jsons[campaign.type]["campaignList"][campaign.json_index]["playlist"];
                break;
            case CampaignType::Totd:
                @json = campaign_jsons[campaign.type]["monthList"][campaign.json_index]["days"];
                break;
            case CampaignType::Other:
                @json = campaign_jsons[campaign.type]["campaignList"][campaign.json_index]["campaign"]["playlist"];
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
            error("LoadMapRecords: API request returned an error message: " + string(map_times["message"]));
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
    }
}