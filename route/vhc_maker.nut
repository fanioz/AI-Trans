/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2013 fanio zilla <fanio.zilla@gmail.com>
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

	MainEngine = null; /// engines without specific cargo
	CargoEngine = null; /// engines with specific cargo
	constructor(vt) {
		::Infrastructure.constructor(-1, -1);
		SetVType(vt);
		SetName("Vehicle Maker");
		MainEngine = CLList();
		CargoEngine = CLList();
		Reset();
	}

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

	function SetMainOrder() {
		local flags = ((GetVType() == AIVehicle.VT_ROAD) && GetCargo() == XCargo.Pax_ID) ? AIOrder.OF_NONE : AIOrder.OF_FULL_LOAD_ANY;
		return Debug.ResultOf(
				   AIOrder.InsertOrder(GetVehicle(), 0, GetStationB(), AIOrder.OF_NONE) &&
				   AIOrder.InsertOrder(GetVehicle(), 0, GetStationA(), flags),
				   "set main order");
	}

	/**
	 * Set common depot order
	 */
	function SetNextOrder() {
		local flags = AIOrder.OF_SERVICE_IF_NEEDED;
		if (!AIMap.IsValidTile(GetDepotA())) flags = flags | AIOrder.OF_GOTO_NEAREST_DEPOT;
		AIOrder.InsertOrder(GetVehicle(), 2, GetDepotA(), flags);
		if (!AIMap.IsValidTile(GetDepotB())) flags = flags | AIOrder.OF_GOTO_NEAREST_DEPOT;
		AIOrder.InsertOrder(GetVehicle(), 2, GetDepotB(), flags);
		while (AIOrder.GetOrderCount(GetVehicle()) > 4) {
			AIOrder.RemoveOrder(GetVehicle(), 4);
		}
		AIOrder.SkipToOrder(GetVehicle(), 0);
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
		local built = Debug.ResultOf(XVehicle.Restart(vhc), "Starting first vehicle") ? 1 : 0;
		if (XCargo.TownStd.HasItem(GetCargo())) {
			local s_temp = GetStationA();
			SetStationA(GetStationB());
			SetStationB(s_temp);
			s_temp = GetDepotA();
			SetDepotA(GetDepotB());
			SetDepotB(s_temp);
		}
		vhc = AIVehicle.CloneVehicle(GetDepotA(), vhc, false);
		if (AIVehicle.IsValidVehicle(vhc)) {
			SetVehicle(vhc);
			SetMainOrder();
		} else {
			TryBuild();
			vhc = GetVehicle();
		}
		SetNextOrder();
		built += Debug.ResultOf(XVehicle.Restart(vhc), "Starting cloned vehicle") ? 1 : 0;
		return Debug.Echo(built, "has been initially built");
	}

	function NeedDTRS() {
		if (AIRoad.GetCurrentRoadType() == AIRoad.ROADTYPE_TRAM) return true;
		CargoEngine.Valuate(AIEngine.IsArticulated);
		return CargoEngine.CountIfKeepValue(0) < 1;
	}

	function AllowLoco(loco_id, loco_price, wgn_price, platform_len) {
		local stationlen = platform_len * 16;
		local wgn_len = AIVehicle.GetLength(GetWagonID());
		local loco_len = AIVehicle.GetLength(loco_id);
		local wgn_cnt = ((stationlen - loco_len) / wgn_len).tointeger();
		local total_price = wgn_price * wgn_cnt + loco_price;
		if (2 * total_price > Money.Balance()) return 0;
		return wgn_cnt;
	}

	function TryBuildRail() {
		local dbg = Storage();
		dbg.SetName("Vehicle.Rail.Build");
		local wgn_price, wgn_count;
		while (!IsValidVehicle(GetWagonID())) {
			if (CargoEngine.IsEmpty()) {
				dbg.Info("couldn't find available wagon");
				AIVehicle.SellVehicle(GetID());
				return false;
			}
			local wagon = CargoEngine.Pop();
			wgn_price = AIEngine.GetPrice(wagon);
			SetWagonID(BuildVehicle(GetDepotA(), wagon));
			if (AIEngine.CanRefitCargo(wagon, GetCargo())) AIVehicle.RefitVehicle(GetWagonID(), GetCargo());
			if (XCargo.OfVehicle(GetWagonID()) != GetCargo()) AIVehicle.SellVehicle(GetWagonID());
		}

		while (!IsBuilt()) {
			if (MainEngine.IsEmpty()) {
				dbg.Info("couldn't find available loco");
				AIVehicle.SellVehicle(GetWagonID());
				return false;
			}
			local eng = MainEngine.Pop();
			SetID(BuildVehicle(GetDepotA(), eng));
			if (AIEngine.CanRefitCargo(eng, GetCargo())) AIVehicle.RefitVehicle(GetID(), GetCargo());
			if (!SetOrder(a, b)) AIVehicle.SellVehicle(GetID());
		}

		wgn_count = AllowLoco(GetID(), AIEngine.GetPrice(eng), wgn_price);
		if (wgn_count == 0) {
			AIVehicle.SellVehicle(GetID());
			return true;
		}
		if (!AIVehicle.MoveWagon(GetWagonID(), 0, GetID(), 0)) {
			AIVehicle.SellVehicle(GetWagonID());
			return true;
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
				if (SetMainOrder()) break;
			}
			Warn("validation failed");
			AIVehicle.SellVehicle(GetVehicle());
		}
		return IsBuilt();
	}
}
