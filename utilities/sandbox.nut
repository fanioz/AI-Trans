/*  09.02.04 - sandbox.nut
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

 /**
 * General un categorized static functions to assist program
 */
class Assist
{
	
	static function BuildAllTrack(head) {
		assert(AIMap.IsValidTile(head));
		foreach (track in Const.RailTrack) AIRail.BuildRailTrack(head, track);
	}
	
	/**
	 * Find modus
	 * @param anarray Array of numbers to find
	 */
	 static function Modus(anarray)
	 {
	 	local t = AIList();
	 	foreach (num in anarray) t.AddItem(num, t.GetValue(num) + 1);
	 	t.Sort(AIAbstractList.SORT_BY_VALUE, false);
	 	return t.Begin();
	 }
	 
	 /**
	 * Valuator function that return array of value
	 * @param list AIList to valuate
	 * @param valuator Function to be used as valuator
	 * @param ... Additional argument to be passed to
	 */
	 static function ValuateToArray(list, valuator, ...)
	{
		assert(typeof list == "instance");
		assert(typeof valuator == "function");
		local anarray = [];
		local args = [this, null];
		for(local c = 0; c < vargc; c++) args.append(vargv[c]);
		foreach(idx, val in list) {
			args[1] = idx;
			anarray.push(Assist.ACall(valuator, args));
		}
		return anarray;
	}
	 
	/**
	 * Convert an AIList to a human-readable string.
	 * @param list The AIList to convert.
	 * @return A string containing all item => value pairs from the list.
	 * @author Yexo (Admiral)
	 */
	static function AIListToString(list)
	{
		if (typeof(list) != "instance") throw("AIListToString(): argument has to be an instance of AIAbstractList.");
		local ret = "[";
		if (!list.IsEmpty()) {
			local a = list.Begin();
			ret += a + "=>" + list.GetValue(a);
			if (list.HasNext()) {
				for (local i = list.Next(); list.HasNext(); i = list.Next()) {
					ret += ", " + i + "=>" + list.GetValue(i);
				}
			}
		}
		ret += "]";
		return ret;
	}
	
	/**
	 * acall replacement to support do command
	 * @param func Function to execute
	 * @args Array of arguments, min. [this]
	 * @return Value of function called
	 * @note args[0] should be 'this' or environment.
	 */
	static function ACall(func, args)
	{
		assert(typeof(func) == "function");
		assert(typeof(args) == "array");
		this = args[0];
		switch (args.len()) {
		   	case 1: return func();
			case 2: return func(args[1]);
			case 3: return func(args[1], args[2]);
			case 4: return func(args[1], args[2], args[3]);
			case 5: return func(args[1], args[2], args[3], args[4]);
			case 6: return func(args[1], args[2], args[3], args[4], args[5]);
			case 7: return func(args[1], args[2], args[3], args[4], args[5], args[6]);
			case 8: return func(args[1], args[2], args[3], args[4], args[5], args[6], args[7]);
			default: throw "Too many arguments to ACall Function";
		}
	}

	/**
	 * Rename the drop off station
	 *@param st_id Station ID
	 *@param name Cargo label
	 */
	static function RenameStation(st_id, name)
	{
		local counter = 1;		
		while (!AIStation.SetName(st_id, name + " Drop Off:" + TransAI.Info.ID + ":" + counter) && counter < 100) counter++;
	}

	/**
	 * Count cargo that accept by an Industry
	 * @param id Industry ID
	 * @return number of cargo
	 */
	static function CargoCount(id)
	{
		local ret = 0;
		local type = AIIndustry.GetIndustryType(id);
		local cargoes = AIIndustryType.GetAcceptedCargo(type);
		if (cargoes) {
			ret += cargoes.Count();
		}
		return ret;
	}

	/**
	 * Temporary service cost
	 */
	static function ServiceCost(dist)
	{
		return (dist / 50).tointeger();
	}

