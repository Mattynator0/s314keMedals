namespace s314keMedals 
{
    // returns 0 if there is no s314ke medal
    uint GetS314keMedalTime()
    {
        auto app = cast<CGameManiaPlanet>(GetApp());
        if (app.RootMap is null)
            return 0;

        const string uid = app.RootMap.EdChallengeId;
        const string map_req_url = "https://live-services.trackmania.nadeo.live/api/token/map/" + uid;
        auto map_req = NadeoServices::Get("NadeoLiveServices", map_req_url);
        map_req.Start();
        while (!map_req.Finished()) yield();

        const string s314ke_id = "5f9c2a43-593f-4e84-a64d-82319058dd3a";
        string records_req_url = "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" + 
                                    s314ke_id + "&mapId=";
        records_req_url += map_req.Json()["mapId"];
        auto records_req = NadeoServices::Get("NadeoServices", records_req_url);
        records_req.Start();
        while (!records_req.Finished()) yield();

        auto records_json = records_req.Json();
        if (records_json.Length < 1)
            return 0;
        else return records_json[0]["recordScore"]["time"];
    }
}