/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2026 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XTown class
 * an AITown extension
 */
class XTown
{
	Managers = {};
	function GetManager(id) {
		if (!XTown.Managers.rawin(id)) {
			XTown.Managers.rawset(id, TownManager(id));
			XTown.Managers[id].RefreshStations();
		}
		return XTown.Managers[id];
	}

	function GetID(location) {
		local id = AITile.GetClosestTown(location);
		if (AITown.IsWithinTownInfluence(id, location)) return id;
		return AITile.GetTownAuthority(location);
	}

	function CanAccept(id, cargo) {
		if (!AITown.IsValidTown(id)) return false;
		return XCargo.TileCanAccept(AITown.GetLocation(id), cargo);
	}

	function ProdValue(town, cargoID) {
		return AITown.GetLastMonthProduction(town, cargoID) - AITown.GetLastMonthSupplied(town, cargoID);
	}

	// Build a station need rating -200 => AITown.TOWN_RATING_POOR
	function HasEnoughRating(townID) {
		switch (AITown.GetRating(townID, My.ID)) {
			case AITown.TOWN_RATING_VERY_POOR:
			case AITown.TOWN_RATING_APPALLING:
				return false;
			default :return true;
		}
	}

	function IsOnLocation(id, loc) {
		return AITown.GetLocation(id) == loc;
	}
}
