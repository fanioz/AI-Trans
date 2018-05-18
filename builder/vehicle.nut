/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * VehicleMaker as it name,
 * would be a common vehicle builder
 */
class VehicleMaker extends Infrastructure
{
	_depot_a = null;
	_depot_b = null;
	_station_a = null;
	_station_b = null;
	_m_id = null;
	_wgn_id = null;
	_platformLength = null;
	_waypoints = null;

	MainEngine = null; /// engines without specific cargo
	CargoEngine = null; /// engines with specific cargo
	constructor(vt) {
		::Infrastructure.constructor(-1, -1);
		SetVType(vt);
		SetName("Vehicle Maker");
		MainEngine = CLList();
		CargoEngine = CLList();
		Reset();
		this._platformLength = 4;
	}

	function GetPlatformLength() { return this._platformLength; }
	function SetPlatformLength(a) { this._platformLength = a; }
	function GetWaypoints() { return this._waypoints; }
	function SetWaypoints(wp) { this._waypoints = wp; }
	function GetDepotA() { return _depot_a; }
	function SetDepotA(a) { _depot_a = a; }
	function GetDepotB() { return _depot_b; }
	function SetDepotB(b) { _depot_b = b; }
	function GetWagonID() { return _wgn_id; }
	function SetWagonID(id) {_wgn_id = id; }
	function GetStationA() { return _station_a; }
	function SetStationA(a) { _station_a = a; }
	function GetStationB() { return _station_b; }
	function SetStationB(b) { _station_b = b; }
	function GetVehicle() { return _m_id; }

	function SetVehicle(id) {
		_m_id = id;
		SetName(AIVehicle.GetName(id));
	}

	function SetCargo(c) {
		::Infrastructure.SetCargo(c);
		CargoEngine.Valuate(AIEngine.CanRefitCargo, c);
		CargoEngine.KeepValue(1);
		if (GetVType() == AIVehicle.VT_RAIL) {
			MainEngine.Valuate(AIEngine.CanPullCargo, c);
			MainEngine.KeepValue(1);
		}
	}

	function GetFirst() {
		if (CargoEngine.Count()) return CargoEngine.Begin();
		return -1;
	}

	function GetFirstLoco() {
		if (MainEngine.Count()) return MainEngine.Begin();
		return -1;
	}

	function IsBuilt() {
		return AIVehicle.IsValidVehicle(GetVehicle());
	}

	function MaxCapacity() {
		return AIVehicle.GetCapacity(GetVehicle(), GetCargo());
	}

	function SortEngine() {
		CargoEngine.Valuate(XEngine.Sort);
		if (GetVType() == AIVehicle.VT_RAIL) {
			MainEngine.Valuate(XEngine.SortLoco);
			return;
		};
	}

	function SetVehicleOrder() {
		AIController.Sleep(1);
		//Remove all order if any
		while (AIOrder.GetOrderCount(GetVehicle()) > 0) AIOrder.RemoveOrder(GetVehicle(), 0);
		local flags = ((GetVType() == AIVehicle.VT_ROAD) && GetCargo() == XCargo.Pax_ID) ? AIOrder.OF_NONE : AIOrder.OF_FULL_LOAD_ANY;
		local via = clone this._waypoints;
		local ret =	Debug.ResultOf(AIOrder.AppendOrder(GetVehicle(), GetStationA(), flags), "set src order");
		foreach(tile in via)
			Debug.ResultOf(AIOrder.AppendOrder(GetVehicle(), tile, AIOrder.OF_NONE),"set buoys order");
		
		ret = ret && Debug.ResultOf(AIOrder.AppendOrder(GetVehicle(), GetStationB(), AIOrder.OF_NONE), "set dst order");
		flags = (GetVType() == AIVehicle.VT_RAIL) ? AIOrder.OF_NONE : AIOrder.OF_SERVICE_IF_NEEDED;
		local nflags = flags;
		if (!AIMap.IsValidTile(GetDepotB())) nflags = flags | AIOrder.OF_GOTO_NEAREST_DEPOT;
		Debug.ResultOf(AIOrder.AppendOrder(GetVehicle(), GetDepotB(), nflags),"set depot order");
		via.reverse();
		foreach(tile in via)
			Debug.ResultOf(AIOrder.AppendOrder(GetVehicle(), tile, AIOrder.OF_NONE),"set buoys order");
		
		if (!AIMap.IsValidTile(GetDepotA())) nflags = flags | AIOrder.OF_GOTO_NEAREST_DEPOT;
		Debug.ResultOf(AIOrder.AppendOrder(GetVehicle(), GetDepotA(), nflags),"set depot order");
		return ret;
	}

