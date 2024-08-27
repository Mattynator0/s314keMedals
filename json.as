namespace MyJson
{
    const string test_path = IO::FromStorageFolder("test.json");

    dictionary map_uid_to_handle;

    // ----------------------------------------------------------------------------------------
    // ------------------------------------- DATA CACHING -------------------------------------
    // ----------------------------------------------------------------------------------------

    void DeleteLegacyPluginStorageFiles()
    {
        if (IO::FileExists(IO::FromStorageFolder("nadeo.json")))
            IO::Delete(IO::FromStorageFolder("nadeo.json"));
        if (IO::FileExists(IO::FromStorageFolder("totd.json")))
            IO::Delete(IO::FromStorageFolder("totd.json"));
    }

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

            map_uid_to_handle.Set(map.uid, @map);
        }
        campaign.maps_loaded = true;
    }
    
    // -----------------------------------------------------------------------------------------------
    // ------------------------------------- MAPS INITIALIZATION -------------------------------------
    // -----------------------------------------------------------------------------------------------

    string GetMapUidsAsString(Campaign@ campaign)
    {
        string result = "";
        Json::Value@ campaigns_json = campaign.campaign_category.campaigns_json;
        Json::Value@ json;
        switch (campaign.type)
        {
            case CampaignType::Nadeo:
                @json = campaigns_json["campaignList"][campaign.json_index]["playlist"];
                break;
            case CampaignType::Totd:
                @json = campaigns_json["monthList"][campaign.json_index]["days"];
                break;
            case CampaignType::Other:
                @json = campaigns_json["campaignList"][campaign.json_index]["campaign"]["playlist"];
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
            if (maps_info["mapList"][i]["author"] == Api::s314ke_id)
                map.s314ke_medal_time = maps_info["mapList"][i]["authorTime"];
            campaign.maps.InsertLast(map);

            map_uid_to_handle.Set(map.uid, @map);
        }
    }
    
    void LoadRecordsForSingleMap(Map@ map, Json::Value@ map_times)
    {
        if (map_times.GetType() == Json::Type::Object && map_times.HasKey("message")) {
            error("LoadMapRecords: API request returned an error message: " + string(map_times["message"]));
            return;
        }

        for (uint i = 0; i < map_times.Length; i++)
        {
            if (map_times[i]["accountId"] == Api::s314ke_id && map.s314ke_medal_time > uint(map_times[i]["recordScore"]["time"]))
                map.s314ke_medal_time = map_times[i]["recordScore"]["time"];
            if (map_times[i]["accountId"] == Api::GetWSID())
                map.pb_time = map_times[i]["recordScore"]["time"];
        }
    }
}