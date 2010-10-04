/*  10.02.27 - townmanager.nut.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
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

	/**
	 * Constructor
	 */
	constructor (id) {
		assert (AITown.IsValidTown (id));
		Servable.constructor (id, AITown.GetLocation (id), AITown.GetName (id));
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

	function ValidateArea () {
		if (_Area[1] > AIDate.GetCurrentDate()) return;
		Info ("validating...");
		Info ("last update :", Assist.DateStr (_Area[1]));
		local tile_s = GetLocation();
		local rad = 20;
		local num = -1;
		while (num < _Area[0].Count()) {
			AIController.Sleep(1);
			num = _Area[0].Count();
			_Area[0].Clear();
			rad++;
			_Area[0].AddList (XTile.Radius (tile_s, rad, rad));
			_Area[0].Valuate (AITile.IsWithinTownInfluence, GetID());
			_Area[0].RemoveValue (0);
		}
		_Area[1] = AIDate.GetCurrentDate() + 360;
		Info ("area count" + _Area[0].Count());
	}

	function ImproveRating () {
		// try to improve current rating until it is enough
		if (XTown.HasEnoughRating (GetID())) return true;
		local list = GetArea ();
		list.Valuate (AITile.IsBuildable);
		list.KeepValue (1);
		list.Valuate (AITile.HasTreeOnTile);
		list.KeepValue (0);
		while (!XTown.HasEnoughRating (GetID())) {
			// Build trees on not yet tree'd to improve the rating
			if (list.IsEmpty()) break;
			local loc = list.Pop();
			while (AITile.PlantTree (loc)) {
				AIController.Sleep (1);
			};
		}
		return XTown.HasEnoughRating (GetID());
	}
	function GetRoadDepot() {
		return Assist.FindDepot(GetLocation(), AIVehicle.VT_ROAD, AIRoad.GetCurrentRoadType());
	}
	function GetWaterDepot() {
		return Assist.FindDepot(GetLocation(), AIVehicle.VT_WATER, 1);
	}
	
	function TryBuildAirport (type, cargo, eng_cost) {
		local est_cost = AIAirport.GetPrice (type) + eng_cost;
		if (!Money.Get (est_cost * 1.1)) return -1;
		_Tried_Airport.AddItem (type, AIDate.GetCurrentDate() + 30);
		if (!ImproveRating()) {
			Info ("rating not enough");
			return -1;
		}
		// Attempts to build an airport in the town
		local tiles = GetArea();
		local x = AIAirport.GetAirportWidth (type);
		local y = AIAirport.GetAirportHeight (type);
		local rad = AIAirport.GetAirportCoverageRadius (type);
		Info ("area around the town:", tiles.Count());
		foreach (tile, id in _Stations) {
			local ntype = AIAirport.GetAirportType(tile);
			if (ntype == AIAirport.AT_INVALID) continue;
			local nx = AIAirport.GetAirportWidth (ntype);
			local ny = AIAirport.GetAirportHeight (ntype);
			local nrad = AIAirport.GetAirportCoverageRadius (ntype);
			local areas = XTile.MakeArea(tile, nx, ny, nrad);
			tiles.RemoveList(areas);
		}
		Info ("tiles left area:", tiles.Count());
		tiles.Valuate (AIAirport.GetNearestTown, type);
		tiles.KeepValue (GetID());
		Info ("tiles that are near from the town:", tiles.Count());
		tiles.Valuate (AIAirport.GetNoiseLevelIncrease, type);
		tiles.KeepBelowValue (AITown.GetAllowedNoise (GetID()) + 1);
		Info ("tiles without high noise producted:", tiles.Count());
		tiles.DoValuate (XTile.IsBuildableRange, x, y);
		tiles.RemoveValue (0);
		Info ("tiles that can have an airport:", tiles.Count());
		if (tiles.IsEmpty()) {
			Info ("tiles were emptied");
			return -1;
		}
		local acceptile = CLList(tiles);
		acceptile.Valuate (AITile.GetCargoAcceptance, cargo, x, y, rad);
		// Try every tile
		foreach (location, acc in acceptile) {
			if (acc < 20) continue;
			if (!Money.Get (est_cost + tiles.GetValue(location))) continue;
			if (!ImproveRating()) {
				Warn ("rating is not enough");
				break;
			}
			local id = XAirport.RealBuild (location, type, x, y, this);
			if (AIStation.IsValidStation (id)) {
				Info ("just build an airport");
				return location;
			}
		}
		Info ("can't build an airport");
		return -1;
	}
	function RefreshStations () {
		local area = GetArea();
		local tiles = CLList(area);
		local checked = CLList();
		tiles.Valuate(AIStation.GetStationID);
		foreach (tile, id in tiles) {
			if (!AIStation.IsValidStation (id)) continue;
			if (AIStation.HasStationType(id, AIStation.STATION_AIRPORT)) {
				local type = 1 << AIAirport.GetAirportType(tile);
				if (checked.HasItem(id) && Assist.HasBit(checked.GetValue(id), type)) continue;
				checked.AddItem(id, checked.GetValue(id) | type);
			}
			if (AIStation.HasStationType(id, AIStation.STATION_TRAIN)) {
				local type = 1 << AIRail.GetRailType(tile);
				if (checked.HasItem(id) && Assist.HasBit(checked.GetValue(id), type)) continue;
				checked.AddItem(id, checked.GetValue(id) | type);
			}
			_Stations.AddItem(tile, id);
		}
	}
	
	function GetAreaForRoadStation(cargo, is_source) {
		local list = GetArea();
		local fn = AITile[is_source ? "GetCargoProduction" : "GetCargoAcceptance"]; 
		list.Valuate (AITile.GetMinHeight);
		list.KeepAboveValue (0);
		list.Valuate (XRoad.IsRoadTile);
		list.KeepValue (1);
		list.Valuate(AIRoad.IsDriveThroughRoadStationTile);
		list.KeepValue (0);
		list.Valuate (XRoad.GetNeighbourRoadCount);
		list.KeepAboveValue (0);
		list.Valuate (XTile.IsFlat);
		list.RemoveValue(0);
		list.Valuate (fn, cargo, 1, 1, AIStation.GetCoverageRadius (AIStation.STATION_BUS_STOP));
		list.KeepAboveValue (10);
		return list;
	}
	
	function GetAreaForRoadDepot() {
		local town_center = GetLocation ();
		local list = GetArea();
		assert(list.Count());
		list.Valuate (AITile.GetCargoProduction, XCargo.Pax_ID, 1, 1, AIStation.GetCoverageRadius (AIStation.STATION_BUS_STOP));
		if (list.CountIfRemoveAboveValue(25) == 0) {
			foreach (tile, v in list) {
				Debug.Sign(tile, v);
			};
			throw "empty";
		} else {
			list.KeepBelowValue(25);
		}
		list.Valuate (AITile.GetMinHeight);
		list.KeepAboveValue (0);
		assert(list.Count());
		list.Valuate (AITile.IsBuildable);
		list.KeepValue (1);
		assert(list.Count());
		list.Valuate(AIMap.DistanceManhattan, town_center);
		return list;
	}
}