	function Reset() {
		CargoEngine.Clear();
		CargoEngine.AddList(AIEngineList(GetVType()));
		CargoEngine.Valuate(AIEngine.IsBuildable);
		CargoEngine.KeepValue(1);
		CargoEngine.Valuate(AIEngine.GetPrice);
		CargoEngine.RemoveAboveValue(Money .Maximum() / 2);
		switch (GetVType()) {
			case AIVehicle.VT_RAIL:
				MainEngine.Clear();
				MainEngine.AddList(CargoEngine);
				CargoEngine.Valuate(AIEngine.GetPower);
				CargoEngine.RemoveAboveValue(5);
				MainEngine.Valuate(AIEngine.GetCapacity);
				MainEngine.RemoveAboveValue(20);
				MainEngine.Valuate(AIEngine.GetReliability);
				MainEngine.RemoveBelowValue(50);
				break;
			case AIVehicle.VT_AIR:
			case AIVehicle.VT_WATER:
			case AIVehicle.VT_ROAD:
				CargoEngine.Valuate(AIEngine.GetCapacity);
				CargoEngine.RemoveBelowValue(20);
				CargoEngine.Valuate(AIEngine.GetReliability);
				CargoEngine.RemoveBelowValue(50);
				break;
			default :
				throw "invalid vt";
		}
		_depot_a = -1;
		_depot_b = -1;
		_station_a = -1;
		_station_b = -1;
		_wgn_id = -1;
		_m_id = -1;
		this._waypoints = [];
	}

	function HaveEngineFor(et) {
		switch (GetVType()) {
			case AIVehicle.VT_RAIL:
				AIRail.SetCurrentRailType(et);
				CargoEngine.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
				CargoEngine.KeepValue(1);
				MainEngine.Valuate(AIEngine.HasPowerOnRail, AIRail.GetCurrentRailType());
				MainEngine.KeepValue(1);
				return CargoEngine.Count() && MainEngine.Count();
			case AIVehicle.VT_ROAD:
				CargoEngine.Valuate(AIEngine.GetRoadType);
				break;
			case AIVehicle.VT_WATER:
				CargoEngine.Valuate(AIEngine.IsValidEngine);
				break;
			case AIVehicle.VT_AIR:
				CargoEngine.Valuate(AIEngine.GetPlaneType);
				break;
			default :
				CargoEngine.Clear();
		}
		CargoEngine.KeepValue(et);
		return CargoEngine.Count();
	}

	/**
	* Start and cloned vehicle
	* @param number The number of cargo production
	*/
	function StartCloned() {
		Info("Try to Start and Clone Vehicle");
		local vhc = GetVehicle();
		local built = Debug.ResultOf(XVehicle.Run(vhc), "Starting first vehicle") ? 1 : 0;
		if (XCargo.TownStd.HasItem(GetCargo())) {
			local s_temp = GetStationA();
			SetStationA(GetStationB());
			SetStationB(s_temp);
			s_temp = GetDepotA();
			SetDepotA(GetDepotB());
			SetDepotB(s_temp);
			this._waypoints.reverse();
		}
		vhc = AIVehicle.CloneVehicle(GetDepotA(), vhc, false);
		if (AIVehicle.IsValidVehicle(vhc)) {
			SetVehicle(vhc);
			SetVehicleOrder();
		} else {
			TryBuild();
			vhc = GetVehicle();
		}
		built += Debug.ResultOf(XVehicle.Run(vhc), "Starting cloned vehicle") ? 1 : 0;
		return Debug.Echo(built, "has been initially built");
	}

