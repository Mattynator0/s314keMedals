#if DEPENDENCY_ULTIMATEMEDALSEXTENDED

class UMEs314keMedal : UltimateMedalsExtended::IMedal {
    UltimateMedalsExtended::Config GetConfig() override {
        UltimateMedalsExtended::Config c;
        c.defaultName = "s314ke";
        c.icon = "\\$21a" + Icons::Circle;
        return c;
    }

    bool has_medal;
    string uid;

    void UpdateMedal(const string &in uid) override {
        this.uid = uid;
        print(uid);
        has_medal = MyJson::map_uid_to_handle.Exists(uid);
        print(has_medal);
    }

    bool HasMedalTime(const string &in uid) override {
        if (uid != this.uid) {return false;}
        return has_medal;
    }

    uint GetMedalTime() override {
        Map@ map;

        MyJson::map_uid_to_handle.Get(this.uid, @map);
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