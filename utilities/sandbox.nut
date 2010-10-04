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
	/**
	 * Convert an AIList to a human-readable string.
	 * @param list The AIList to convert.
	 * @return A string containing all item => value pairs from the list.
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
	 * Sleep Time
	 * @return The amount time for company to sleep :-)
	 */
	function SleepTime()
	{
		if (AICompany.GetLoanAmount() < 20000) return 20;
		return (AICompany.GetLoanAmount() / 500).tointeger();
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
	 * ClearSigns is AISign cleaner
	 * Clear all sign that I have been built while servicing.
	 */
	static function ClearSigns()
	{
		AILog.Info("Clearing signs ...");
		for (local c = AISign.GetMaxSignID(); c > 0; c--) if (AISign.IsValidSign(c)) AISign.RemoveSign(c);
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
	 * @param src Source ID (industry/town)
	 * @param istown Fill true if this is town
	 * @param cargo ID of cargo to be used
	 */
	static function ServiceCost(src, istown, cargo)
	{
		local cost = 0;
		local multiplier = 1;
		local fnAPI = istown ? AITown : AIIndustry ;
		if (istown) cost += AITown.GetMaxProduction(src, cargo)
		else cost += fnAPI.GetLastMonthProduction(src, cargo);
		cost -= fnAPI.GetLastMonthTransported(src, cargo) * multiplier;
		cost +=  AICargo.GetCargoIncome(cargo, 20, 200);
		return cost;
	}

	/**
	 * Average an integer list in array
	 * @param parray Array of integer number
	 * @return Average of number
	 */
	static function Average(parray)
	{
		assert(typeof parray == "array");
		assert(parray.len());
		local sam = 0, count = parray.len();
		foreach (idx, val in parray) sam += val;
		local orgi = (sam * 10 / count).tointeger();
		local mod = orgi % 10;
        local rounded = (mod > 5) ? 1 : 0;
		return  (orgi - mod) / 10 + rounded;
	}

	/**
	 * Valuator function
	 * @param list AIList to valuate
	 * @param valuator Function to be used as valuator
	 * @param ... Additional argument to be passed to
	 */
	 static function Valuate(list, valuator, ...)
	{
		assert(typeof(list) == "instance");
		assert(typeof(valuator) == "function");

		local args = [this, null];
		for(local c = 0; c < vargc; c++) args.append(vargv[c]);
		foreach(idx, val in list) {
			args[1] = idx;
			local value = Assist.ACall(valuator, args);
			if (typeof(value) == "bool") {
				value = value ? 1 : 0;
			} else if (typeof(value) != "integer") throw("Invalid return type from valuator");
			list.SetValue(idx, value);
		}
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
        if (Hex_number.length() > 2) return 0;
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
		local cur = -1;
		while (path != null) {
			anArray.push(path.GetTile());
			path = path.GetParent();
		}
		return anArray; //.reverse();
	}
	
	static function ArrayToPath(anArray, PF)
	{
		if (typeof anArray != "array") return;
		assert(typeof PF == "instance");
		anArray.reverse();
		local Ay = import("graph.aystar", "", 6);				 
		local path = null;
		while (anArray.len()) {
			if (path == null) {
				path = Ay.Path(path, anArray.pop(), 0xFF, PF._Cost, PF);
			} else {
				local par_tile = path.GetParent() ? path.GetParent().GetTile() : null;				
				local cur_node = anArray.pop();
				local next_tile = anArray.len() ? anArray.top() : 0xFF;
				//local isbridge = AIMap.DistanceManhattan(cur_node, next_tile) > 1;
				//local dir = Assist.ACall(PF._GetDirection, [PF, par_tile, cur_node, next_tile, isbridge]); 
				path = Ay.Path(path, cur_node, next_tile, PF._Cost, PF);
			}
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
     * Additional cost for road path finder
     * @param path Path class
     * @param new_tile The next tile
     * @param new_direction The next direction
     * @return integer cost
     */
    static function RoadDiscount(self, path, new_tile, new_direction, serv)
    {
        local new_cost = 0;
        this = self;
        local prev_tile = (path.GetParent() == null) ? new_tile : path.GetParent().GetTile();
        if (AIBridge.IsBridgeTile(new_tile) && (AIBridge.GetOtherBridgeEnd(new_tile) == prev_tile)) {
            local b_id = AIBridge.GetBridgeID(new_tile);
            if (AIBridge.IsValidBridge(b_id)) new_cost -= (AIBridge.GetMaxSpeed(b_id)  + this._cost_bridge_per_tile);
        }
        if (AITunnel.IsTunnelTile(new_tile) && AITunnel.GetOtherTunnelEnd(new_tile) == prev_tile) {
            new_cost -= this._cost_tunnel_per_tile;
        }
        if (AIRoad.IsRoadTile(new_tile) && AIRoad.AreRoadTilesConnected(prev_tile, new_tile)) {
            new_cost -= this._cost_tile * 2;
        }

        if (!AITile.DemolishTile(new_tile) && AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY) {
            new_cost += this._cost_bridge_per_tile * 2;
        }
        //AILog.Info("cost:" + new_cost);
        return new_cost * AIMap.DistanceManhattan(new_tile, prev_tile);
    }

    /**
     * @deprecated Deprecated
     */
    static function Connect_BackBone(serv)
    {
        local _cost = 0;
        if (serv.Info.VehicleType != AIVehicle.VT_RAIL) return true;
        AILog.Info("Try to connect backbone for id " + serv.Info.Key);
        TransAI.Builder.Rail.Path(serv, 2, true);
        TransAI.Builder.State.TestMode = true;

        if (!TransAI.Builder.Rail.Track(serv, 2)) {
            TransAI.Builder.Rail.Path(serv, 2, true);
            if (!TransAI.Builder.Rail.Track(serv, 2)) return false;
        }
        _cost += TransAI.Builder.State.LastCost;
        TransAI.Builder.Rail.Vehicle(serv);
        _cost += TransAI.Builder.State.LastCost;
        TransAI.Builder.Rail.Signal(serv, 1);
        _cost += TransAI.Builder.State.LastCost;
        TransAI.Builder.Rail.Signal(serv, 2);
        _cost += TransAI.Builder.State.LastCost;
        if (!Bank.Get(_cost)) return false;

        TransAI.Builder.State.TestMode = false;
        if (!TransAI.Builder.Rail.Track(serv, 2)) {
            TransAI.Builder.Rail.Path(serv, 2, true);
            if (!TransAI.Builder.Rail.Track(serv, 2)) return false;
        }
        TransAI.Builder.Rail.Signal(serv, 1);
        TransAI.Builder.Rail.Signal(serv, 2);
        TransAI.Builder.Rail.Vehicle(serv);
        return true;
    }

	/**
	 * Get maximum number of tile acceptance/production
	 * @return integer_number
	 */
    static function GetMaxProd_Accept(tiles, cargo, is_source)
    {
        local check_fn = is_source ? AITile.GetCargoProduction : AITile.GetCargoAcceptance;
		tiles.Valuate(check_fn, cargo, 1, 1, Stations.RoadRadius());
        return check_fn(tiles.Begin(), cargo, 1, 1, Stations.RoadRadius());
    }
    
    static function CheckRail(path, new_tile)
	{
	    local new_cost = 0;
	    local prev_tile = path.GetTile();
	    local prev_prev = (path().GetParrent() == null) ? null : path().GetParrent().GetTile() ;
	    if (!AIRail.AreTilesConnected(new_tile, prev_tile, path().GetParrent().GetTile())) new_cost = this._max_cost;
	    return new_cost;
	}
	
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
	            AISign.RemoveSign(c);
	        } else {
	            local grandpa = parn.GetParent();
	            if (grandpa == null) {
	                local c = Debug.Sign(parn.GetTile(), "null");
	                if (!AITile.HasTransportType(path.GetTile(), AITile.TRANSPORT_RAIL)) return false;
	                AISign.RemoveSign(c);
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
	                        AISign.RemoveSign(c);
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
	 * Temporary handle closing industry
	 */
	static function HandleClosingIndustry(id)
	{
		local location = -1;
		location = TransAI.ServableMan.Item(id);
		if (location) TransAI.Info.DropPointIsValid = false;
		//foreach (loc, val in TransAI.Info.Drop_off_point) {			
		//}
		local station_list = Tiles.StationOn(AIIndustry.GetLocation(id));
		if (station_list.Count() == 0) return;
		//todo : handle it !
		local ind_type = AIIndustry.GetIndustryType(id);
		foreach (sta, val in station_list) {
		foreach (vhc, val in AIVehicleList_Station(sta)) {
		foreach (cargo, val in AIIndustryType.GetProducedCargo(ind_type).AddList(AIIndustryType.GetAcceptedCargo(ind_type))) {
		AIController.Sleep(1);
		if (Vehicles.CargoType(vhc) == cargo) TransAI.Info.Lost_Vehicle.push(vhc);
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
        /* no other methode found to clear last err */
        //AISign.RemoveSign(Debug.Sign(AIMap.GetTileIndex(2, 2), "debugger"));
        return exp;
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
        //TransAI.Info.Live = 0;
		throw msg;
    }

    /**
	 * Wrapper for build sign.
	 * prepared for use with Game.Settings
	*/
	static function Sign(tile, txt)
    {
        if (1 == 1) return AISign.BuildSign(tile, txt);
    }

	/**
	 * Assert replacement for custom handling
	 */
	static function Assert(exp)
	{
		if (exp) return true;
		Debug.DontCallMe("Try call null:", exp);
	}
}

class Settings
{
    /* usage : AILog.Info(Const.Settings.long_train + " -> " +  Settings.Get(Const.Settings.long_train)) */
    static function Get(setting_str)
    {
        local temp = AIGameSettings.GetValue(setting_str);
        return (temp == -1) ? false : temp;
    }

	static function Version()
	{
		local v = AIController.GetVersion();
		local maj = (v & 0xF0000000) >> 28;
		local minor = (v & 0x0F000000) >> 24;
		local build = (v & 0x00F00000) >> 20;
		local rel = (v & 0x00080000) != 0;
		local rev = v & 0x0007FFFF;
		if (maj < 1) maj = 0;
		AILog.Info("Running Ver:" + maj + "." + minor + " Build:" + build + " (" + (rel ?  "Release" : "Rev." + rev) + ")");
		if (((minor < 7) && (build < 1)) || (rev < 16537)) throw "Not supported version";
	}
}

class Ticker
{
	_tick = null; ///< the ticker
	constructor(){
		this._tick = AIController.GetTick();
	}

	function Elapsed() {return AIController.GetTick() - this._tick; }
	function Reset() { this._tick = AIController.GetTick(); }
}
