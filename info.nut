/**
 *      09.02.01
 *      info.nut
 *      
 *      Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *      
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *      
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */

class FanAI extends AIInfo {
	function GetAuthor()      { return "fanioz"; }
	function GetName()        { return "FanAI"; }
	function GetShortName()   { return "FNAI"; }
	function GetDescription() { return "FanAI is an AI that want to be a Tycoon too ;-)"; }
	function GetVersion()     { return 90312 }
	function CanLoadFromVersion(version)	{return version <= 90201;}
	function GetDate()        { return "2009-02-1"; }
	function CreateInstance() { return "FanAI"; }
	function GetSettings() {}
}

/**
*Tell the core, I'm an AI too ...
* 
*/
RegisterAI(FanAI());
