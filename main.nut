/**
 *	    09.02.01
 *      main.nut
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
 
//require("rail.path.nut");
require("lib/binary.heap.2.nut");
require("lib/aystar.5.nut");
require("lib/road.path.finder.4.nut");

require("company.nut");
require("building.nut");
require("generator.nut");
require("services.nut");
require("money.nut");
require("tile.nut");
require("sandbox.nut");

/**
* extending AIController class
*
*/

class FanAI extends AIController 
{
	_manager = null;         /// the manager of Company
	AutoSave = {};          /// Table Auto Save
	
	constructor()
	{
		_manager = CompanyManager(this);
		AutoSave = {};
	}
	
  /**
  * 
  * name: Start
  * @note Start my AI please ...
  */
	function Start();

	/**
  * 
  * name: Save
  * @note handle autosave of OpenTTD
  */	
	function Save();
	
	/**
  * 
  * name: Load
  * @note handle loading savegame by OpenTTD
  */	
	function Load(version, data);
}

function FanAI::Start() 
{
	Sleep(10);
	this._manager.Born();
	this._manager.Evaluate();
	this._manager.Test();
	this._manager.Service();
	/**
	* ============ Main Loop ================
	*/
	local wait_time = GetTick();
	while (this._manager.Live != 0){
		Sleep(this._manager.SleepTime());
		if (GetTick() - wait_time > 1000) {
		  wait_time = GetTick();
			AILog.Info("============" + DateStr(AIDate.GetCurrentDate()) + "============");
			this._manager.Evaluate();
			this._manager.Events();
      local s = AISubsidyList();
			if (s.Count() > 0 || AIBase.Chance(1, 4)) this._manager.Service();
			if ((AICompany.GetLoanAmount() > 0) && (Bank.Balance() > 10000)) Bank.PayLoan();
		}
	}
	/**
	* ====================================
	*/
	AILog.Info("I'm resign :-)");	
}

function FanAI::Save() 
{
	AutoSave.Start_Date <- this._manager.StartDate;
	AILog.Info("--- Save/Load unsupported yet ---");
	return AutoSave;
}

function FanAI::Load(version, data)
{
	this._manager.StartDate = (data["Start_Date"]) ? data["Start_Date"] : 0;
	ErrMessage("Loading... ");
}
