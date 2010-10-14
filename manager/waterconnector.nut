/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that connect a route by ship.
 */
class WaterConnector extends Connector
{
	constructor() {
		_V_Type = AIVehicle.VT_WATER;
		Connector.constructor("Water Connector", 10);
		_Max_Distance = 100;
		_Min_Distance = 30;
		_PF = Water_PF();
	}

	function On_Start() {
		if (IsNotAllowed(this)) return;
		if (_Track == -1) {
			_Track = 1;
		}
		if (!AICargo.IsValidCargo(_Cargo_ID)) {
			return MatchCargo(this);
		}
		Info("cargo selected:", XCargo.Label[_Cargo_ID]);
		if (!AIEngine.IsValidEngine(_Engine_A)) {
			return SelectEngine(this);
		}
		Info("engine selected:", AIEngine.GetName(_Engine_A));

		if (_Route_Built) {
			Info("route built");
			if (!Money.Get(AIEngine.GetPrice(_Engine_A))) return;
			MakeVehicle(this);
			_Route_Built = false;
			_Engine_A = -1;
			_Mgr_A = null;
			_LastSuccess = AIDate.GetCurrentDate() + 90;
		} else if (IsWaitingPath(this)) {

		} else if (_Route_Found) {
			Info("route found");
			if (!Money.Get(GetTotalCost(this))) return;
			_Start_Point = _Line.GetFirstTile();
			_End_Point = _Line.GetTile();
			_Route_Found = false;
			_Route_Built = BuildInfrastructure();
			_Line = null;
			Info("water route building:",  _Route_Built);
		} else {
			Info("Initialize service");
			_Line = false;
			if (_Mgr_B == null) SelectDest(this);
			if (_Mgr_A == null) {
				return SelectSource(this);
			} else {
				Info("selected source:", _Mgr_A.GetName());
			}
			switch (InitService()) {
				case 1 : _Mgr_A = null; break;
				case 2 : _Mgr_B = null; break;
			}
		}
		return Money.Pay();
	}

	function InitService() {
		if (!_Mgr_A.AllowTryStation(_S_Type)) return 1;
		if (!_Mgr_B.AllowTryStation(_S_Type)) return 2;
		local dpoint = _Mgr_B.GetWaterPoint();
		if (dpoint.IsEmpty()) {
			Warn("couldn't got a start point at dest");
			return 2;
		}
		local spoint = _Mgr_A.GetWaterPoint();
		if (spoint.IsEmpty()) {
			Warn("couldn't got a start point at source");
			return 1;
		}
		_PF.InitializePath(spoint.GetItemArray(), dpoint.GetItemArray(), []);
		return 0;
	}

	function BuildInfrastructure() {
		local dests = CLList();

		Info("finding depot in", _Mgr_B.GetName());
		_D_Depot = _Mgr_B.GetWaterDepot();
		if (!AIMarine.IsWaterDepotTile(_D_Depot)) {
			_D_Depot = XMarine.BuildDepot(_End_Point, _Mgr_B.GetAreaForWaterDepot());
		}
		if (!AIMarine.IsWaterDepotTile(_D_Depot)) {
			return false;
		}

		Info("finding depot in", _Mgr_A.GetName());
		_S_Depot = _Mgr_A.GetWaterDepot();
		if (!AIMarine.IsWaterDepotTile(_S_Depot)) {
			_S_Depot = XMarine.BuildDepot(_Start_Point, _Mgr_A.GetAreaForWaterDepot());
		}

		if (!AIMarine.IsWaterDepotTile(_S_Depot)) {
			return false;
		}

		Info("build station in", _Mgr_B.GetName());
		_D_Station = _Mgr_B.GetExistingWaterStop(_Cargo_ID, false);
		if (!AIMap.IsValidTile(_D_Station)) {
			dests.AddList(_Mgr_B.GetAreaForDock(_Cargo_ID, false));
			if (dests.IsEmpty()) return false;
			_D_Station = XMarine.BuilderStation(_End_Point, dests);
			if (!AIMap.IsValidTile(_D_Station)) return false;
		}

		dests.Clear();
		Info("build station in", _Mgr_A.GetName());
		_S_Station = _Mgr_A.GetExistingWaterStop(_Cargo_ID, true);
		if (!AIMap.IsValidTile(_S_Station)) {
			dests.AddList(_Mgr_A.GetAreaForDock(_Cargo_ID, true));
			if (dests.IsEmpty()) return false;
			_S_Station = XMarine.BuilderStation(_Start_Point, dests);
			if (!AIMap.IsValidTile(_S_Station)) return false;
		}
		return true;
	}
};
