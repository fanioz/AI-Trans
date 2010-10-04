/*  09.02.01 info.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA 02110-1301, USA.
 */

class Trans extends AIInfo
{
    version = null;
    constructor() {
    	this.version = 90819;
        ::AIInfo.constructor();
    }

    function GetAuthor(){ return "fanioz"; }
    function GetName() { return "Trans"; }
    function GetShortName() { return "FTAI"; }
    function GetDescription(){ return "Trans is an effort to be a transporter ;-) "; }
    function GetVersion() { return this.version; }
    /* only change the version if the structure is changed */
    function MinVersionToLoad() { return 90619; }
    function GetDate(){ return "2009-02-1"; }
    function CreateInstance(){ return "Trans"; }
	function GetURL() {	return "http://noai.openttd.org/projects/show/ai-trans"; }
    function GetSettings(){
		AddSetting({
			name = "allow_bus", 
			description = "Allow build bus",
			easy_value = 1, 
			medium_value = 1, 
			hard_value = 1, 
			custom_value = 1, 
			flags = AICONFIG_BOOLEAN
		});
		AddSetting({
			name = "allow_truck", 
			description = "Allow build truck", 
			easy_value = 1, 
			medium_value = 1, 
			hard_value = 1, 
			custom_value = 1, 
			flags = AICONFIG_BOOLEAN
		});
		AddSetting({
			name = "allow_train", 
			description = "Allow build train", 
			easy_value = 1, 
			medium_value = 1, 
			hard_value = 1, 
			custom_value = 1, 
			flags = AICONFIG_BOOLEAN
		});
		AddSetting({
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
		AddSetting({
			name = "loop_time", 
			description = "Trans AI processing speed", 
			min_value = 1, 
			max_value = 5, 
			easy_value = 3, 
			medium_value = 2, 
			hard_value = 1, 
			custom_value = 1, 
			flags = 0
		});
		AddSetting({
			name = "debug_signs", 
			description = " debug signs", 
			min_value = 0, 
			max_value = 1, 
			easy_value = 0, 
			medium_value = 0, 
			hard_value = 0, 
			custom_value = 0, 
			flags = 0
		});
		AddLabels("loop_time", {_1 = "Fastest", _2 = "Medium", _3 = "Sligthly slow", _4 = "Very slow", _5 = "Slowest"});
		AddLabels("debug_signs", {_0 = "Don't build", _1 = "Build"});
    }
}
/*
*Tell the core, I'm an AI too ...
*/
RegisterAI(Trans());
