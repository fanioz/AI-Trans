/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XIndustry class
 * an AIIndustry eXtension
 */
class XIndustry
{
	function GetID(location, is_source, cargo) {
		local list = CLList((is_source ? AIIndustryList_CargoProducing : AIIndustryList_CargoAccepting)(cargo));
		list.Valuate(AIIndustry.GetAmountOfStationsAround);
		list.RemoveValue(0);
		list.Valuate(AIIndustry.GetDistanceSquareToTile, location);
		//list.RemoveAboveValue(36);
		list.SortValueAscending();
		if (list.Count()) return list.Begin();
		return -1;
	}

	function ProdValue(industry, cargoID) {
		return AIIndustry.GetLastMonthProduction(industry, cargoID) - AIIndustry.GetLastMonthTransported(industry, cargoID);
	}

	function IsRaw(id) {
		return AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(id));
	}

	function GetManager(id) {
		if (!My._Inds_Manager.rawin(id)) {
			My._Inds_Manager.rawset(id, IndustryManager(id));
			My._Inds_Manager[id].RefreshStations();
		}
		return My._Inds_Manager[id];
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