	/**
	 * Valuator function
	 * @param list AIList to valuate
	 * @param valuator Function to be used as valuator
	 * @param ... Additional argument to be passed to
	 * @return the list too
	 */
	 static function Valuate(list, valuator, ...)
	{
		assert(typeof list == "instance");
		assert(typeof valuator == "function");

		local args = [this, null];
		for(local c = 0; c < vargc; c++) args.append(vargv[c]);
		foreach(idx, val in list) {
			args[1] = idx;
			local value = Assist.ACall(valuator, args);
			list.SetValue(idx, (value ? 1 : 0));
		}
		return list;
	}

	/**
	 * Check if parameter is null
	 * @param val val to evaluate
	 * @return true if val is null
	 */
	static function IsNull(val) { return val == null ; }

	/**
     * Lead a number with zero
     * this will solve problem of '09' that displayed '9' only
     * @param integer_number to convert
     * @return number in string
     * @note only for number below 10
     */
    static function LeadZero(integer_number)
    {
        if (integer_number > 9) return integer_number.tostring();
        return "0" + integer_number;
    }

    /**
     * Convert date to it string representation in DD-MM-YYYY
     * @param date to convert
     * @return string representation in DD-MM-YYYY
     */
    static function DateStr(date)
    {
        return "" + AIDate.GetDayOfMonth(date) + "-" +   AIDate.GetMonth(date) + "-" + AIDate.GetYear(date);
    }

    /**
     * Hex to Decimal converter
     * @param Hex_number in string to convert
     * @return  number in integer
     * @note max number is 255 or FF
    */
    static function HexToDec(Hex_number)
    {
        if (Hex_number.len() > 2) return 0;
        local aSet = "0123456789ABCDEF";
        return aSet.find(Hex_number.slice(0,1)).tointeger() * 16 + aSet.find(Hex_number.slice(1,2)).tointeger();
    }

	/**
     * Decimal to Hex converter
     * @param dec number to convert
     * @return hex number in string
    */
    static function DecToHex(dec)
	{
		local aSet = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"];
		local tmp = [];
		local c = dec % 16;
		while (true) {
			tmp.push(aSet[c]);
			if (dec < 16) break;
			dec = (dec - c) / 16;
			c = dec % 16;
		}
		if (tmp.len() == 1) tmp.push("0");
		tmp.reverse();
		local ret = "";
		foreach (idx, val in tmp) ret += val;
		return ret;
	}

    /**
     * Push list to array
     * @param list AIList to convert from
     * @return Array of index list
     */
    static function ListToArray(list)
    {
        local array = [];
        foreach(item, lst in list) array.push(item);
        return array;
    }

    /**
     * Make list from array
     * @param array to convert from
     * @return AIList of array value
     */
    static function ArrayToList(array)
    {
        local list = AIList();
        foreach(idx, item in array) list.AddItem(item, 0);
        return list;
    }

	/**
	 * Convert path to array
	 * @param path Path class to convert from
     * @return Array of path.GetTile()
     */
	static function Path2Array(path)
	{
		local anArray = [];
		while (path != null) {
			anArray.push(path.GetTile(), path.GetDirection(), path.GetCost());
			path = path.GetParent();
		}
		return anArray;
	}
	
	/**
	 * Convert array to path
	 * @param anArray array of converted path
     * @return AyStar.Path class
     */
	static function ArrayToPath(anArray)
	{
		if (typeof anArray != "array") return;
		local Ay = Route.Finder;
		local path = null;
		while (anArray.len()) {
			local node = anArray.pop();
			path = Ay.Path(path, node[0], node[1], function(a, b, c, d) { return a;}, node[2]);
		}
		return path;
	}

    /**
	 * Filter Industry that is built on water
	 * @param anIndustry ID of industry
     * @return AIList of non water Industry
     */
     static function NotOnWater(anIndustry) {
		anIndustry.Valuate(AIIndustry.IsValidIndustry);
		anIndustry.RemoveValue(0);
        anIndustry.Valuate(AIIndustry.IsBuiltOnWater);
        anIndustry.RemoveValue(1);
        return anIndustry;
    }
	
