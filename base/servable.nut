/* 
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Servable. Base of serv-able class
  */
class Servable extends CIDLocation
{
	_Area = null;			// tiles arround-date
	_Has_Coast = null;		// truth, date
	_Tried_Station = null;	// type - date
	_Stations = null;		// Tile - ID of of common station
	
	constructor(id, loc, name) {
		CIDLocation.constructor (id, loc);
		SetName(name);
		_Tried_Station = CLList();
		_Has_Coast = [CLList(), 0];
		_Area = [CLList(), 0];
		_Stations = CLList();
	}

	function ValidateArea ();

	function GetArea() {
		ValidateArea();
		return CLList(_Area[0]);
	}    

	function GetStations(s_type) {
		local ret = CLList();
		local gets = GetStationTiles(s_type);
		//gets.SortItemDescending();
		foreach (loc, id in gets) {
			ret.AddItem(id, loc);
		}
		Info (ret.Count(), "station id's found");
		return ret;
	}
    
	function GetStationTiles(s_type) {
		local tiles = GetArea();
		tiles.Valuate(AITile.IsStationTile);
		tiles.KeepValue(1);
		tiles.Valuate(AIStation.GetStationID);
		local retst = CLList();
		foreach (loc, id in tiles) {
			if (AIStation.HasStationType(id, s_type)) retst.AddItem(loc, id);
		}
		Info (retst.Count(), "station tiles found");
		return retst;
	}

	function ValidateCoast() {
		if (_Has_Coast[1] < AIDate.GetCurrentDate()) {
			_Has_Coast[0].Clear();
			_Has_Coast[0].AddList(GetArea());
			_Has_Coast[0].Valuate (AITile.IsCoastTile);
			_Has_Coast[0].KeepValue (1);
			_Has_Coast[0].Valuate(AIMap.DistanceMax, GetLocation());
			_Has_Coast[1] = AIDate.GetCurrentDate() + 360;
		}
	}
	function GetCoast() {
		ValidateCoast();
		return _Has_Coast[0];
	}
	function HasCoast () {
		return GetCoast().Count();
	}
	function GetWaterPoint() {
		local list = GetArea();
		list.Valuate(AITile.HasTransportType, AITile.TRANSPORT_WATER);
		list.KeepValue(1);
		list.Valuate(XMarine.GetWaterSide);
		list.RemoveValue(-1);
		list.Valuate(AIMap.DistanceMax, GetLocation());
		return list;
	}

	function GetExistingRoadStop (dtrs, cargo, s_type, is_source) {
		local stf = GetStations(s_type);
		Info ("found existing", stf.Count());
		foreach (id, tile in stf) {
			local station = XStation.GetManager (id, s_type);
			if (!station.HasRoadStation(dtrs)) continue;
			if (is_source) {
				if (station.GetProduction(cargo) < 10) continue;
			} else {
				if (station.GetAcceptance(cargo) < 10) continue;
			}
			if (station.GetOccupancy () > 99) continue;
			local front = AIRoad.GetRoadStationFrontTile(station.GetLocation());
			if (!XRoad.IsConnectedTo([front], GetRoadPoint().GetItemArray())) {
				Debug.Sign(tile, "not connected?");
				continue;
			}
			return station.GetLocation();
		}
		return -1;
	}

	function GetExistingWaterStop (cargo, is_source) {
		foreach (id, tile in GetStations(AIStation.STATION_DOCK)) {
			local station = XStation.GetManager (id, AIStation.STATION_DOCK);
			if (!station.HasDock()) continue;
			if (is_source) {
				if (station.GetProduction(cargo) < 8) continue;
			} else {
				if (station.GetAcceptance(cargo) < 8) continue;
			}
			return station.GetLocation();
		}
		return -1;
	}

	function GetExistingAirport (plane_type, cargo) {
		foreach (id, tile in GetStations(AIStation.STATION_AIRPORT)) {
			local station = XStation.GetManager (id, AIStation.STATION_AIRPORT);
			if (!station.AllowPlaneType (plane_type)) continue;
			if (station.GetProduction(cargo) < 10) continue;
			if (station.GetAcceptance(cargo) < 10) continue;
			if (station.GetOccupancy () > 99) continue;
			return station.GetLocation();
		}
		return -1;
	}

	function AllowTryStation (s_type) {
		if (!Money.Get (Money.Inflated(10000))) {
			Warn ("we haven't enough money");
			return false;
		}
		if (_Tried_Station.HasItem (s_type)) {
			if (_Tried_Station.GetValue (s_type) > AIDate.GetCurrentDate()) {
				Warn ("we have just build a station there");
				return false;
			}
		}
		local sts = GetStationTiles(s_type);
		local allow = sts.IsEmpty() || (GetArea().Count() > (sts.Count() / XStation.GetDivisorNum(s_type)).tointeger());
		if (allow) {
			Info ("Allowed to try to build station");
		} else {
			Warn ("Station number exceeding limit");
		}
		return allow;
	}

	function AllowTryAirport (type) {
		if (!Money.Get (AIAirport.GetPrice (type) * 1.1)) return false;
		if (_Tried_Airport.HasItem (type)) {
			Info ("ever try to build ", Assist.ATName (type));
			if (_Tried_Airport.GetValue (type) > AIDate.GetCurrentDate()) return false;
			Info ("but that was a year ago :D");
		}
		local airports = GetStations(AIStation.STATION_AIRPORT);
		local num = (GetArea().Count() - airports.Count()) / XAirport.GetDivisorNum(type);
		Info ("airport counts", airports.Count(), "::num", num);
		return num > 0;
	}
	
	function GetAreaForWaterDepot() {
		local list = GetArea();
		list.Valuate (AITile.IsWaterTile);
		list.KeepValue (1);
		list.Valuate(AIMap.DistanceMax, GetLocation ());
		return list;
	}
	
	// TODO :: Dock terraform-ability
	function GetAreaForDock(cargo, is_source) {
		local list = GetCoast();
		local fn = AITile[is_source ? "GetCargoProduction" : "GetCargoAcceptance"];
		list.Valuate (fn, cargo, 1, 1, AIStation.GetCoverageRadius (AIStation.STATION_DOCK));
		//list.KeepAboveValue (8);
		return list;
    
	function GetRoadDepot() {
		return Assist.FindDepot(GetLocation(), AIVehicle.VT_ROAD, AIRoad.GetCurrentRoadType());
	}
	
	function GetWaterDepot() {
		return Assist.FindDepot(GetLocation(), AIVehicle.VT_WATER, 1);
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
}