	function NeedDTRS() {
		if (AIRoad.GetCurrentRoadType() == AIRoad.ROADTYPE_TRAM) return true;
		CargoEngine.Valuate(AIEngine.IsArticulated);
		return CargoEngine.CountIfKeepValue(0) < 1;
	}

	function TryBuildRail() {
		local wgn_price, wgn_count, wagon, loco_price;
		while (!AIVehicle.IsValidVehicle(GetWagonID())) {
			if (CargoEngine.IsEmpty()) {
				Info("couldn't find available wagon");
				AIVehicle.SellVehicle(GetVehicle());
				return false;
			}
			wagon = CargoEngine.Pop();
			local cost = AIAccounting();
			cost.ResetCosts();
			SetWagonID(AIVehicle.BuildVehicle(GetDepotA(), wagon));
			if (AIEngine.CanRefitCargo(wagon, GetCargo())) AIVehicle.RefitVehicle(GetWagonID(), GetCargo());
			wgn_price = cost.GetCosts();
			if (XCargo.OfVehicle(GetWagonID()) != GetCargo()) AIVehicle.SellVehicle(GetWagonID());
		}
		
		while (!IsBuilt()) {
			if (MainEngine.IsEmpty()) {
				Info("couldn't find available loco");
				AIVehicle.SellVehicle(GetWagonID());
				return false;
			}
			local eng = MainEngine.Pop();
			SetVehicle(Debug.ResultOf(AIVehicle.BuildVehicle(GetDepotA(), eng), "build train got ID:"));
			local vhcLength = AIVehicle.GetLength(GetVehicle());
			while (vhcLength < 16 * this.GetPlatformLength()) {
				Money.Get(wgn_price);
				SetWagonID(AIVehicle.BuildVehicle(GetDepotA(), wagon));
				if (AIVehicle.GetLength(GetVehicle()) == vhcLength) {
					//wagon not attached
					if (AIVehicle.IsValidVehicle(GetWagonID())) {
						AIVehicle.MoveWagon(GetWagonID(), 0, GetVehicle(), 0);
					} else {
						XVehicle.Sell(GetVehicle());
						return true;
					}
				}
				vhcLength = AIVehicle.GetLength(GetVehicle());
			}
			if (AIEngine.CanRefitCargo(eng, GetCargo())) AIVehicle.RefitVehicle(GetVehicle(), GetCargo());
			if (!this.SetVehicleOrder()) XVehicle.Sell(GetVehicle());
		}
		
		return false;
	}

	function TryBuild() {
		_m_id = -1;
		while (Debug.Echo(CargoEngine.Count(), "engine(s) found")) {
			local eng = CargoEngine.Pop();
			if (!AIEngine.IsValidEngine(eng)) {
				Warn("couldn't build an invalid engine");
				continue;
			}
			if (!Money.Get(AIEngine.GetPrice(eng))) {
				Warn("couldn't build if have no money");
				continue;
			}
			SetVehicle(Debug.ResultOf(AIVehicle.BuildVehicle(GetDepotA(), eng), "build vehicle got ID:"));
			Debug.ResultOf(AIVehicle.RefitVehicle(GetVehicle(), GetCargo()), "refit to", XCargo.Label[GetCargo()]);
			if (XCargo.OfVehicle(GetVehicle()) == GetCargo()) {
				if (SetVehicleOrder()) break;
			}
			Warn("validation failed");
			AIVehicle.SellVehicle(GetVehicle());
		}
		return IsBuilt();
	}
}
