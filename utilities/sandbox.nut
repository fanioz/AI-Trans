/*  10.02.27 - sandbox.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
* General un categorized functions to assist program
 */
class Assist
{
	function GetManager(loc) {
		local tl = AITownList();
		tl.Valuate(XTown.IsOnLocation, loc);
		tl.KeepValue(1);
		if (!tl.IsEmpty()) {
			return XTown.GetManager(tl.Begin());
		}
		tl.AddList(AIIndustryList());
		tl.Valuate(XIndustry.IsOnLocation, loc);
		tl.KeepValue(1);
		if (tl.IsEmpty()) return;
		return XIndustry.GetManager(tl.Begin());
	}
	//find depot near tile for vt and tt
	function FindDepot(near, vt, tt) {
		local depots = CLList(AIDepotList(vt));
		switch (vt) {
			case AIVehicle.VT_RAIL:
				depots.Valuate(XRail.HasRail, tt);
				break;
			case AIVehicle.VT_AIR:
				depots.Valuate(XAirport.HasPlaneType, tt);
				break;
			case AIVehicle.VT_ROAD:	
				depots.Valuate(AIRoad.IsRoadDepotTile);
				break;
			case AIVehicle.VT_WATER:	
				depots.Valuate(AIMarine.IsWaterDepotTile);
				break;
			default :
				return -1;
		}
		depots.KeepValue(1);
		depots.Valuate(AIMap.DistanceMax, near);
		depots.RemoveAboveValue(15);
		depots.SortValueAscending();
		foreach (body, v in depots) {
			return body;
		}
		return -1;
	}
	function SumValue(list) {
		local ret = 0;
		foreach (idx, val in list) ret += val;
		return ret;
	}
	function IncomeTown (town1, loc2, cargoID, engID) {
		//print(AITown.GetName(town1) + ":to:" + AITown.GetName(town2));
		local distance = AITown.GetDistanceManhattanToTile (town1, loc2);
		local product = XTown.ProdValue (town1, cargoID);
		local mult = Service.GetSubsidyPrice(AITown.GetLocation(town1), loc2, cargoID);
		return Assist.Estimate (product, distance, cargoID, engID, mult);
	}
	function IncomeIndustry (inds1, loc2, cargoID, engID) {
		//print(AIIndustry.GetName(inds1) + ":to:" + AIIndustry.GetName(inds2));
		local distance = AIIndustry.GetDistanceManhattanToTile (inds1, loc2) * 2;
		local product = XIndustry.ProdValue (inds1, cargoID);
		local mult = Service.GetSubsidyPrice(AIIndustry.GetLocation(inds1), loc2, cargoID);
		return Assist.Estimate (product, distance, cargoID, engID, mult);
	}
	
	function Estimate (product, distance, cargoID, engID, mult) {
		local spd = AIEngine.GetMaxSpeed (engID);
		local days = Assist.TileToDays (distance, spd) + 4;
		local income = AICargo.GetCargoIncome (cargoID, distance, days) * mult;
		local cap = AIEngine.GetCapacity (engID);
		//local vhcneed = max(XVehicle.Needed (product, cap, days), 1);
		//local price =  AIEngine.GetPrice (engID);// * vhcneed;
		local vhc_num = Money.Maximum() / AIEngine.GetPrice (engID) * 10;
		local cost = AIEngine.GetRunningCost (engID) * vhc_num / 10;
		//local profit = 12 * income * product - cost;
		local profit = 365 / days * income * cap * vhc_num / 10 - cost;
		//local rrate = (profit * 100 / price).tointeger();
		//print("=> :Vehicle needed: " + vhcneed + " :Cost: " + cost);
		//print("=> at distance: " + distance);
		//print("=> at speed: " + spd);
		//print("=> days: " + days);
		//print("=> base:: :income: " + income + " :Prod: " + product);
		//My.Info("=> :Profit estimated: ", profit);
		//print("=> :return rate: " + rrate);
		//return rrate ;
		return profit;
	}

	// estimated how many days need to travel with certain speed
	// using http://wiki.openttd.org/wiki/index.php?title=Game_mechanics&oldid=30090
	// dist_tile * 686km / (speed / 1.00584)kmph / 24h
	function TileToDays (dist, speed) {
		return (dist * 56.8347517166415 / speed).tointeger()
	}	

	function AntiDistance (a, b) {
		return 100000 - AIMap.DistanceManhattan (a, b);
	}
	//return true if n is between n1 and n2 (exclusive)
	function IsBetween (n, n1, n2) {
		return (n1 < n) && (n < n2);
	}

	function Split (str, separator) {
		assert (separator.len() == 1);
		assert (typeof str = "string");
		local s = "";
		local result = [];
		foreach (idx, val in str) {
			if (val == separator) {
				if (s.len()) result.push (s);
				s = "";
			} else {
				s += val;
			}
		}
		return result;
	}

	function Join (arr, separator) {
		local s = "";
		local a = clone arr;
		a.reverse();
		while (a.len()) {
			local i = a.pop();
			s += i;
			if (a.len())  s += separator;
		}
		return s;
	}

