/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that connect a route by aircraft.
 */
class AirConnector extends Connector {
	_Airport = null;
	_Blocked_Airport = CLList();

	/**
	 * Create a aircraft manager.
	 */
	constructor() {
		_V_Type = AIVehicle.VT_AIR;
		Connector.constructor("Air Connector", 10);
		_Max_Distance = 300;
		_Min_Distance = 150;
		_Airport = -1;
	}

	function On_Start() {
		if (Service.IsNotAllowed(_V_Type)) return;
		if (Setting.Get(SetString.infrastructure_maintenance)) {
			Info("Not connecting air route with infrastructure maintenance setting activated");
			return;
		}
		// _Track a.k.a Plane type
		if (_Track == -1) _Airport = -1;
		if (!AIAirport.IsValidAirportType(_Airport)) {
			MatchAirport();
			return;
		}
		Info("airport selected:", CLString.AirportType(_Airport));
		Info("plane type selected:", CLString.PlaneType(_Track));
		if (!AICargo.IsValidCargo(_Cargo_ID)) {
			_Cargo_ID = Setting.AllowPax ? XCargo.Pax_ID : XCargo.Mail_ID;
		}
		Info("cargo selected:", XCargo.Label[_Cargo_ID]);
		if (!AIEngine.IsValidEngine(_Engine_A)) {
			return SelectEngine(this);
		}
		Info("engine selected:", AIEngine.GetName(_Engine_A));
		if (_Route_Found) {
			Info("route found");
			if (!Money.Get(AIEngine.GetPrice(_Engine_A))) return;
			_S_Depot = XAirport.GetHangar(_S_Station);
			_D_Depot = XAirport.GetHangar(_D_Station);
			MakeVehicle(this);
			_Route_Found = false;
			_Engine_A = -1;
			_S_Station = -1;
			_LastSuccess = AIDate.GetCurrentDate() + 30;
		} else {
			if (Money.Get(AIAirport.GetPrice(_Airport))) {
				FindNewRoute();
			}
		}
		UpdateDistance(this);
		return Money.Pay();
	}

	function MatchAirport() {
		foreach(at in Const.AirportType) {
			if (!AIAirport.IsValidAirportType(at)) continue;
			if (_Blocked_Airport.HasItem(at)) continue;
			_Blocked_Airport.AddItem(at, 0);
			foreach(pt in Const.PlaneType) {
				if (_Blocked_Track.HasItem(pt)) continue;
				if (!XAirport.AllowPlaneToLand(pt, at)) continue;
				_Track = pt;
				_Airport = at;
				return;
			}
			_Blocked_Track.Clear();
		}
		_Blocked_Airport.Clear();
	}

	/**
	 * Build a new air route.
	 */
	function FindNewRoute() {
		local eng_cost = AIEngine.GetPrice(_Engine_A);
		local town_list = CLList(AITownList());
		town_list.RemoveList(_SkipList);
		town_list.Valuate(AITown.GetPopulation);
		town_list.KeepAboveValue(Setting.Min_Town_Population);
		foreach(town_from, d in town_list) {
			_SkipList.AddItem(town_from, 0);
			if (Service.IsServed(town_from, _Cargo_ID)) continue;
			local manager = XTown.GetManager(town_from);
			if (!AIMap.IsValidTile(_S_Station)) {
				_S_Station = manager.GetExistingAirport(_Track, _Cargo_ID);
				_Source_ID = town_from;
			}
			if (!AIMap.IsValidTile(_S_Station)) {
				if (JustMake(this)) continue;
				if (!manager.AllowTryAirport(_Airport)) return;
				_S_Station = manager.TryBuildAirport(_Airport, _Cargo_ID, eng_cost);
				if (!AIMap.IsValidTile(_S_Station)) return;
				_Source_ID = town_from;
				Info("we've just built an airport at", manager.GetName());
			}
			local town_list2 = CLList(town_list);
			town_list2.Valuate(AITown.GetDistanceManhattanToTile, AITown.GetLocation(_Source_ID));
			town_list2.RemoveBelowValue(_Min_Distance);
			local maxEngineDistance = AIEngine.GetMaximumOrderDistance(_Engine_A);
			foreach(town_to, d in town_list2) {
				local orderDistance = AIOrder.GetOrderDistance(AIVehicle.VT_AIR, _S_Station, AITown.GetLocation(town_to));
				//Info("orderDistance:", orderDistance, ":maxEngineDistance", maxEngineDistance);
				//thanks to Xarrick for fixing this here : https://www.tt-forums.net/viewtopic.php?p=1258586#p1258586
				if (maxEngineDistance != 0 && orderDistance > maxEngineDistance) continue;
				if (Assist.IncomeTown(town_to, AITown.GetLocation(_Source_ID), _Cargo_ID, _Engine_A) < 1) continue;
				local manager2 = XTown.GetManager(town_to);
				_D_Station = manager2.GetExistingAirport(_Track, _Cargo_ID);
				if (AIMap.IsValidTile(_D_Station)) {
					Info("there is an airport in the", manager2.GetName(), "that needs extra planes");
					_Route_Found = true;
					return;
				}
				if (JustMake(this)) continue;
				if (!manager2.AllowTryAirport(_Airport)) continue;
				/* Build the new airport. */
				_D_Station = manager2.TryBuildAirport(_Airport, _Cargo_ID, eng_cost);
				if (!AIMap.IsValidTile(_D_Station)) continue;
				Info("we've just built an airport at", manager2.GetName());
				_Route_Found = true;
				return;
			}
			_S_Station = -1;
		}
		Info("can't find any usable airport");
		_SkipList.Clear();
		_Track = -1;
	}
}