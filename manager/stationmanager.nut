/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that manages existing stations.
 */
class StationManager extends Infrastructure
{
	_is_drop_station = null; /// True if this stations is used for drop-off.
	_voter = null;
	_tiles = null;
	_s_type = null;

	/**
	 * Create a new StationManager.
	 * @param station_id The StationID of the station to manage.
	 */
	constructor(id, s_type) {
		assert(AIStation.HasStationType(id, s_type));
		_s_type = s_type;
		_tiles = CLList(AITileList_StationType(id, s_type));
		assert(_tiles.Count());
		_tiles.SortItemAscending();
		Infrastructure.constructor(id , _tiles.Begin());
		SetName(AIStation.GetName(id));
		SetVType(XStation.GetVTipe(s_type));
		_is_drop_station = false;
		_voter = 0;
	}

	function GetSType() { return _s_type; }

	function GetArea() { return CLList(_tiles); }

	function HasRailTrack(track) {
		local tiles = GetArea();
		tiles.Valuate(XRail.HasRail, track);
		tiles.KeepValue(1);
		return !tiles.IsEmpty();
	}

	function HasRoadStation(dtrs) {
		local tiles = GetArea();
		tiles.Valuate(AIRoad.IsDriveThroughRoadStationTile);
		foreach(tst, is_dtrs in tiles) {
			if (dtrs && is_dtrs != 1) continue;
			return true;
		}
		return false;
	}

	function AllowPlaneType(pt) {
		return XAirport.AllowPlaneToLand(pt, AIAirport.GetAirportType(GetLocation()));
	}

	function HasDock() {
		return AIStation.HasStationType(GetID(), AIStation.STATION_DOCK);
	}

	function Refresh() {
		_tiles = CLList(AITileList_StationType(GetID(), GetSType()));
		local vhc_lst = AIVehicleList_Station(GetID());
		vhc_lst.Valuate(AIOrder.IsGotoStationOrder, 1);
		vhc_lst.KeepValue(1);
		vhc_lst.Valuate(AIOrder.GetOrderDestination, 1);
		local vote = 0;
		foreach(vhc, dst in vhc_lst) {
			vote += (AIStation.GetStationID(dst) == GetID()) ? 1 : -1;
		}
		_is_drop_station = vote > 1;
		Rename();
	}

	function GetTileRadiuzed() {
		local tiles = CLList();
		foreach(s_type in Const.StationType) {
			if (!AIStation.HasStationType(GetID(), s_type)) continue;
			local tilelist = CLList(AITileList_StationType(GetID(), s_type));
			if (s_type == AIStation.STATION_AIRPORT) {
				local type = AIAirport.GetAirportType(tilelist.Begin());
				tiles.AddList(XTile.MakeArea(tilelist.Begin(), AIAirport.GetAirportWidth(type), AIAirport.GetAirportHeight(type), AIAirport.GetAirportCoverageRadius(type)));
			} else {
				foreach(tile, v in tilelist) {
					local area = XTile.MakeArea(tile, 1, 1, AIStation.GetCoverageRadius(s_type));
					tiles.AddList(area);
				}
			}
		}
		return tiles;
	}

	function GetProduction(cargo) {
		local tiles = GetTileRadiuzed();
		tiles.Valuate(AITile.GetCargoProduction, cargo, 1, 1, 1);
		local ret = Assist.SumValue(tiles);
		Debug.Sign(GetLocation(), "prd:" + ret);
		return ret;
	}

	function GetAcceptance(cargo) {
		local tiles = GetTileRadiuzed();
		tiles.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 1);
		local ret = Assist.SumValue(tiles);
		Debug.Sign(GetLocation(), "acc:" + ret);
		return ret;
	}

	/**
	 * Can use part of station wich is defined as :
	 * @param cargo cargo to transport from/to
	 * @return true if this station can be used
	 */
	function CanAddNow(cargo) {
		Info("checking usability");

		local vhcl = CLList(AIVehicleList_Station(GetID()));
		vhcl.Valuate(XCargo.OfVehicle);
		vhcl.KeepValue(cargo);
		if (vhcl.Count() < 2) return true;

		local area = GetArea();
		if (area.IsEmpty()) {
			Info("tile list is empty");
			return false;
		}
		local max_vhc = 2;

		local rad = 1;
		switch (GetSType()) {
			case AIStation.STATION_DOCK:
				rad -= 3;
			case AIStation.STATION_BUS_STOP:
			case AIStation.STATION_TRUCK_STOP:
				max_vhc = area.Count() * 2;
				rad += 3;
				break;
			case AIStation.STATION_AIRPORT:
				rad += 11;
				max_vhc = XAirport.MaxPlane(AIAirport.GetAirportType(GetLocation()));
				break;
			case AIStation.STATION_TRAIN:
				rad += 5;
				max_vhc = (area.Count() / 2).tointeger();
				break;
			default :
				Info("station type invalid");
				return false;
		}
		local catched = CLList(), v_in_range = CLList();
		while (catched.Count() < max_vhc) {
			if (area.IsEmpty()) {
				_voter--;
				Info("Voter say", _voter);
				return _voter < 10;
			}
			local tile = area.Pop();
			AIController.Sleep(1);
			v_in_range.AddList(vhcl);
			v_in_range.Valuate(XVehicle.DistanceMax, tile, rad);
			v_in_range.KeepValue(1);
			catched.AddList(v_in_range);
		}
		_voter += catched.Count() - max_vhc;
		Info("Vehicle catched", catched.Count(), "of max.", max_vhc);
		Info("Voter say", _voter);
		return false;
	}

	/**
	 * Rename the station
	 */
	function Rename() {
		local text = _is_drop_station ? "Dest" : "Source";
		if (GetName().find(text) == null) {
			AIStation.SetName(GetID(), CLString.Join(["Trans", text, GetID()], "."));
			SetName(AIStation.GetName(GetID()));
		}
	}

	/**
	 * Query if this station is a cargo drop station.
	 * @return Whether this station is a cargo drop station.
	 */
	function IsCargoDrop() {
		return _is_drop_station;
	}

	/**
	 * Set whether this station is a cargo drop station or not.
	 * @param is_drop_station True if and only if this station is a drop station.
	 */
	function SetCargoDrop(is_drop_station) {
		_is_drop_station = is_drop_station;
	}

	function GetOccupancy() {
		local rad = 1;
		switch (GetSType()) {
			case AIStation.STATION_AIRPORT:
				rad = XAirport.MaxPlane(AIAirport.GetAirportType(GetLocation()));
				break;
			case AIStation.STATION_BUS_STOP:
			case AIStation.STATION_TRUCK_STOP:
				rad = GetArea().Count();
				break;
			case AIStation.STATION_DOCK:
				return 50;
			case AIStation.STATION_TRAIN:
				rad = (GetArea().Count() / 2).tointeger();
				break;
			default :
				Info("station type invalid");
				return 100;
		}
		local vhcl = CLList(AIVehicleList_Station(GetID()));
		vhcl.Valuate(XVehicle.IsRegistered);
		vhcl.KeepValue(1);
		local acc = 0;
		foreach(vhc, v in vhcl) {
			local vhcc = My._Vehicles[vhc];
			if (vhcc.GetSType() != GetSType()) continue;
			local dist = AIMap.DistanceManhattan(vhcc.GetSStation(), vhcc.GetDStation());
			local td = max(1, Assist.TileToDays(dist, vhcc.GetMaxSpeed()) - 15);
			acc	+= rad * 100 / td;
		}
		Debug.Sign(GetLocation(), "occ" + acc)
		Info("Occupancy", acc);
		return acc;
	}
};
