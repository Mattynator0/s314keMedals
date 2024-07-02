class Browser
{
	vec4 base_color = vec4(0.2, 0.1, 0.7, 1.0);
	vec4 brighter_color = vec4(0.25, 0.2, 0.8, 1.0);
	vec4 brightest_color = vec4(0.3, 0.25, 1, 1.0);
	string base_circle = "\\$31b" + Icons::Circle + "\\$fff ";

	uint window_w = 900;
	uint window_h = 600;

	UI::Texture@ s314ke_medal;
	UI::Font@ base_large_font;
	UI::Font@ base_normal_font;
	UI::Font@ base_small_font;

	CampaignManager@ campaign_manager;

	Browser()
	{
		@s314ke_medal = UI::LoadTexture("s314ke_medal.png");

		@base_large_font = UI::LoadFont("DroidSans.ttf", 26, -1, -1 , true, true, true);
		@base_normal_font = UI::LoadFont("DroidSans.ttf", 20, -1, -1 , true, true, true);
		@base_small_font = UI::LoadFont("DroidSans.ttf", 16, -1, -1 , true, true, true);

		@campaign_manager = CampaignManager();
	}

	void Draw()
	{
		//     _____________________________
		//    |              |              |
		//    |   O  Title   |   Campaign   |
		//    |              |     info     |
		//    |              |              |
		//    |   Campaign   |  Map 1 sm pb |
		//    |   selection  |  Map 2 sm pb |
		//    |              |  Map 3 sm pb |
		//    |              |  ...         |
		//    |______________|______________|
		//
		//  sm - s314ke medal
		//  pb - personal best

		UI::PushStyleColor(UI::Col::Separator, base_color);
		UI::PushStyleColor(UI::Col::SeparatorHovered, brighter_color);
		UI::PushStyleColor(UI::Col::SeparatorActive, brightest_color);

		UI::SetNextWindowSize(window_w, window_h);
		UI::Begin(base_circle + "s314ke Medals", UI::WindowFlags::NoCollapse | UI::WindowFlags::NoScrollbar);
		UI::Columns(2);

		// ------------------------------------------------ LEFT SIDE ------------------------------------------------
		UI::BeginChild("LeftContainer");
		
		DrawTitle();

		DrawCampaignSelectionMenu();

		UI::EndChild(); // "LeftContainer"
		UI::NextColumn();
		
		// ------------------------------------------------ RIGHT SIDE ------------------------------------------------
		
		// leave the right side empty until a campaign is chosen
		if (campaign_manager.chosen is null)
		{
			UI::End();
			UI::PopStyleColor(3);
			return;
		}

		if (!campaign_manager.chosen.maps_loaded)
		{
			UI::Text("Loading...");
			UI::End();
			UI::PopStyleColor(3);
			return;
		}

		UI::BeginChild("RightContainer");
		
		DrawCampaignInfo();

		DrawMapsInfo();

		UI::EndChild(); // "RightContainer"
		UI::End();
		UI::PopStyleColor(3);
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
			uint medal_w = 150;
			uint medal_h = 150;
			UI::BeginChild("MedalWrapper", vec2(medal_w + 2 * padding, medal_h + padding));
			UI::SetCursorPos(UI::GetCursorPos() + vec2(padding, padding));
			UI::Image(s314ke_medal, vec2(medal_w, medal_h));
			UI::EndChild(); // "MedalWrapper"
	
			UI::TableNextColumn();
			UI::BeginChild("TitleTextWrapper");
			string title_text = base_circle + " s314ke Medals";
			float move_titletext_x = (UI::GetWindowSize().x - Draw::MeasureString(title_text).x) / 2 - 35;
			UI::SetCursorPos(UI::GetCursorPos() + vec2(move_titletext_x, 85)); // center the text
			UI::PushFont(base_large_font);
			UI::Text(title_text);
			UI::PopFont();
	
			//float move_titleprogress_x = UI::GetWindowSize().x / 2 - 30;
			//UI::SetCursorPos(UI::GetCursorPos() + vec2(move_titleprogress_x, 40)); // center the text
			//UI::PushFont(base_normal_font);
			//UI::Text(base_circle + " " + campaign_manager.GetAchievedMedalsCount() + " / " + campaign_manager.GetTotalMedalsCount());
			//UI::PopFont();
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
		UI::PushStyleColor(UI::Col::Border, vec4(1,1,1,1));

		UI::BeginTabBar("CampaignsBar");

		if (UI::BeginTabItem("Campaigns"))
		{
			DrawCampaignSelectionMenuTab(CampaignType::Nadeo);
			
			UI::EndTabItem(); // "Campaigns"
		}

		if (UI::BeginTabItem("Track of the Day"))
		{
			DrawCampaignSelectionMenuTab(CampaignType::Totd);

			UI::EndTabItem(); // "Track of the Day"
		}

		UI::EndTabBar(); // "CampaignsBar"
		UI::PopStyleColor(4);
	}

	void DrawCampaignSelectionMenuTab(CampaignType campaign_type)
	{
		const uint buttons_per_row = 4; // TODO

		UI::BeginChild("TableWrapper", vec2(), false, UI::WindowFlags::NoScrollbar);
		if (campaign_manager.IsEmpty(campaign_type))
			// LoadCampaign(campaign_type);
			UI::Text("Loading...");
		else
		{
			if (UI::BeginTable("CampaignsTable", 4))
			{
				UI::TableSetupColumn("##fall", UI::TableColumnFlags::WidthStretch);
				UI::TableSetupColumn("##summer", UI::TableColumnFlags::WidthStretch);
				UI::TableSetupColumn("##spring", UI::TableColumnFlags::WidthStretch);
				UI::TableSetupColumn("##winter", UI::TableColumnFlags::WidthStretch);

				UI::PushStyleColor(UI::Col::Button, base_color);
				UI::PushStyleColor(UI::Col::ButtonHovered, brighter_color);
				UI::PushStyleColor(UI::Col::ButtonActive, brightest_color);

				uint campaign_count = campaign_manager.GetCampaignsCount(campaign_type);
				// offsetting the first row so that the layout is:
				//
				//     FALL   SUMMER   SPRING   WINTER
				//
				//     FALL   SUMMER   SPRING   WINTER
				// 
				uint first_row_offset = (campaign_count + 2) % 4;
				for (uint i = first_row_offset; i < 4; i++)
					UI::TableNextColumn();

				// button spacing (x = button_w is fixed)
				//  
				// |    __      __      __    |
				// |   |__|    |__|    |__|   |
				// |                          |
				//      x       x       x
				//  <-><--><--><--><--><--><->
				//   y      2y      2y      y
				// 
				for (uint i = 0; i < campaign_count; i++)
				{
					Campaign@ campaign = campaign_manager.GetCampaign(campaign_type, i);
					UI::TableNextColumn();
					UI::Dummy(vec2(0, 10));
						
					uint button_w = 80;
					uint button_h = 80;
					float wrapper_w = UI::GetWindowSize().x;

					float y = (wrapper_w - button_w * buttons_per_row) / (buttons_per_row * 2);
					UI::SetCursorPos(UI::GetCursorPos() + vec2(y, 0)); // center button

					UI::PushID("CampaignButton" + tostring(i));
					if (UI::Button("", vec2(button_w, button_h)))
					{
						campaign_manager.ChooseCampaign(campaign_type, i);
					}
					UI::PopID();
						
					UI::PushFont(base_large_font);
					float move_twodigits_x = (button_w - Draw::MeasureString(campaign.GetTwoLastDigitsOfYear()).x) / 2;
					float additional_offset = 1.0; // for some reason the text is slightly off center without this
					UI::SetCursorPos(UI::GetCursorPos() + vec2(y + move_twodigits_x + additional_offset, -70)); // center text
					UI::Text(campaign.GetTwoLastDigitsOfYear()); // year
					UI::PopFont();

					UI::PushFont(base_normal_font); 
					float move_month_x = (button_w - Draw::MeasureString(campaign.GetShortName()).x) / 2;
					UI::SetCursorPos(UI::GetCursorPos() + vec2(y + move_month_x + additional_offset, 0)); // center text
					UI::Text(campaign.GetShortName()); // month
					UI::PopFont();
				}
				UI::PopStyleColor(3);

				UI::EndTable(); // "CampaignsTable"
			}
		}
		UI::EndChild(); // "TableWrapper"
	}

	void DrawCampaignInfo()
	{
		if (!user_has_permissions)
			UI::Text("You don't have permissions to play maps locally.\n\nThe \"Play\" buttons will be hidden.");
		UI::BeginChild("CampaignInfo", vec2(-1, 150));
		if (UI::BeginTable("CampaignInfoTable", 2))
		{
			UI::TableSetupColumn("##name", UI::TableColumnFlags::WidthStretch);
			UI::TableSetupColumn("##progress", UI::TableColumnFlags::WidthStretch);

			UI::TableNextColumn();
			UI::PushStyleColor(UI::Col::Button, base_color);
			UI::PushStyleColor(UI::Col::ButtonHovered, brighter_color);
			UI::PushStyleColor(UI::Col::ButtonActive, brightest_color);
			UI::PushFont(base_large_font);
			UI::BeginChild("CampaignName");
			vec2 container_size = UI::GetWindowSize();
			UI::SetCursorPos(UI::GetCursorPos() + vec2(container_size.x / 2 - 65, 60)); // center the text
			UI::Text(campaign_manager.GetChosenCampaignName()); // full campaign name
			UI::EndChild(); // "CampaignName"
			UI::TableNextColumn();
			UI::BeginChild("CampaignMedalCounter");
			UI::SetCursorPos(UI::GetCursorPos() + vec2(container_size.x / 2 - 35, 60)); // center the text
			UI::Text(base_circle + " " + tostring(campaign_manager.chosen.medals_achieved) 
							   + " / " + tostring(campaign_manager.chosen.medals_total));
			UI::SetCursorPos(UI::GetCursorPos() + vec2(100, 0));
			UI::PushFont(base_small_font);
			if (UI::Button(Icons::Refresh)) {
				startnew(CoroutineFunc(campaign_manager.ReloadChosenCampaignMaps));
			}
			UI::PopFont();
			UI::EndChild(); // "CampaignMedalCounter"
			UI::PopFont();
			UI::PopStyleColor(3);
			UI::EndTable(); // "CampaignInfoTable"
		}
		UI::EndChild(); // "CampaignInfo"
	}

	void DrawMapsInfo()
	{
		UI::BeginChild("Maps", vec2(), false, UI::WindowFlags::NoScrollbar);
		UI::PushFont(base_small_font);
		UI::PushStyleColor(UI::Col::TableRowBg, vec4(.25, .25, .25, .2));
		if (UI::BeginTable("MapsTable", 6, UI::TableFlags::RowBg | UI::TableFlags::SizingFixedFit))
		{
			UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch, 2);
			UI::TableSetupColumn("##padding", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupColumn("Medal", UI::TableColumnFlags::WidthStretch);
			UI::TableSetupColumn("##achieved", UI::TableColumnFlags::WidthFixed);
			UI::TableSetupColumn("PB", UI::TableColumnFlags::WidthStretch);
			UI::TableSetupColumn("##button", UI::TableColumnFlags::WidthFixed);

			UI::TableHeadersRow();
			UI::PushStyleColor(UI::Col::Button, base_color);
			UI::PushStyleColor(UI::Col::ButtonHovered, brighter_color);
			UI::PushStyleColor(UI::Col::ButtonActive, brightest_color);

			// TODO maybe use UI::ListClipper instead?
			for (uint i = 0; i < campaign_manager.GetMapsCount(); i++)
			{
				Map map = campaign_manager.GetMap(i);
				UI::TableNextRow(UI::TableRowFlags::None, 30);

				UI::TableNextColumn(); // map name
				UI::AlignTextToFramePadding();
				UI::SetCursorPos(UI::GetCursorPos() + vec2(5.0, 0.0)); // a little padding
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
				if (user_has_permissions && UI::Button("Play"))
				{
					startnew(CoroutineFunc(map.PlayCoroutine));
				}
				UI::PopID(); // "Play" + i
			}
			UI::PopStyleColor(3);

			UI::EndTable(); // "MapsTable"
		}
		UI::PopStyleColor(1); // TableRowBg
		UI::PopFont();
		UI::EndChild(); // "Maps"
	}
}
