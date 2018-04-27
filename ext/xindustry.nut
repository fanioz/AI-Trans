/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XIndustry class
 * an AIIndustry eXtension
 */
class XIndustry
{
	Managers = {};
	
	/**
	@param locations - AITileListStationType
	*/
	function GetID(locations, is_source, cargo) {
		local list = CLList((is_source ? AIIndustryList_CargoProducing : AIIndustryList_CargoAccepting)(cargo));
		list.Valuate(AIIndustry.GetAmountOfStationsAround);
		list.RemoveValue(0);
		list.Valuate(function(id, loc) {return AIMap.DistanceMax(AIIndustry.GetLocation(id), loc);}, locations.Begin());
		list.RemoveAboveValue(20);
		list.SortValueAscending();
		while (list.Count()) {
			//print(list.GetValue(list.Peek()));
			local id = list.Pop();
			local industryTiles = (is_source ? AITileList_IndustryProducing:AITileList_IndustryAccepting)(id, 5);
			industryTiles.KeepList(locations);
			if (industryTiles.Count()>0) return id;
		}
		return -1;
	}

	function ProdValue(industry, cargoID) {
		return AIIndustry.GetLastMonthProduction(industry, cargoID) - AIIndustry.GetLastMonthTransported(industry, cargoID);
	}

	function IsRaw(id) {
		return AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(id));
	}

	function GetManager(id) {
		if (!XIndustry.Managers.rawin(id)) {
			XIndustry.Managers.rawset(id, IndustryManager(id));
			XIndustry.Managers[id].RefreshStations();
		}
		return XIndustry.Managers[id];
	}

	function GetDest(industryid) {
		local ret = {};
		foreach(cargo , v in AICargoList_IndustryProducing(industryid)) {
			local targets = AIIndustryList_CargoAccepting(cargo);
			targets.Valuate(AIIndustry.GetLocation);
			foreach(id, loc in targets) {
				ret[loc] <- IndustryManager(id);
				ret[loc]._Dests = XIndustry.GetDest(id);
			}
		}
		return ret;
	}

	function IsOnLocation(id, loc) {
		return AIIndustry.GetLocation(id) == loc;
	}
}
