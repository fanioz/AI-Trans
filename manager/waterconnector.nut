/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that connect a route by ship.
 */
class WaterConnector extends Connector
{
	_Buoys = null;
	constructor() {
		_V_Type = AIVehicle.VT_WATER;
		Connector.constructor("Water Connector", 10);
		_Max_Distance = 100;
		_Min_Distance = 30;
		_PF = Water_PF();
		this._Buoys = [];
	}

	function On_Start() {
		if (Service.IsNotAllowed(_V_Type)) return;
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
			this._VhcManager.SetWaypoints(this._Buoys);
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
			if (_Mgr_B == null) return SelectDest(this);
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
		
		local dpoint = CLList();
		this._D_Station = this._Mgr_B.GetExistingWaterStop(this._Cargo_ID, false);
		if (AIMap.IsValidTile(this._D_Station)) {
			dpoint.AddItem(this._D_Station, 0);
		} else {
			local dests = this._Mgr_B.GetAreaForDock(this._Cargo_ID, false);
			if (dests.IsEmpty()) return 2;
			local mode = AITestMode();
			foreach(body, v in dests) {
				local head = XMarine.GetWaterSide(body);
				if (AIMarine.AreWaterTilesConnected(head, XTile.NextTile(body, head))) {
					if (AIMarine.BuildDock(body, AIStation.STATION_NEW)) {
						dpoint.AddItem(body, 0);
						Debug.Sign(body,"D");
					}
				}
			}
		}
		
		if (dpoint.IsEmpty()) {
			Warn("couldn't got a start point at dest");
			return 2;
		}
		
		local spoint = CLList();
		this._S_Station = this._Mgr_A.GetExistingWaterStop(this._Cargo_ID, true);
		if (AIMap.IsValidTile(this._S_Station)) {
			spoint.AddItem(this._S_Station, 0);
		} else {
			local dests = this._Mgr_A.GetAreaForDock(this._Cargo_ID, true);
			if (dests.IsEmpty()) return 1;
			local mode = AITestMode();
			foreach(body, v in dests) {
				local head = XMarine.GetWaterSide(body);
				if (AIMarine.AreWaterTilesConnected(head, XTile.NextTile(body, head))) {
					if (AIMarine.BuildDock(body, AIStation.STATION_NEW)) {
						spoint.AddItem(body, 0);
						Debug.Sign(body,"D");
					}
				}
			}
		}
		
		if (spoint.IsEmpty()) {
			Warn("couldn't got a start point at source");
			return 1;
		}
		_PF.InitializePath(spoint.ItemsToArray(), dpoint.ItemsToArray(), []);
		return 0;
	}

	function BuildInfrastructure() {
		local dests = CLList();

		if (!AIMap.IsValidTile(this._D_Station)) {
			AIMarine.BuildDock(this._End_Point, XStation.FindIDNear(this._End_Point, 15));
		 	if (AIMarine.IsDockTile(this._End_Point)) this._D_Station = this._End_Point;
		}
		if (!AIMap.IsValidTile(this._D_Station)) {
			Info("build station in", this._Mgr_B.GetName(), "failed");
			return false;
		}
		
		if (!AIMap.IsValidTile(this._S_Station)) {
			AIMarine.BuildDock(this._Start_Point, XStation.FindIDNear(this._Start_Point, 15));
		 	if (AIMarine.IsDockTile(this._Start_Point)) this._S_Station = this._Start_Point;
		}
		if (!AIMap.IsValidTile(this._S_Station)) {
			Info("build station in", this._Mgr_A.GetName(), "failed");
			return false;
		}
		
		this._Buoys = XMarine.BuildPath(this._Line);
		this._Buoys.reverse();
		local arr = Service.PathToArray(this._Line);
		
		Info("finding depot in", _Mgr_B.GetName());
		this._D_Depot = Assist.FindDepot(this._D_Station, 15, this._V_Type, 1);
		if (!AIMarine.IsWaterDepotTile(_D_Depot)) {
			Info("not found");
			this._D_Depot = XMarine.BuildDepotOnLine(arr)
		}

		arr.reverse();
		
		Info("finding depot in", _Mgr_A.GetName());
		this._S_Depot = Assist.FindDepot(this._S_Station, 15, this._V_Type, 1);
		if (!AIMarine.IsWaterDepotTile(_S_Depot)) {
			Info("not found");
			this._S_Depot = XMarine.BuildDepotOnLine(arr);
		}
				
		if (!AIMarine.IsWaterDepotTile(_S_Depot)) {
			if (AIMarine.IsWaterDepotTile(this._D_Depot)) {
				this._S_Depot = this._D_Depot;
			} else {
				return false;
			}
		}
		return true;
	}
};
