#if DEPENDENCY_ULTIMATEMEDALSEXTENDED

class UMEs314keMedal : UltimateMedalsExtended::IMedal {
    UltimateMedalsExtended::Config GetConfig() override {
        UltimateMedalsExtended::Config c;
        c.defaultName = "s314ke";
        c.icon = "\\$21a" + Icons::Circle;
        return c;
    }

    void UpdateMedal(const string &in uid) override {}

    bool HasMedalTime(const string &in uid) override {
        return MyJson::map_uid_to_handle.Exists(uid);
    }
    uint GetMedalTime() override {
        auto app = cast<CGameManiaPlanet>(GetApp());
        if (app.RootMap is null)
            return 0;

        const string uid = app.RootMap.EdChallengeId;
        Map@ map;

        MyJson::map_uid_to_handle.Get(uid, @map);
        return map.s314ke_medal_time;
    }
}

void RegisterUME() {
    UltimateMedalsExtended::AddMedal(UMEs314keMedal());
}

void OnDestroyedUME() {
    UltimateMedalsExtended::RemoveMedal("s314ke");
}

#endif