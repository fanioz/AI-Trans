/*
	This file is part of AI Library - String
	Copyright (C) 2010  OpenTTD NoAI Community

	AI Library - String is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	AI Library - String is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this AI Library - String; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

enum DateStr {
	DateYMD = 0
	DateMDY = 1
	DateDMY = 2
}

/**
 * Library Class
 */
class CLString
{
	///Year - Month - Day
	static DateYMD = DateStr.DateYMD;
	///Month - Day - Year
	static DateMDY = DateStr.DateMDY;
	/// Day - Month - Year
	static DateDMY = DateStr.DateDMY;

	/**
	* Split a string by separator
	* @param str The string to split
	* @param separator the separator to split by
	* @return Array of string that has been splitted
	*/
	static function Split (str, separator) {
		if (typeof str != "string") throw "String::Split => first argumen should be a string";
		if(separator.len() != 1) throw "String::Split => Separator must be one character";
		local s = "";
		local result = [];
		local strlen = str.len();
		for(local idx = 0; idx < strlen; idx++) {
			local ch = str.slice(idx, idx + 1);
			if(ch == separator) {
				if (s.len()) result.push (s);
				s = "";
			} else {
				s += ch;
			}
			if(idx + 1 == strlen) result.push(s);
		}
		return result;
	}

	/**
	 * Join a string by separator
	 * @param arr Array of string to join
	 * @param separator the separator to insert between string
	 * @return a string that has been joined
	 */
	static function Join (arr, separator) {
		local s = "";
		/* clone it as we didn't want to modify the orig array*/
		local a = clone arr;
		a.reverse();
		while (a.len()) {
			local i = a.pop();
			s += i;
			if (a.len())s += separator;
		}
		return s;
	}

	/**
	* Repeat a string
	* @param sentence String to repeat
	* @param count number to repeat
	* @return repeated string
	*/
	static function Repeat (sentence, count) {
		local s = "";
		local a = array (count, sentence);
		while (a.len()) {
			local i = a.pop();
			s += i;
			if (a.len())s += "";
		}
		return s;
	}

	/**
	 * Get plane type as string
	 * @param pt Plane type
	 * @return string of plane type
	*/
	static function PlaneType (pt) {
		switch (pt) {
			case AIAirport.PT_BIG_PLANE :
				return "Big Plane";
			case AIAirport.PT_SMALL_PLANE :
				return "Small Plane";
			case AIAirport.PT_HELICOPTER :
				return "Helicopter";
		}
		return "Invalid plane type";
	}

	/**
	* Get airport type as string
	* @param at Airport type
	* @return string of airport type
	*/
	static function AirportType (at) {
		switch (at) {
			case AIAirport.AT_HELIPORT:
				return "Heliport";
			case AIAirport.AT_HELIDEPOT:
				return "Helidepot";
			case AIAirport.AT_HELISTATION:
				return "HeliStation";
			case AIAirport.AT_SMALL:
				return "Small Airport";
			case AIAirport.AT_COMMUTER:
				return "Commuter";
			case AIAirport.AT_LARGE:
				return "Large Airport";
			case AIAirport.AT_METROPOLITAN:
				return "Metropolitan Airport";
			case AIAirport.AT_INTERNATIONAL:
				return "International Airport";
			case AIAirport.AT_INTERCON:
				return "Intercontinental Airport";
		}
		return "invalid airport type";
	}

	/**
	* Get vehicle type as string
	* @param vt Vehicle type
	* @return string of vehicle type
	*/
	static function VehicleType(vt) {
		switch (vt) {
			case AIVehicle.VT_RAIL:
				return "Rail Vehicle";
			case AIVehicle.VT_ROAD:
				return "Road Vehicle";
			case AIVehicle.VT_WATER:
				return "Water Vehicle";
			case AIVehicle.VT_AIR:
				return "Air Vehicle";
		}
		return "invalid vehicle type";
	}

	/**
	* Get road track type as string
	* @param rt Road type
	* @return string of road track type
	*/
	static function RoadTrackType(rt) {
		switch (rt) {
			case AIRoad.ROADTYPE_ROAD:
				return "Road Track";
			case AIRoad.ROADTYPE_TRAM:
				return "Tram Track";
		}
		return "invalid road track type";
	}

	/**
	* Get rail track type as string
	* @param rt Rail type
	* @return string of rail track type
	*/
	static function RailTrackType(rt) {
		if ((rt < 4) && (rt > -1)) {
			//this would only valid if no NewGRF loaded
			local RailType_Str = ["Rail", "Electric", "Monorail", "Magnetic Levi"];
			return RailType_Str[rt] + " Track";
		}
		return "unknown (NewGRF) rail track type";
	}

