/*  10.03.01 - xtown.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XTown class
 * an AITown extension
 */
class XTown
{
	function GetManager (id) {
		if (!My._Town_Manager.rawin(id)) {
			My._Town_Manager.rawset (id, TownManager (id));
			My._Town_Manager[id].RefreshStations();
		}
		return My._Town_Manager[id];
	}
	function GetID (location) {
		local id = AITile.GetClosestTown (location);
		if (AITown.IsWithinTownInfluence (id, location)) return id;
		local lst = AITownList();
		lst.Valuate (AITown.IsWithinTownInfluence, location);
		lst.KeepValue (1);
		if (lst.Count()) return lst.Begin();
		return -1;
	}

	function CanAccept (id, cargo) {
		if (!AITown.IsValidTown (id)) return false;
		return XCargo.TileCanAccept (AITown.GetLocation (id), cargo);
	}

	function ProdValue (town, cargoID) {
		return AITown.GetLastMonthProduction (town, cargoID) - AITown.GetLastMonthTransported (town, cargoID);
	}

	// Build a station need rating -200 => AITown.TOWN_RATING_POOR
	function HasEnoughRating (townID) {
		switch (AITown.GetRating (townID, My.ID)) {
			case AITown.TOWN_RATING_VERY_POOR:
			case AITown.TOWN_RATING_APPALLING:
				return false;
			default :return true;
		}
	}

	/**
	 * Get the maximum number of station on town.
	 * @return The maximum number
	 */
	function MaxStation(townID, divisor) {
		return max (1, AITown.GetPopulation (townID) / divisor);
	}
	
	function IsOnLocation(id, loc) {
		return AITown.GetLocation(id) == loc;
	}
}