	/**
	 * Check existing rail connection
	 * @param path Path class of Rail PF
	 * @return true if it was connected
	 */
	static function CheckRailConnection(path)
	{
	    /* must be executed in exec mode */
	    local ex = AIExecMode();
	    if (path == null || path == false) return false;
	    AILog.Info("Check rail connection Length=" + path.GetLength());
	    while (path != null) {
	        local parn = path.GetParent();
	        if (parn == null ) {
	            local c = Debug.Sign(path.GetTile(), "null");
	            if (!AITile.HasTransportType(path.GetTile(), AITile.TRANSPORT_RAIL)) return false;
	            Debug.UnSign(c);
	        } else {
	            local grandpa = parn.GetParent();
	            if (grandpa == null) {
	                local c = Debug.Sign(parn.GetTile(), "null");
	                if (!AITile.HasTransportType(path.GetTile(), AITile.TRANSPORT_RAIL)) return false;
	                Debug.UnSign(c);
	            } else {
	                if (!AIRail.AreTilesConnected(path.GetTile(), parn.GetTile(), grandpa.GetTile())) {
	                    if (AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) == 1) {
	                        AIRail.BuildRail(path.GetTile(), parn.GetTile(), grandpa.GetTile());
	                    } else {
	                        local c = Debug.Sign(path.GetTile(), "null");
	                        if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == parn.GetTile()) {
	                            if (!AITunnel.IsTunnelTile(path.GetTile())) {
	                                if (!AITunnel.BuildTunnel(AIVehicle.VT_RAIL, path.GetTile())) return false;
	                            }
	                        } else if (AIBridge.GetOtherBridgeEnd(path.GetTile()) == parn.GetTile()) {
	                            if (!AIBridge.IsBridgeTile(path.GetTile())) {
	                                local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) + 1);
	                                bridge_list.Valuate(AIBridge.GetMaxSpeed);
	                                bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
	                                if (!AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), path.GetTile(), parn.GetTile())) {
	                                    while (bridge_list.HasNext()) {
	                                        if (AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Next(), path.GetTile(), parn.GetTile())) break;
	                                    }
	                                }
	                            }
	                        }
	                        Debug.UnSign(c);
	                    }
	                }
	            }
	        }
	        path = parn;
	    }
	    return true;
	}
	
	/**
	 * Try to use sqrt function
	 * @param num number to get square from
	 * @return squared root number
	 * @author zutty (PathZilla)
	 */
	static function SquareRoot(num)
	{
		if (num == 0) return 0;
		local n = (num / 2) + 1;
		local n1 = (n + (num / n)) / 2;
		while (n1 < n) {
			n = n1;
			n1 = (n + (num / n)) / 2;
		}
		return n;
	}
	
	/**
	 * Handle closing industry
	 * @param tabel Tabel of structure catched on Event catcher
	 */
	static function HandleClosingIndustry(tabel)
	{
		/* validating Drop off point */
		if (TransAI.Info.Drop_off_point.rawin(tabel.Loc)) TransAI.Info.Drop_off_point.rawdelete(tabel.Loc);
		TransAI.ServableMan.RemoveItem(tabel.Loc);
		/* is there my station ? */
		local station_list = Tiles.StationOn(tabel.Loc);
		if (station_list.Count() == 0) return;
		local location = -1;
		tabel.CargoAccept.extend(tabel.CargoProduce);
		/* mark vehicle as lost */
		foreach (sta, val in station_list) {
			foreach (vhc, val in AIVehicleList_Station(sta)) {
				foreach (cargo in tabel.CargoAccept) {
					if (Vehicles.CargoType(vhc) == cargo) {
						TransAI.Info.Lost_Vehicle.push(vhc);
						AIController.Sleep(1);
					}
				}
			}
		}
	}
}

/**
 * Debug static functions class
 *
 */