	/**
	* Get rail direction as string
	* @param dir Rail Direction
	* @return String of rail direction
	*/
	static function RailDirection (dir) {
		switch (dir) {
			case AIRail.RAILTRACK_NE_SW :
				return "from north-east to south-west";
			case AIRail.RAILTRACK_NW_SE :
				return "from north-west to south-east";
			case AIRail.RAILTRACK_NW_NE :
				return "from north-west to north-east).";
			case AIRail.RAILTRACK_SW_SE :
				return "from south-west to south-east";
			case AIRail.RAILTRACK_NW_SW :
				return "from north-west to south-west";
			case AIRail.RAILTRACK_NE_SE :
				return "from north-east to south-east";
		}
		return "an invalid track direction";
	}

	/**
	* Get station type as string
	* @param st station type
	* @return String of station type
	*/
	static function StationType(st) {
		switch (st) {
			case AIStation.STATION_TRAIN:
				return "Train Station";
			case AIStation.STATION_TRUCK_STOP:
				return "Truck Stop";
			case AIStation.STATION_BUS_STOP:
				return "Bus Stop";
			case AIStation.STATION_AIRPORT:
				return "Airport";
			case AIStation.STATION_DOCK:
				return "Dock";
		}
		return "invalid station type";
	}

	/**
	* Get town effect as string
	* @param te Town effect
	* @return String of Town effect
	*/
	static function TownEffect (te) {
		switch (te) {
			case AICargo.TE_NONE:
				return "has no effect on a town.";
			case AICargo.TE_PASSENGERS :
				return "supplies passengers to a town.";
			case AICargo.TE_MAIL :
				return "supplies mail to a town.";
			case AICargo.TE_GOODS :
				return "supplies goods to a town.";
			case AICargo.TE_WATER :
				return "supplies water to a town.";
			case AICargo.TE_FOOD :
				return "supplies food to a town.";
		}
		return "unknown cargo town effect";
	}

	/**
	* Get tile co-ordinat as string
	* @param idx tile index
	* @return string in the form of [x,y]
	*/
	static function Tile (idx) {
		return "[" + AIMap.GetTileX (idx) + ", " + AIMap.GetTileY (idx) + "]";
	}


	/**
	* Get vehicle state as string
	* @param vs Vehicle state
	* @return String of vehicle state
	*/
	static function VehicleState (vs) {
		switch (vs) {
			case AIVehicle.VS_RUNNING :
				return "The vehicle is currently running";
			case AIVehicle.VS_STOPPED :
				return "The vehicle is stopped manually";
			case AIVehicle.VS_IN_DEPOT :
				return "The vehicle is stopped in the depot";
			case AIVehicle.VS_AT_STATION :
				return "The vehicle is stopped at a station and is currently loading or unloading";
			case AIVehicle.VS_BROKEN :
				return "The vehicle has broken down and will start running again in a while";
			case AIVehicle.VS_CRASHED :
				return "The vehicle is crashed";
		}
		return "Invalid vehicle state";
	}

	/*
	 example :
	 import ("AILib.String", "CString", 1);
	 local cur_date = CString.Date(AIDate.GetCurrentDate(), CString.DateDMY, "-");
	 AILog.Info("Current date " + cur_date);
	*/
	/**
	 * Convert date to it string representation
	 * @param date Date integer to convert
	 * @param date_format One of DateStr Format
	 * @return string of date
	 */
	static function Date (date, date_format, separator) {
		local day = AIDate.GetDayOfMonth (date);
		local month = AIDate.GetMonth (date);
		local year = AIDate.GetYear (date);
		switch (date_format) {
			case DateStr.DateYMD :
				return year + separator + month + separator + day;
			case DateStr.DateMDY :
				return month + separator + day + separator + year;
			case DateStr.DateDMY :
				return day + separator + month + separator + year;
		}
		return "invalid date format";
	}

	/**
	 * Shows key and value foreach record of table into string
	 * @param table Table to show
	 * @return string
	 */
	static function Table(table) {
		if(typeof(table) != "table") throw("String.Table(): argument has to be a table.");
		local ret = "[";
		foreach(a, b in table) {
			ret += a + "=>" + b + ", ";
		}
		ret += "]";
		return ret;
	}


	/**
	 * Shows item and value foreach record of AIList into string
	 * @param list an instance of AIList
	 * @return string
	 */
	static function AIList(list) {
		if(!(list instanceof AIList)) throw("String.AIList(): argument has to be an instance of AIList.");
		local ret = "[";
		if(!list.IsEmpty()) {
			local a = list.Begin();
			ret += a + "=>" + list.GetValue(a);
			if(list.HasNext()) {
				for(local i = list.Next(); list.HasNext(); i = list.Next()) {
					ret += ", " + i + "=>" + list.GetValue(i);
				}
			}
		}
		ret += "]";
		return ret;
	}
}