	function RepeatStr (s, count) {
		return Assist.Join (array (count, s), "");
	}

	function PTName (pt) {
		switch (pt) {
			case AIAirport.PT_BIG_PLANE :
				return "PT_BIG_PLANE";
			case AIAirport.PT_SMALL_PLANE :
				return "PT_SMALL_PLANE";
			case AIAirport.PT_HELICOPTER :
				return "PT_HELICOPTER";
		}
		return "Invalid plane type";
	}

	function PT_to_AT (pt) {
		local at = [];
		switch (pt) {
			case AIAirport.PT_HELICOPTER :
				at.push (AIAirport.AT_HELIPORT);
				at.push (AIAirport.AT_HELIDEPOT);
				at.push (AIAirport.AT_HELISTATION);
			case AIAirport.PT_SMALL_PLANE :
				at.push (AIAirport.AT_SMALL);
				at.push (AIAirport.AT_COMMUTER);
			case AIAirport.PT_BIG_PLANE :
				at.push (AIAirport.AT_LARGE);
				at.push (AIAirport.AT_METROPOLITAN);
				at.push (AIAirport.AT_INTERNATIONAL);
				at.push (AIAirport.AT_INTERCON);
				return at;
		}
		return [AIAirport.AT_INVALID];
	}

	function ATName (at) {
		switch (at) {
			case AIAirport.AT_HELIPORT:
				return "AT_HELIPORT";
			case AIAirport.AT_HELIDEPOT:
				return "AT_HELIDEPOT";
			case AIAirport.AT_HELISTATION:
				return "AT_HELISTATION";
			case AIAirport.AT_SMALL:
				return "AT_SMALL";
			case AIAirport.AT_COMMUTER:
				return "AT_COMMUTER";
			case AIAirport.AT_LARGE:
				return "AT_LARGE";
			case AIAirport.AT_METROPOLITAN:
				return "AT_METROPOLITAN";
			case AIAirport.AT_INTERNATIONAL:
				return "AT_INTERNATIONAL";
			case AIAirport.AT_INTERCON:
				return "AT_INTERCON";
		}
		return "invalid airport type";
	}

	/**
	 * RemoveAllSigns is AISign cleaner
	 * Clear all sign that I have been built while servicing.
	 */
	function RemoveAllSigns() {
		Info ("Clearing signs ...");
		foreach (signID , v in AISignList()) {
			AISign.RemoveSign (signID);
		}
	}

	function Left (num, str) {
		if (str) {
			if (str.len() > num) return str.slice (0, num);
			return str;
		}
		return "";
	}

	function HasBit (item, bit) {
		return (item & bit) != 0;
	}
	function SetBitOff (item, bit) {
		if (Assist.HasBit(item, bit)) {
			item = item & ~bit;
		}
		return item;
	}

	function BuildAllTrack (head) {
		assert(AIMap.IsValidTile(head));
		foreach (track in Const.RailTrack) {
			if (!AIRail.BuildRailTrack (head, track)) return track;
		}
		return 0;
	}
	
	/**
	 * Find modus
	 * @param anarray Array of numbers to find
	 */
	function Modus (anarray) {
	 	local t = AIList();
	 	foreach (num in anarray) t.AddItem(num, t.GetValue(num) + 1);
	 	t.Sort(AIAbstractList.SORT_BY_VALUE, false);
	 	return t.Begin();
	 }
	 
	 /**
	 * Check if parameter is not true
	 * @param val val to evaluate
	 * @return true if val is null
	 */
	function IsNot (val) {
		return !val;
	}

	/**
     * Lead a number with zero
     * this will solve problem of '09' that displayed '9' only
     * @param integer_number to convert
     * @return number in string
     * @note only for number below 10
     */
	function LeadZero (integer_number) {
        if (integer_number > 9) return integer_number.tostring();
        return "0" + integer_number;
    }

    /**
     * Convert date to it string representation in DD-MM-YYYY
     * @param date to convert
     * @return string representation in DD-MM-YYYY
     */
	function DateStr (date) {
		return Assist.Join ([AIDate.GetDayOfMonth (date), AIDate.GetMonth (date), AIDate.GetYear (date) ], "-");
    }

    /**
     * Hex to Decimal converter
     * @param Hex_number in string to convert
     * @return  number in integer
     * @note max number is 255 or FF
    */
	function HexToDec (Hex_number) {
        if (Hex_number.len() > 2) return 0;
        local aSet = "0123456789ABCDEF";
        return aSet.find(Hex_number.slice(0,1)).tointeger() * 16 + aSet.find(Hex_number.slice(1,2)).tointeger();
    }

	/**
     * Decimal to Hex converter
     * @param dec number to convert
     * @return hex number in string
    */
	function DecToHex (dec) {
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
}

function min (x, y) { 
	if (x > y) return y;
	return x;
}

function max (x, y) { 
	if (x < y) return y;
	return x;
}
