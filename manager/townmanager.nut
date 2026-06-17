/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2026 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that handles towns.
 */
class TownManager extends Servable
{
	_Tried_Airport = null;	// type - date
	_Airports = null;		// Tile - ID of airports
	_Stations = null;		// Tile - ID of of common station
	_lastHouses = -1;		// house count when _Area[0] was last computed
	_lastCenter = -1;		// town center tile when _Area[0] was last computed

	/**
	 * Constructor
	 */
	constructor(id) {
		assert(AITown.IsValidTown(id));
		Servable.constructor(id, AITown.GetLocation(id), AITown.GetName(id));
		_Tried_Airport = CLList();
		_Airports = CLList();
	}

	function GetRoadPoint() {
		local list = CLList();
		if (XRoad.IsRoadTile(GetLocation())) {
			list.AddTile(GetLocation());
		} else {
			list.AddList(GetArea());
			list.Valuate(XRoad.IsRoadTile);
			list.KeepValue(1);
			list.Valuate(XRoad.GetNeighbourRoadCount);
			list.RemoveBelowValue(2);
			list.Valuate(AIMap.DistanceMax, GetLocation());
			list.KeepBelowValue(5);
			list.SortValueAscending();
		}
		return list;
	}

	/**
	 * Recompute the town influence area cache.
	 *
	 * Engine definition of "in town influence": DistanceSquare(center, tile)
	 * <= squared_town_zone_radius[TownEdge], where the radius is a pure function
	 * of the house count (Town::UpdateTownRadius) and the center is the town
	 * location. The cache is reused only while BOTH determinants are unchanged
	 * (verified below) and the 360-day safety window has not elapsed.
	 */
	function ValidateArea() {
		local town_id = GetID();
		local houses = AITown.GetHouseCount(town_id);
		local tile_s = AITown.GetLocation(town_id); // live center, not the cached one

		// Reuse the cache only while both determinants of the influence circle
		// are unchanged. The center tile and the house count fully determine the
		// area (see the engine definition above), so we verify them directly
		// rather than assume the town is fixed or that the radius tracks count.
		if (_Area[1] > AIDate.GetCurrentDate() && houses == _lastHouses && tile_s == _lastCenter) return;

		Info("validating...");
		Info("last update :", Assist.DateStr(_Area[1]), "houses :", houses);

		// Served towns are population-filtered, so R >= 5 (engine: 8+ houses).
		// Influence is an isotropic circle, so probing the axes finds the radius
		// d; take the max over all four directions so an edge town — where one
		// direction truncates early — still measures the true R. square(d) holds
		// the whole circle (|a|,|b| <= d for any influence tile); the filter
		// then trims to exact.
		local d = 5; // served towns have R >= 5; floor the radius there
		foreach (delta in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
			for (local step = 5; ; step++) {
				local t = XTile.AddOffset(tile_s, delta[0] * step, delta[1] * step);
				if (!AIMap.IsValidTile(t)) break;
				if (!AITile.IsWithinTownInfluence(t, town_id)) break;
				Debug.Sign(t, "i");
				if (step > d) d = step;
			}
		}

		_Area[0].Clear();
		_Area[0].AddList(XTile.Radius(tile_s, d, d));
		_Area[0].Valuate(AITile.IsWithinTownInfluence, town_id);
		_Area[0].RemoveValue(0);

		_Area[1] = AIDate.GetCurrentDate() + 360;
		_lastHouses = houses;
		_lastCenter = tile_s;
		Info("influence extent :", d, "area count :", _Area[0].Count());
	}

	/**
	 * Improve the town rating by planting trees until sufficient.
	 * @return true if rating reached the required level
	 */
	function ImproveRating() {
		// try to improve current rating until it is enough
		if (XTown.HasEnoughRating(GetID())) return true;
		local list = GetArea();
		list.Valuate(AITile.IsBuildable);
		list.KeepValue(1);
		list.Valuate(AITile.HasTreeOnTile);
		list.KeepValue(0);
		while (!XTown.HasEnoughRating(GetID())) {
			// Build trees on not yet tree'd to improve the rating
			if (list.IsEmpty()) break;
			local loc = list.Pop();
			while (AITile.PlantTree(loc)) {
				AIController.Sleep(1);
			};
		}
		return XTown.HasEnoughRating(GetID());
	}

