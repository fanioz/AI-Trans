/*  10.02.27 - roadconnector.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that connect a route by road.
 */
class RoadConnector extends Connector
{
	_Rvs_Type = null;
	constructor() {
		_V_Type = AIVehicle.VT_ROAD;
		Connector.constructor ("Road Connector", 100);
		SetKey (10);
		_Max_Distance = 100;
		_Min_Distance = 50;
		_PF = Road_PF();
		_Rvs_Type = -1;
		///remove line below to start tram first;
		//AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
	}

	function On_Start() {
		if (IsNotAllowed (this)) return;
		if (_Track == -1) {
			if (AIRoad.GetCurrentRoadType() == AIRoad.ROADTYPE_TRAM) {
				AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
			} else if (AIRoad.IsRoadTypeAvailable(AIRoad.ROADTYPE_TRAM)) {
				AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
			}
			_Track = AIRoad.GetCurrentRoadType();
		}
		Info ("using", Const.RoadTypeStr[_Track]);
		if (!AICargo.IsValidCargo (_Cargo_ID)) {
			MatchCargo(this);
			_Rvs_Type = AIRoad.GetRoadVehicleTypeForCargo(_Cargo_ID);
			return;
		}
		Info ("cargo selected:", XCargo.Label[_Cargo_ID]);
		if (!AIEngine.IsValidEngine (_Engine_A)) {
			return SelectEngine (this);
		}
		Info ("engine selected:", AIEngine.GetName (_Engine_A));
		
		if (_Route_Built) {
			Info ("route built");
			if (!Money.Get (AIEngine.GetPrice (_Engine_A))) return;
			MakeVehicle (this);
			_Route_Built = false;
			_Engine_A = -1;
			_Mgr_A = null;
			_LastSuccess = AIDate.GetCurrentDate() + 90;
		} else if (IsWaitingPath(this)) {
			
		} else if (_Route_Found) {
			Info ("route found");
			if (!Money.Get(GetTotalCost(this))) return;
			_Start_Point = _Line.GetTile();
			_End_Point = _Line.GetFirstTile();
			_Route_Built = BuildInfrastructure();
			_Route_Found = false;
			_Line = null;
			_Mgr_A = null;
			Info ("road route building:",  _Route_Built);
		} else {
			Info ("Initialize service");
			_Line = false;
			if (_Mgr_B == null) SelectDest(this);		
			if (_Mgr_A == null) {
				return SelectSource(this);
			} else {
				Info ("selected source:", _Mgr_A.GetName());
			}
			switch (InitService()) {
				case 1 : _Mgr_A = null; break;
				case 2 : _Mgr_B = null; break;
			}
		}
		UpdateDistance (this);
		return Money.Pay();
	}

	function InitService() {
		if (!_Mgr_A.AllowTryStation (_S_Type)) return 1;
		if (!_Mgr_B.AllowTryStation (_S_Type)) return 2;
		local dpoint = _Mgr_B.GetRoadPoint();
		if (dpoint.IsEmpty()) {
			Warn ("couldn't got a start point at dest");
			return 2;
		}
		local spoint = _Mgr_A.GetRoadPoint();
		if (spoint.IsEmpty()) {
			Warn ("couldn't got a start point at source");
			return 1;
		}
		_PF.InitializePath (dpoint.GetItemArray(), spoint.GetItemArray(), []);
		return 0;
	}
	
	function BuildInfrastructure() {
		local dst_new, src_new;
		local dests = CLList();
		local to_ign = CLList();
		local dtrs = _VhcManager.NeedDTRS();
		local path = AyPath.ToArray(_Line);
		
		Info ("build station in", _Mgr_B.GetName());
		_D_Station = _Mgr_B.GetExistingRoadStop (dtrs, _Cargo_ID, _S_Type, false);
		if (!AIMap.IsValidTile (_D_Station)) {
			dests.AddList(_Mgr_B.GetAreaForRoadStation(_Cargo_ID, false));
			if (dests.IsEmpty()) return false;
			_D_Station = XRoad.BuilderStation(_End_Point, dtrs, _Rvs_Type, dests);
			if (!AIMap.IsValidTile (_D_Station)) {
				Warn ("build road station failed");
				return false;
			}
			dst_new = true;
		}
		
		Info ("finding depot in", _Mgr_B.GetName());
		_D_Depot = _Mgr_B.GetRoadDepot(); 
		if (!AIRoad.IsRoadDepotTile(_D_Depot)) {
			_D_Depot = XRoad.BuildDepot(XRoad.GetBackOrFrontStation(_D_Station), _Mgr_B.GetAreaForRoadDepot());
		}
		if (!AIRoad.IsRoadDepotTile(_D_Depot)) {
			Warn ("build road depot failed");
			if (dst_new) AIRoad.RemoveRoadStation(_D_Station);
			return false;
		}
		
		dests.Clear();
		Info ("build station in", _Mgr_A.GetName());
		_S_Station = _Mgr_A.GetExistingRoadStop (dtrs, _Cargo_ID, _S_Type, true);
		if (!AIMap.IsValidTile (_S_Station)) {
			dests.AddList(_Mgr_A.GetAreaForRoadStation(_Cargo_ID, true));
			if (dests.IsEmpty()) return false;
			_S_Station = XRoad.BuilderStation(_Start_Point, dtrs, _Rvs_Type, dests);
			if (!AIMap.IsValidTile (_S_Station)) {
				Warn ("build road station failed");
				return false;
			}
			src_new = true;
		}
		
		Info ("finding depot in", _Mgr_A.GetName());
		_S_Depot = _Mgr_A.GetRoadDepot();
		if (!AIRoad.IsRoadDepotTile(_S_Depot)) {
			_S_Depot = XRoad.BuildDepot(XRoad.GetBackOrFrontStation(_S_Station), _Mgr_A.GetAreaForRoadDepot());
		}
		if (!AIRoad.IsRoadDepotTile(_S_Depot)) {
			Warn ("build road depot failed");
			if (src_new) AIRoad.RemoveRoadStation(_S_Station);
			return false;
		}
		return XRoad.BuildRoute(_Line, [_End_Point], [_Start_Point], [], 4);
	}
};
