[Setting hidden]
bool show_browser_window = true;

class Browser
{
	vec4 base_color = vec4(0.15, 0.1, 0.65, 1.0);
	vec4 brighter_color = vec4(0.2, 0.2, 0.75, 1.0);
	vec4 brightest_color = vec4(0.25, 0.25, 0.9, 1.0);
	string base_circle = "\\$21a" + Icons::Circle + "\\$fff ";

	CampaignType current_tab;
	bool show_only_unbeaten_medals = false;

	uint window_w = 900;
	uint window_h = 600;

	UI::Texture@ s314ke_medal;
	UI::Font@ base_large_font;
	UI::Font@ base_normal_font;
	UI::Font@ base_small_font;

	Browser()
	{
		@s314ke_medal = UI::LoadTexture("s314ke_medal.png");

		@base_large_font = UI::LoadFont("DroidSans.ttf", 26, -1, -1 , true, true, true);
		@base_normal_font = UI::LoadFont("DroidSans.ttf", 20, -1, -1 , true, true, true);
		@base_small_font = UI::LoadFont("DroidSans.ttf", 16, -1, -1 , true, true, true);

		CampaignManager::Init();
		for (uint i = 0; i < CampaignType::Count; i++)
		{
			CampaignManager::UpdateMedalsCounts(CampaignType(i));
		}
	}

	void RenderMenu() 
	{
    	if (UI::MenuItem(base_circle + "s314ke Medals", "", show_browser_window)) {
        	show_browser_window = !show_browser_window;
    	}
	}

	void Draw()
	{
		if (!show_browser_window) return;

		//     _____________________________
		//    |              |              |
		//    |   O  Title   |   Campaign   |
		//    |              |     info     |
		//    |              |              |
		//    |   Campaign   |  Map1  sm pb |
		//    |   selection  |  Map2  sm pb |
		//    |              |  Map3  sm pb |
		//    |              |  ...         |
		//    |______________|______________|
		//
		//  sm - s314ke medal
		//  pb - personal best

		UI::PushStyleColor(UI::Col::Separator, base_color);
		UI::PushStyleColor(UI::Col::SeparatorHovered, brighter_color);
		UI::PushStyleColor(UI::Col::SeparatorActive, brightest_color);
		UI::PushStyleColor(UI::Col::Button, base_color);
		UI::PushStyleColor(UI::Col::ButtonHovered, brighter_color);
		UI::PushStyleColor(UI::Col::ButtonActive, brightest_color);

		UI::SetNextWindowSize(window_w, window_h);
		UI::Begin(base_circle + "s314ke Medals", show_browser_window, UI::WindowFlags::NoCollapse | UI::WindowFlags::NoScrollbar);
		UI::Columns(2);

		// ------------------------------------------------ LEFT SIDE ------------------------------------------------
		UI::BeginChild("LeftContainer");
		
		DrawTitle();

		DrawCampaignSelectionMenu();

		UI::EndChild(); // "LeftContainer"
		UI::NextColumn();
		
		// ------------------------------------------------ RIGHT SIDE ------------------------------------------------
		
		// leave the right side empty until a campaign is chosen
		if (CampaignManager::chosen is null)
		{
			UI::End(); // "s314ke Medals"
			UI::PopStyleColor(6); // Separator and Button
			return;
		}

		if (!CampaignManager::chosen.maps_loaded)
		{
			UI::Text("Loading...");
			UI::End(); // "s314ke Medals"
			UI::PopStyleColor(6); // Separator and Button
			return;
		}

		UI::BeginChild("RightContainer");
		
		DrawCampaignInfo();

		DrawMapsInfo();

		UI::EndChild(); // "RightContainer"
		UI::End(); // "s314ke Medals"
		UI::PopStyleColor(6); // Separator and Button
	}
	