	function TryBuildAirport(type, cargo, eng_cost) {
		local est_cost = AIAirport.GetPrice(type) + eng_cost;
		if (!Money.Get(est_cost * 1.1)) return -1;
		_Tried_Airport.AddItem(type, AIDate.GetCurrentDate() + 30);
		if (!ImproveRating()) {
			Info("rating not enough");
			return -1;
		}
		// Attempts to build an airport in the town
		local tiles = GetArea();
		local x = AIAirport.GetAirportWidth(type);
		local y = AIAirport.GetAirportHeight(type);
		local rad = AIAirport.GetAirportCoverageRadius(type);
		Info("area around the town:", tiles.Count());
		foreach(tile, id in _Stations) {
			local ntype = AIAirport.GetAirportType(tile);
			if (ntype == AIAirport.AT_INVALID) continue;
			local nx = AIAirport.GetAirportWidth(ntype);
			local ny = AIAirport.GetAirportHeight(ntype);
			local nrad = AIAirport.GetAirportCoverageRadius(ntype);
			local areas = XTile.MakeArea(tile, nx, ny, nrad);
			tiles.RemoveList(areas);
		}
		Info("tiles left area:", tiles.Count());
		tiles.Valuate(AIAirport.GetNearestTown, type);
		tiles.KeepValue(GetID());
		Info("tiles that are near from the town:", tiles.Count());
		tiles.Valuate(AIAirport.GetNoiseLevelIncrease, type);
		tiles.KeepBelowValue(AITown.GetAllowedNoise(GetID()) + 1);
		Info("tiles without high noise producted:", tiles.Count());
		tiles.DoValuate(XTile.IsBuildableRange, x, y);
		tiles.RemoveValue(0);
		Info("tiles that can have an airport:", tiles.Count());
		if (tiles.IsEmpty()) {
			Info("tiles were emptied");
			return -1;
		}
		local acceptile = CLList(tiles);
		acceptile.Valuate(AITile.GetCargoAcceptance, cargo, x, y, rad);
		// Try every tile
		foreach(location, acc in acceptile) {
			if (acc < 20) continue;
			if (!Money.Get(est_cost + tiles.GetValue(location))) continue;
			if (!ImproveRating()) {
				Warn("rating is not enough");
				break;
			}
			local id = XAirport.RealBuild(location, type, x, y, this);
			if (AIStation.IsValidStation(id)) {
				Info("just build an airport");
				local tiles = AITileList_StationType(id, AIStation.STATION_AIRPORT);
				tiles.Valuate(AIAirport.IsAirportTile);
				tiles.KeepValue(1);
				if (!tiles.IsEmpty()) return tiles.Begin();
				Should_Not_Reached_Here();
			}
		}
		Info("can't build an airport");
		return -1;
	}

	function GetAreaForRoadStation(cargo, is_source) {
		local list = GetArea();
		local fn = AITile[is_source ? "GetCargoProduction" : "GetCargoAcceptance"];
		list.Valuate(AITile.GetMinHeight);
		list.KeepAboveValue(0);
		list.Valuate(XRoad.IsRoadTile);
		list.KeepValue(1);
		list.Valuate(AIRoad.IsDriveThroughRoadStationTile);
		list.KeepValue(0);
		list.Valuate(XRoad.GetNeighbourRoadCount);
		list.KeepAboveValue(0);
		list.Valuate(XTile.IsFlat);
		list.RemoveValue(0);
		list.Valuate(fn, cargo, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP));
		list.KeepAboveValue(8);
		return list;
	}

	function GetAreaForRoadDepot() {
		local town_center = GetLocation();
		local list = GetArea();
		assert(list.Count());
		list.Valuate(AITile.GetCargoProduction, XCargo.Pax_ID, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP));
		if (list.CountIfRemoveAboveValue(25) == 0) {
			foreach(tile, v in list) {
				Debug.Sign(tile, v);
			};
			throw "empty";
		} else {
			list.KeepBelowValue(25);
		}
		list.Valuate(AITile.GetMinHeight);
		list.KeepAboveValue(0);
		assert(list.Count());
		list.Valuate(AITile.IsBuildable);
		list.KeepValue(1);
		assert(list.Count());
		list.Valuate(AIMap.DistanceManhattan, town_center);
		return list;
	}
}
