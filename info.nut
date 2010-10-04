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

class Trans71 extends AIInfo
{
    version = null;
    constructor() {
    	this.version = 90619;
        ::AIInfo.constructor();
    }

    function GetAuthor(){ return "fanioz"; }
    function GetName() { return "Trans"; }
    function GetShortName() { return "FTAI"; }
    function GetDescription(){ return "Trans is an effort to be a transporter ;-) "; }
    function GetVersion() { return this.version; }
    function CanLoadFromVersion(version) { return version <= this.version; }
    function GetDate(){ return "2009-02-1"; }
    function CreateInstance(){ return "Trans"; }
	function GetURL() {	return "https://bugs.launchpad.net/transai";	}
    function GetSettings(){
    	//AddSetting({name = "dbg_sign", description = "Enable building debug signs", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = AICONFIG_BOOLEAN});
    }
}
/*
*Tell the core, I'm an AI too ...
*/
RegisterAI(Trans71());
