/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2019 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

class Trans19 extends AIInfo
{
	function GetAuthor() { return "fanioz"; }
	function GetName() { return "Trans"; }
	function GetShortName() { return "FTAI"; }
	function GetDescription() { return "Trans is an effort to be a transporter ;-) "; }
	function GetVersion() { return 200101; }
	function GetAPIVersion() { return "1.3"; }
	/* only change the version if the structure is changed */
	function MinVersionToLoad() { return 1; }
	function GetDate() { return "2009-02-1"; }
	function CreateInstance() { return "Trans"; }
	function GetURL() { return "https://github.com/fanioz/AI-Trans/issues/new"; }

	function GetSettings() {
		foreach(v in ["Rail", "Road", "Water", "Air"]) {
			AddSetting( {
				name = v + " Vehicle",
				description = "Allow build " + v + " vehicle",
				easy_value = 1,
				medium_value = 1,
				hard_value = 1,
				custom_value = 1,
				flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
			});
		}

		AddSetting( {
			name = "allow_pax",
			description = "Allow pax cargo",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = AICONFIG_BOOLEAN
		});

		AddSetting( {
			name = "allow_freight",
			description = "Allow freight cargo",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = AICONFIG_BOOLEAN
		});

		AddSetting( {
			name = "last_transport",
			description = "percent of last month transported cargo. Trans AI won't compete above this value",
			min_value = 0,
			max_value = 100,
			easy_value = 60,
			medium_value = 80,
			hard_value = 100,
			custom_value = 100,
			step_size = 10,
			flags = 0
		});

		AddSetting( {
			name = "loop_time",
			description = "Trans AI processing speed",
			min_value = 1,
			max_value = 5,
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = 0
		});

		AddSetting( {
			name = "debug_signs",
			description = "Build Signs",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
		});

		AddSetting( {
			name = "debug_log",
			description = "Dump Log",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
		});
		
		AddSetting( {
			name = "debug_break",
			description = "Allow AI to pause for debugging",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
		});
		
		AddSetting( {
			name = "debug_signsPF",
			description = "Build Signs for pathfinding",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
		});

		AddLabels("loop_time", {_1 = "Normal", _2 = "Sligthly slow", _3 = "More slow", _4 = "Very slow", _5 = "Slowest ever"});
	}
}

/*
*Tell the core, I'm an AI too ...
*/
RegisterAI(Trans19());