class Debug
{
    /**
     * Evaluate expression, display message,  detect last error.
     * usable for in-line debugging
     * @param msg Message to be displayed
     * @param exp Expression to be displayed and returned
     * @return Value of expression
     */
    static function ResultOf(msg, exp)
    {
        if (AIError.GetLastError() == AIError.ERR_NONE) AILog.Info("" + msg + ":" + exp +" -> Good Job :-D");
        else AILog.Warning("" + msg + ":" + exp + ":" + AIError.GetLastErrorString().slice(4));
        return exp;
    }
    
    /** 
     * No other methode found to clear last err
     */
    static function ClearErr() {
        AISign.RemoveSign(AISign.BuildSign(AIMap.GetTileIndex(2, 2), "debugger"));
    } 

    /**
     * The function that should never called / passed by flow of code.
     * @param msg The message to be displayed
	 * @param suspected The variable to displayed
	 * @note This would only set to make the AI end it's live
     */
    static function DontCallMe(msg, suspected)
    {
        /* I've said, don't call me. So why you call me ?
         * okay, I'll throw you out ! :-( */
        AILog.Warning("Should not come here!" + msg + " suspected --> " + suspected);        
		throw msg;
    }

    /**
	 * Wrapper for build sign.
	 * Its used with Game.Settings
	 * @param tile TileID where to build sign
	 * @param txt Text message to be displayed
	 * @return a valid signID if its allowed by game setting
	*/
	static function Sign(tile, txt)
    {
        if (TransAI.Setting.DebugSign) {
        	if (typeof txt != "string") txt = txt.tostring();
        	return AISign.BuildSign(tile, txt);
        }
    }
    
    /**
     * Unsign is to easy check wether we have build sign before
     * @param id Suspected signID
     */
	static function UnSign(id)
	{
		if (id != null) if (AISign.IsValidSign(id)) AISign.RemoveSign(id); 
	}	
}

/**
 * Game settings related class
 */
class Settings
{
	/** Enable build sign */
	DebugSign = 0;
	/** Bus allowed */
	AllowBus = 0;
	/** Truck allowed */
	AllowTruck = 0;
	/** Train allowed */
	AllowTrain = 0;
	/** Last Month Transported */
	LastMonth = 0;
	/** Loop Time for TaskManager */
	LoopTime = 0;
	
	/**
	 * Get settings from .cfg file
	 * @param setting_str String of settings. Get it from Cons.Settings
	 * @return false if setting is not valid, otherwise return value from .cfg
	 * @note usage : 
	 * AILog.Info(Const.Settings.long_train + " -> " +  Settings.Get(Const.Settings.long_train))
	 */
    function Get(setting_str)
    {
        if (!AIGameSettings.IsValid(setting_str)) throw "Setting no longer valid :" + setting_str;
        return AIGameSettings.GetValue(setting_str);
    }
	
	/**
	 * Check current OpenTTD running version
	 * @return throw if the version is not match
	 */
	function CheckVersion()
	{
		local v = AIController.GetVersion();
		local maj = (v & 0xF0000000) >> 28;
		local minor = (v & 0x0F000000) >> 24;
		local build = (v & 0x00F00000) >> 20;
		local rel = (v & 0x00080000) != 0;
		local rev = v & 0x0007FFFF;
		if (maj < 1) maj = 0;
		AILog.Info("Run On OpenTTD Ver:" + maj + "." + minor + " Build:" + build + " (" + (rel ?  "Release" : "Rev." + rev) + ")");
		if ((maj == 0 && minor < 2) || rev < 17010) throw "Not supported version";
	}
}

/**
 * Ticker class
 */
class Ticker
{
	/** the ticker */
	_tick = null;
	/** class contructor */
	constructor(){
		this._tick = AIController.GetTick();
	}

	/**
	 * Get elapsed tick
	 * @return number of tick elapsed
	 */
	function Elapsed() {return AIController.GetTick() - this._tick; }
	
	/**
	 * Reset tick
	 */
	function Reset() { this._tick = AIController.GetTick(); }
}