	void DrawTitle()
	{
		UI::BeginChild("TitleWrapper", vec2(-1, 200));
		
		if (UI::BeginTable("TitleTable", 2)) 
		{
			UI::TableSetupColumn("##Medal", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupColumn("##TitleText", UI::TableColumnFlags::WidthStretch);
	
			UI::TableNextColumn();
			uint padding = 25;
			uint medal_x = 150;
			uint medal_y = 150;
			UI::BeginChild("MedalWrapper", vec2(medal_x + 2 * padding, medal_y + padding));
			UI::SetCursorPos(UI::GetCursorPos() + vec2(padding, padding));
			UI::Image(s314ke_medal, vec2(medal_x, medal_y));
			UI::EndChild(); // "MedalWrapper"
	
			UI::TableNextColumn();
			UI::BeginChild("TitleTextWrapper");
			UI::PushFont(base_large_font);
			CenterText(base_circle + " s314ke Medals", vec2(0, -20));
			UI::PopFont();
	
			if (current_tab == CampaignType::Other)
			{
				UI::PushFont(base_normal_font);
				CenterText("Refresh list", vec2(-10, 70));
				UI::PopFont(); // normal
				UI::SameLine();
				UI::PushFont(base_small_font);
				if (UI::Button(Icons::Refresh)) {
                	CampaignManager::ReloadOtherCampaignsList();
				}
				UI::PopFont(); // small
			}
			else
			{
				string medal_counter_text = base_circle + " " + CampaignManager::medals_achieved[current_tab] + 
											" / " + CampaignManager::medals_total[current_tab];
				UI::PushFont(base_normal_font);
				CenterText(medal_counter_text, vec2(-20, 70));
				UI::SameLine();
				UI::PushFont(base_small_font);
				if (UI::Button(Icons::Refresh)) {
					CampaignManager::ReloadAllCampaignMaps(current_tab);
				}
				UI::PopFont(); // small
				if (CampaignManager::medals_calculating[current_tab]) {
					CenterText("Loading...", vec2(0, 125));
				}
				UI::PopFont(); // normal
			}

			UI::EndChild(); // "TitleTextWrapper"
			UI::EndTable(); // "TitleTable"
		}
		UI::SetWindowSize(vec2(UI::GetWindowContentRegionMax().x, 200));
		UI::EndChild(); // "TitleWrapper"
	}

	void DrawCampaignSelectionMenu()
	{
		UI::PushStyleColor(UI::Col::Tab, base_color);
		UI::PushStyleColor(UI::Col::TabHovered, brightest_color);
		UI::PushStyleColor(UI::Col::TabActive, brighter_color);

		UI::BeginTabBar("CampaignsBar");

		if (UI::BeginTabItem("Campaigns"))
		{
			current_tab = CampaignType::Nadeo;
			DrawCampaignSelectionMenuTab(CampaignType::Nadeo);
			UI::EndTabItem(); // "Campaigns"
		}
		if (UI::BeginTabItem("Track of the Day"))
		{
			current_tab = CampaignType::Totd;
			DrawCampaignSelectionMenuTab(CampaignType::Totd);
			UI::EndTabItem(); // "Track of the Day"
		}
		if (UI::BeginTabItem("Other"))
		{
			current_tab = CampaignType::Other;
			DrawCampaignSelectionMenuTab(CampaignType::Other);
			UI::EndTabItem(); // "Other"
		}
		UI::EndTabBar(); // "CampaignsBar"
		UI::PopStyleColor(3);
	}

	void DrawCampaignSelectionMenuTab(const CampaignType&in campaign_type)
	{
		const vec2 button_size = vec2(80, 80);
		const float button_padding = 5; // also minimum value of 'b'
		const uint buttons_per_row = Math::Max(1, uint(UI::GetWindowSize().x / (button_size.x + 2 * button_padding)));

		UI::BeginChild("TableWrapper", vec2(), false, UI::WindowFlags::NoScrollbar);
		if (!CampaignManager::campaigns_loaded[campaign_type])
			UI::Text("Loading...");
		else
		{
			if (UI::BeginTable("CampaignsTable", buttons_per_row))
			{
				UI::PushStyleVar(UI::StyleVar::FrameRounding, 10);

				uint campaign_count = CampaignManager::GetCampaignsCount(campaign_type);

				// button spacing (value of 'a' is fixed)
				//  
				// |    __      __      __    |
				// |   |__|    |__|    |__|   |
				// |                          |
				//      a       a       a
				//  <-><--><--><--><--><--><->
				//   b      2b      2b      b
				// 
				for (uint i = 0; i < campaign_count; i++)
				{
					Campaign@ campaign = CampaignManager::GetCampaign(campaign_type, i);
					UI::TableNextColumn();
					UI::Dummy(vec2(0, 2 * button_padding));
						
					float whole_width = UI::GetWindowSize().x;

					// look at the figure above to understand what 'a' and 'b' are
					float a = button_size.x;
					float b = (whole_width - a * buttons_per_row) / (buttons_per_row * 2);
					UI::SetCursorPos(UI::GetCursorPos() + vec2(b, 0)); // center button

					UI::PushID("CampaignButton" + tostring(i));
					if (UI::Button("", button_size))
					{
						CampaignManager::ChooseCampaign(campaign_type, i);
					}
					UI::PopID();
					
					if (campaign_type == CampaignType::Other)
					{
						UI::PushFont(base_large_font);
						if (Draw::MeasureString(campaign.short_name).x > button_size.x - 14) {
							UI::PopFont();
							UI::PushFont(base_normal_font);
						}
						if (Draw::MeasureString(campaign.short_name).x > button_size.x - 14) {
							UI::PopFont();
							UI::PushFont(base_small_font);
						}
						vec2 text_size = Draw::MeasureString(campaign.short_name);
						float move_short_name_x = (button_size.x - text_size.x) * 0.5f;
						float additional_offset = 1.0; // for some reason the text is slightly off center without this
						UI::SetCursorPos(UI::GetCursorPos() + vec2(b + move_short_name_x + additional_offset, -35 - (text_size.y))); // center text
						UI::Text(campaign.short_name);
						UI::PopFont();
					}
					else
					{
						UI::PushFont(base_large_font);
						float move_twodigits_x = (button_size.x - Draw::MeasureString(campaign.GetTwoLastDigitsOfYear()).x) * 0.5f;
						float additional_offset = 1.0; // for some reason the text is slightly off center without this
						UI::SetCursorPos(UI::GetCursorPos() + vec2(b + move_twodigits_x + additional_offset, -70)); // center text
						UI::Text(campaign.GetTwoLastDigitsOfYear()); // year
						UI::PopFont();

						UI::PushFont(base_normal_font); 
						float move_month_x = (button_size.x - Draw::MeasureString(campaign.short_name).x) * 0.5f;
						UI::SetCursorPos(UI::GetCursorPos() + vec2(b + move_month_x + additional_offset, 0)); // center text
						UI::Text(campaign.short_name);
						UI::PopFont();
					}
				}
				UI::PopStyleVar();

				UI::EndTable(); // "CampaignsTable"
			}
		}
		UI::EndChild(); // "TableWrapper"
	}

	void DrawCampaignInfo()
	{
		if (!user_has_permissions)
			UI::Text("You don't have permissions to play maps locally.\n\nThe \"Play\" buttons will be disabled.");
		UI::BeginChild("CampaignInfo", vec2(-1, 150));
		if (UI::BeginTable("CampaignInfoTable", 2))
		{
			UI::TableSetupColumn("##name", UI::TableColumnFlags::WidthStretch);
			UI::TableSetupColumn("##progress", UI::TableColumnFlags::WidthStretch);
			
			UI::PushFont(base_large_font);

			UI::TableNextColumn();
			UI::BeginChild("CampaignName");
			// center the text
			vec2 container_size = UI::GetContentRegionAvail();
			vec2 campaignname_text_size = Draw::MeasureString(CampaignManager::GetChosenCampaignName());
			UI::SetCursorPos((container_size - campaignname_text_size) * 0.5f);
			UI::Text(CampaignManager::GetChosenCampaignName()); // full campaign name
			UI::EndChild(); // "CampaignName"
			
			UI::TableNextColumn();
			UI::BeginChild("CampaignMedalCounter");
			string medalcounter_text = base_circle + " " + tostring(CampaignManager::chosen.medals_achieved) 
							   + " / " + tostring(CampaignManager::chosen.medals_total);
			container_size = UI::GetContentRegionAvail();
			vec2 medalcounter_text_size = Draw::MeasureString(medalcounter_text);
			UI::SetCursorPos((container_size - medalcounter_text_size) * 0.5f + vec2(-10, 0)); // -10 to account for the refresh button
			UI::Text(medalcounter_text);
			UI::SameLine();
			UI::PushFont(base_small_font);
			if (!CampaignManager::AreRecordsLoading() && UI::Button(Icons::Refresh)) {
				CampaignManager::ReloadChosenCampaignMaps();
			}
			UI::PopFont(); // small
			UI::EndChild(); // "CampaignMedalCounter"

			UI::PopFont(); // large
			UI::EndTable(); // "CampaignInfoTable"
		}
		UI::EndChild(); // "CampaignInfo"
	}

	void DrawMapsInfo()
	{
		UI::BeginChild("Maps", vec2(), false, UI::WindowFlags::NoScrollbar);
		UI::PushStyleColor(UI::Col::CheckMark, brightest_color);
		UI::PushStyleColor(UI::Col::FrameBg, vec4(.35, .35, .35, .3));
		UI::PushStyleColor(UI::Col::FrameBgHovered, base_color);
		UI::PushStyleColor(UI::Col::FrameBgActive, brighter_color);
		// a single whitespace at the beginning of the checkbox label is intentional and used as padding
		show_only_unbeaten_medals = UI::Checkbox(" Only show maps with an unachieved medal", show_only_unbeaten_medals);
		UI::PushStyleColor(UI::Col::TableRowBg, vec4(.25, .25, .25, .2));
		UI::PushFont(base_small_font);

		uint n_columns = CampaignManager::chosen.type == CampaignType::Totd ? 7 
																			: 6;
		if (UI::BeginTable("MapsTable", n_columns, UI::TableFlags::RowBg | UI::TableFlags::ScrollY | UI::TableFlags::PadOuterX))
		{
			if (CampaignManager::chosen.type == CampaignType::Totd)
				UI::TableSetupColumn("##day", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch, 2);
			UI::TableSetupColumn("##padding", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupColumn("Medal", UI::TableColumnFlags::WidthStretch);
			UI::TableSetupColumn("##achieved", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupColumn("PB", UI::TableColumnFlags::WidthStretch);
			UI::TableSetupColumn("##button", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupScrollFreeze(n_columns, 1);

			UI::TableHeadersRow();

			for (uint i = 0; i < CampaignManager::GetMapsCount(); i++)
			{
				Map map = CampaignManager::GetMap(i);
				// skip if checkbox is ticked AND (medal is achieved OR doesn't exist)
				if (show_only_unbeaten_medals && (map.MedalAchieved() || !map.MedalExists()))
					continue;

				UI::TableNextRow(UI::TableRowFlags::None, 30);

				if (CampaignManager::chosen.type == CampaignType::Totd) 
				{
					UI::TableNextColumn(); // day
					UI::AlignTextToFramePadding();
					UI::Text(" " + tostring(i + 1) + " ");
				}

				UI::TableNextColumn(); // map name
				UI::AlignTextToFramePadding();
				UI::Text(Text::OpenplanetFormatCodes(map.name));

				UI::TableNextColumn(); // padding
				UI::TableNextColumn(); // s314ke medal time
				if (map.MedalExists())
					UI::Text(Time::Format(map.s314ke_medal_time));

				UI::TableNextColumn(); // circle
				if (map.MedalAchieved())
					UI::Text(base_circle);

				UI::TableNextColumn(); // PB
				if (map.PbExists())
					UI::Text(Time::Format(map.pb_time));

				UI::TableNextColumn(); // button
				UI::PushID("Play" + i);
				UI::BeginDisabled(!user_has_permissions);
				if (UI::Button("Play"))
				{
					startnew(CoroutineFunc(map.PlayCoroutine));
				}
				UI::EndDisabled();
				UI::PopID(); // "Play" + i
			}
			UI::EndTable(); // "MapsTable"
		}
		UI::PopFont();
		UI::PopStyleColor(5); // TableRowBg, Frame, Checkmark
		UI::EndChild(); // "Maps"
	}

	void CenterText(const string&in text, const vec2 additional_offset = vec2(0,0))
	{
		vec2 container_size = UI::GetContentRegionAvail();
		vec2 text_size = Draw::MeasureString(text);
		UI::SetCursorPos((container_size - text_size) * 0.5f + additional_offset);
		UI::Text(text);
	}
}
