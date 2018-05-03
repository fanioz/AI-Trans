/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
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
	function FindDepot(near, limit, vt, tt) {
		local depots = CLList(AIDepotList(vt));
		switch (vt) {
			case AIVehicle.VT_RAIL:
				depots.Valuate(XRail.HasRail, tt);
				break;
			case AIVehicle.VT_AIR:
				depots.Valuate(XAirport.HasPlaneType, tt);
				break;
			case AIVehicle.VT_ROAD:
				local depot = -1;
				local ct = [AIRoad.GetCurrentRoadType()];
				if (ct[0] != tt) AIRoad.SetCurrentRoadType(tt);
				ct.push(AIRoad.GetCurrentRoadType());
				depots.Valuate(AIRoad.IsRoadDepotTile);
				depots.KeepValue(1);
				if (depots.Count() > 0) { 
					local pf =  Road_PT();
					pf.InitializePath([near], depots.ItemsToArray(), []);
					pf._max_len = limit;
					local path = pf.FindPath(1000);
					if (path) depot = path.GetTile();
				}
				if (ct[0] != ct[1]) AIRoad.SetCurrentRoadType(ct[0]); 
				return depot;
				break;
			case AIVehicle.VT_WATER:
				local depot = -1;
				depots.Valuate(AIMarine.IsWaterDepotTile);
				depots.KeepValue(1);
				if (depots.Count() > 0) { 
					local pf =  Water_PT();
					pf.InitializePath([near], depots.ItemsToArray(), []);
					pf._max_len = limit;
					local path = pf.FindPath(1000);
					if (path) depot = path.GetTile();
				}
				return depot;
				break;
			default :
				return -1;
		}
		depots.KeepValue(1);
		depots.Valuate(AIMap.DistanceMax, near);
		depots.RemoveAboveValue(limit);
		depots.SortValueAscending();
		foreach(body, v in depots) {
			return body;
		}
		return -1;
	}

	function SumValue(list) {
		local ret = 0;
		foreach(idx, val in list) ret += val;
		return ret;
	}

	function IncomeTown(town1, loc2, cargoID, engID) {
		//print(AITown.GetName(town1) + ":to:" + AITown.GetName(town2));
		local distance = AITown.GetDistanceManhattanToTile(town1, loc2);
		local product = XTown.ProdValue(town1, cargoID);
		local mult = Service.GetSubsidyPrice(AITown.GetLocation(town1), loc2, cargoID);
		return Assist.Estimate(product, distance, cargoID, engID, mult);
	}

	function Estimate(product, distance, cargoID, engID, mult) {
		local spd = AIEngine.GetMaxSpeed(engID);
		local days = Assist.TileToDays(distance, spd) + 4;
		local income = AICargo.GetCargoIncome(cargoID, distance, days) * mult;
		local cap = AIEngine.GetCapacity(engID);
		//local vhcneed = max(XVehicle.Needed (product, cap, days), 1);
		//local price =  AIEngine.GetPrice (engID);// * vhcneed;
		local vhc_num = Money.Maximum() / AIEngine.GetPrice(engID) * 10;
		local cost = AIEngine.GetRunningCost(engID) * vhc_num / 10;
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
	function TileToDays(dist, speed) {
		return (dist * 56.8347517166415 / speed).tointeger()
		   }

		   //return true if n is between n1 and n2 (exclusive)
	function IsBetween(n, n1, n2) {
		return (n1 < n) && (n < n2);
	}

	function PT_to_AT(pt) {
		local at = [];
		switch (pt) {
			case AIAirport.PT_HELICOPTER :
				at.push(AIAirport.AT_HELIPORT);
				at.push(AIAirport.AT_HELIDEPOT);
				at.push(AIAirport.AT_HELISTATION);
			case AIAirport.PT_SMALL_PLANE :
				at.push(AIAirport.AT_SMALL);
				at.push(AIAirport.AT_COMMUTER);
			case AIAirport.PT_BIG_PLANE :
				at.push(AIAirport.AT_LARGE);
				at.push(AIAirport.AT_METROPOLITAN);
				at.push(AIAirport.AT_INTERNATIONAL);
				at.push(AIAirport.AT_INTERCON);
				return at;
		}
		return [AIAirport.AT_INVALID];
	}

	/**
	 * RemoveAllSigns is AISign cleaner
	 * Clear all sign that I have been built while servicing.
	 */
	function RemoveAllSigns() {
		Info("Clearing signs ...");
		foreach(signID , v in AISignList()) {
			AISign.RemoveSign(signID);
		}
	}

	function Left(num, str) {
		if (str) {
			if (str.len() > num) return str.slice(0, num);
			return str;
		}
		return "";
	}

	function HasBit(item, bit) {
		return (item & bit) != 0;
	}

	function SetBitOff(item, bit) {
		if (Assist.HasBit(item, bit)) {
			item = item & ~bit;
		}
		return item;
	}

	function BuildAllTrack(head) {
		assert(AIMap.IsValidTile(head));
		foreach(track in Const.RailTrack) {
			if (!AIRail.BuildRailTrack(head, track)) return track;
		}
		return 0;
	}

	/**
	 * Find modus
	 * @param anarray Array of numbers to find
	 */
	function Modus(anarray) {
		local t = AIList();
		foreach(num in anarray) t.AddItem(num, t.GetValue(num) + 1);
		t.Sort(AIList.SORT_BY_VALUE, false);
		return t.Begin();
	}

	/**
	* Convert date to it string representation in DD::MM::YYYY
	* @param date to convert
	* @return string representation in DD::MM::YYYY
	*/
	function DateStr(date) {
		return CLString.Date(date, CLString.DateDMY, "::");
	}
}

function min(x, y)
{
	if (x > y) return y;
	return x;
}

function max(x, y)
{
	if (x < y) return y;
	return x;
}
