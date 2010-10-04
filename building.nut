/**
 *      09.02.06
 *      building.nut
 *      
 *      Copyright 2009 fanio zilla <fanio@arx-ads>
 *      
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *      
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */


/**
 * 
 * name: BuildingHandler
 * @note class of all builder
 */
class BuildingHandler {

	_lastCost = null;					/// store the last cost of command
	_costHandler = null;			/// AIAccounting instance
	_test_flag = null;					/// flag indicator test mode
	_commander = null;      /// My Bos instance
	State = null;               /// The state of this builder
	Road = null;                /// RoadBuilder Class
	Rail = null;                  /// RailBuilder class
	Factor = null;              /// Cost Factor
	
/**
 * 
 * name: BuildingHandler::constructor
 */
	constructor(commander) {
		_lastCost = 0;
		_costHandler = AIAccounting();
		_test_flag = false;
		_commander = commander;
		State = BuildingHandler.state(this);
		Road = BuildingHandler.road(this);
		Rail = BuildingHandler.rail(this);
		Factor = _commander.Factor;
	}
	
	/**
 	* 
 	* name: HeadQuarter
 	* @note Build my HQ on random suitable site if I haven't yet or 
 	* @return tile location
 	*/
	function HeadQuarter();
	
	/**
 	* 
 	* name: ClearSigns
 	* @note Clear all sign that I have been built
 	*/
	function ClearSigns(); 
	
	
}

function BuildingHandler::HeadQuarter()
{
	local hq = AICompany.GetCompanyHQ(AICompany.COMPANY_SELF);
	if (AIMap.IsValidTile(hq)) return hq;
	this._costHandler.ResetCosts();
	local loc = Tile.Waters(Tile.Flat(Tile.WholeMap()),0);
	loc.Valuate(AITile.IsCoastTile);
	loc.RemoveValue(1);
	loc.Valuate(AITile.IsBuildableRectangle,3,3);
	loc.RemoveValue(0);
	local location = loc.Begin();
	local t = AITestMode();
	local c = AIAccounting();
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	AIRoad.BuildRoad(location, Tile.SE_Of(location));
	AIController.Sleep(1);
	this._lastCost = c.GetCosts();
	c = null;
	local xt = AIExecMode();
	while (!AICompany.BuildCompanyHQ (location) && loc.HasNext()) {
		AIController.Sleep(10);
		location = loc.Next();
	}
}

function BuildingHandler::ClearSigns()
{
	AILog.Info("Clearing signs ...");
	local c = AISign.GetMaxSignID ();
  while (c > -1) {
    AISign.RemoveSign(c);
    c--;
  }
}

/**
	* Read/Write only public properties
	*
	*/
	class BuildingHandler.state {
	  _main = null;
	constructor(main)
	{
	  this._main = main;
	}
	
	function _set(idx, val)
	{
		switch (idx) {
		  case "LastCost" :
		    this._main._lastCost = val;
		    break;
			case "TestMode" :
				this._main._test_flag = val;
				break;
      default :	throw("the index '" + idx + "' does not exist");
		}
	}

	function _get(idx)
	{
		switch (idx) {
			case "LastCost" : return this._main._lastCost;
      case "TestMode" : return this._main._test_flag;
      default : throw("the index '" + idx + "' does not exist");
		}
	}
}

/**
 * 
 * name: BuildingHandler.road
 * @note class of Road builder // use fake namespace
 */
 
class BuildingHandler.road {
  _mother = null; /// the mother instance
  
  constructor(main) {
    this._mother = main;
  }
  
/**
 * 
 * name: Depot
 * @param service class
 * @return true if the depot can build or has been build
 */
  function Depot(service);
  
/**
 * 
 * name: Path
 * @param service class
 * @param number the code number wich path to find
 * @param is_finding set to false if only check a path
 * @return true if the path is found
 */
  function Path(service, number, is_finding = true);
  function Station(service);  
  function Track(service);
  function Vehicle(service);
}

function BuildingHandler::road::_depot(body, head)
{
  if (!AITile.IsBuildable(body)) AITile.DemolishTile(body);
  if (!Tile.IsMine(head) && !(AITile.IsBuildable(head) || AIRoad.IsRoadTile(head))) AITile.DemolishTile(head);
  AIRoad.BuildRoad(head, body);
  /* problem here with AITestMode() */
  if (!AIRoad.AreRoadTilesConnected(head, body)) return false;  
  if (!AIRoad.BuildRoadDepot(body, head)) return false;
  return AIRoad.IsRoadDepotTile(body);
}

function BuildingHandler::road::Depot(service)
{
  //AILog.Info("Build Depot");
  local rad = 1;
  local built_s = Tile.RoadDepot(service.Info.SourcePos);
  /* check if i've one */
  if (!built_s.IsEmpty()) {
    local dpt = built_s.Begin();
    service.Info.Depot.Body = dpt;
    service.Info.Depot.Head = AIRoad.GetRoadDepotFrontTile(dpt);
    AILog.Info("Not need as I have one");
    return true;
  }
  /* check if i've determined the position*/
  if (AIMap.IsValidTile(service.Info.Depot.Body) && AIMap.IsValidTile(service.Info.Depot.Head)) {
    if (this._depot(service.Info.Depot.Body, service.Info.Depot.Head)) return true;
  }
  /* find a good place */
	while (rad < 20) {
    local Gpos = Gen.Pos(rad, service.Info.SourcePos, service.Info.SourceIsTown);
	  local pos = null;
	  local the_cost = AIAccounting();	  
	  while (pos = resume Gpos) {
	    if (Tile.IsMine(pos.Body)) continue;
	    AIController.Sleep(1);	    
	    //AISign.BuildSign(pos.Body,"b");	    
			if (this._depot(pos.Body, pos.Head)) {
			  service.Info.Depot = pos;
			  ErrMessage("Road Depot at " + service.Info.SourceText);
			  return true;
			}
			else {
			  if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
					local addmoney = 0;
					local wait_time = AIVehicleList().Count() * 2 + 5;
					AIController.Sleep(wait_time);
					 do {
					  if (this._depot(pos.Body, pos.Head)) {
			        service.Info.Depot = pos;
			        ErrMessage("Road Depot at " + service.Info.SourceText);
              return true;
            }
					  if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
					  AIController.Sleep(wait_time);
					} while (Bank.Get(addmoney += 10000));
					//in case come here after break;
					if (Bank.Get(addmoney += 10000)) return false;
        }
        if (AIError.GetLastError() == AIError.ERR_LOCAL_AUTHORITY_REFUSES) return false;
			}
			AIController.Sleep(1);
    }
	  ErrMessage("Road Depot at " + service.Info.SourceText);
	  rad++;
	}
  return false;
 }

function BuildingHandler::road::_station(body, head, tipe)
{
  if (!AITile.IsBuildable(body)) AITile.DemolishTile(body);
  if (!Tile.IsMine(head) && !(AITile.IsBuildable(head) || AIRoad.IsRoadTile(head))) AITile.DemolishTile(head);
  AIRoad.BuildRoad(head, body);
  /* problem here with AITestMode() */
  if (!AIRoad.AreRoadTilesConnected(head, body)) return false;
  if (!AIRoad.BuildRoadStation(body, head, tipe, AIStation.STATION_JOIN_ADJACENT)) return false;
  return AIRoad.IsRoadStationTile(body);
}
 
function BuildingHandler::road::Station(service, is_source)
{
  //AILog.Info("Build Station");
  local rad = 1;
  local c_pos = PosClass();
  local built_s = (is_source) ? MyStationTile(service.Info.SourcePos) : MyStationTile(service.Info.DestinationPos)
  /* check if i've one */
  for (local pos = built_s.Begin(); built_s.HasNext(); pos = built_s.Next()) {
    local prod_accept = (is_source) ? 
      AITile.GetCargoProduction(pos, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) :
      AITile.GetCargoAcceptance(pos, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) ;
    if (prod_accept < 5) continue;
    c_pos.ID = AIStation.GetStationID(pos);
    if (!AIStation.HasRoadType(c_pos.ID, AIRoad.ROADTYPE_ROAD)) continue;
    /* check if i really need to build other one */
    local v_number = AIVehicleList_Station(c_pos.ID);
    if (v_number.Count() > 5) continue;
    c_pos.Body = AIStation.GetLocation(c_pos.ID);
    c_pos.Head = AIRoad.GetRoadStationFrontTile(c_pos.Body); 
    if (is_source) service.Info.SourceStation = c_pos;
    else service.Info.DestinationStation = c_pos;
    return true;
  }
  /* ceck if i've determined the position*/
  c_pos = (is_source) ? service.Info.SourceStation : service.Info.DestinationStation;
  if (AIMap.IsValidTile(c_pos.Body) && AIMap.IsValidTile(c_pos.Head)) {
    if (this._station(c_pos.Body, c_pos.Head, RoadStationOf(service.Info.CargoID))) return true;
  }
  /* find a good place */
  local name = (is_source) ? service.Info.SourceText : service.Info.DestinationText;
	while (rad < 20) {
	  local Gpos = Gen.Pos(rad, 
      (is_source) ? service.Info.SourcePos : service.Info.DestinationPos, 
      (is_source) ? service.Info.SourceIsTown : service.Info.DestinationIsTown );
	  local pos = null;	  
	  while (pos = resume Gpos) {
      if (Tile.IsMine(pos.Body)) continue;
      local prod_accept = (is_source) ? 
        AITile.GetCargoProduction(pos.Body, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) :
        AITile.GetCargoAcceptance(pos.Body, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) ;
      if (prod_accept < 5) continue;
			if (this._station(pos.Body, pos.Head, RoadStationOf(service.Info.CargoID))) {
        pos.ID = AIStation.GetStationID(pos.Body);
        if (is_source) service.Info.SourceStation = pos;
        else service.Info.DestinationStation = pos;
			  return true;
			}
			else {
			  if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
					local addmoney = 0;
					local pos_income = AIVehicleList().Count();
					local wait_time =  pos_income * 2 + 5;
					AIController.Sleep(wait_time);
					 do {
					  if (this._station(pos.Body, pos.Head, RoadStationOf(service.Info.CargoID))) {
              pos.ID = AIStation.GetStationID(pos.Body);
              if (is_source) service.Info.SourceStation = pos;
              else service.Info.DestinationStation = pos;
			        return true;
					  }
					  if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
					  AIController.Sleep(wait_time);
					} while (Bank.Get(addmoney += 10000) && pos_income > 1);
					//in case come here after break;
					if (Bank.Get(addmoney += 10000)) return false;
        }
			}
			AIController.Sleep(1);
    }
	  ErrMessage("Road Station at " + name);
	  rad++;
	}
  return false;
}

function BuildingHandler::road::Path(service, number, is_finding = true)
{
  local txt = (is_finding) ? "Finding" : "Checking" ;
  AILog.Info("Path " + txt);
  
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  
  //if (path != null && path != false) return true;
  local _from = [];
  local _to = [];
  local Finder = null;
  local distance = 0;
  local result = false;
  local path = false;
  
  switch (number) {
    case 1:
    _from.push((service.Info.SourceIsTown) ? service.Info.SourcePos : Tile.N_Of(service.Info.SourcePos));
    _to.push((service.Info.DestinationIsTown) ? service.Info.DestinationPos : Tile.N_Of(service.Info.DestinationPos));
    break;
    case 2:
    _from.push(service.Info.SourceStation.Head);
    _to.push(service.Info.DestinationStation.Head);
    break;
    case 3:
    _from.push(service.Info.Depot.Head);
    _to.push(service.Info.SourceStation.Head);
  }
  
  distance = AIMap.DistanceManhattan(_from[0], _to[0]) + 1;
  local prior = Binary_Heap();
  //for (local t = 0; t < 2; t++) {  
  Finder = Road();
  local tile_cost = Finder.cost.tile;
  //Finder.cost.max_cost = distance * tile_cost * 10;
  /* check if find existing road first */
  Finder.cost.no_existing_road = (is_finding) ? tile_cost * number : Finder.cost.max_cost;
  Finder.cost.tile = 0.2 * tile_cost;
  Finder.cost.turn = 3 * tile_cost;
	Finder.cost.slope = 2 * tile_cost;
  Finder.cost.bridge_per_tile = 6 * tile_cost;
	Finder.cost.tunnel_per_tile = 10 * tile_cost;
  Finder.cost.coast = 4 * tile_cost;
	Finder.cost.crossing = 12 * tile_cost;
  //Finder.cost.NonFreeTile = 5 * tile_cost; //custom cost huh?
  //Finder.cost.allow_demolition = still get conflict huh ?
	Finder.cost.demolition = 12 * tile_cost;
	Finder.cost.estimate_multiplier = 3;
  Finder.InitializePath(_from, _to, 3.5 - number, 20);
  
    local c = 1;
    while (path == false && c++ < 120) {
      AIController.Sleep(1);
      path  = Finder.FindPath(distance);
    }
    ErrMessage("Path " + txt + " End:"+ c);
    result = (path != null && path != false);
    if (result) {
      if (!is_finding) return true;
      AILog.Info("Found a path");
     //prior.Insert(path, path.GetCost());
    }
  //}
  AIController.Sleep(1);
  //result = (prior.Count() > 0);  
	//if (result) path = prior.Pop();
	switch (number) {
    case 1:	service.Info.Path1 = path; break;
    case 2:	service.Info.Path2 = path; break;
    case 3:	service.Info.Path3 = path; break;
	}
	return result;
}

function BuildingHandler::road::Track(service, number, real_job = true)
{
  local test_job = (real_job) ? AIExecMode() : AITestMode() ;
  local txt = (real_job) ? "(Real)" : "(Test)";
  local path = null;
  switch (number) {
    case 1:	path = service.Info.Path1; break;
    case 2:	path = service.Info.Path2; break;
    case 3:	path = service.Info.Path3; break;
  }
  if (path == null || path == false) return false;
  AILog.Info("Build Track Length=" + path.GetLength() + txt);
	while (path != null) {
		local parn = path.GetParent();
		if (parn != null) {
			local last_node = path.GetTile();
			if (AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) == 1 ) {
					if (!AIRoad.BuildRoad(path.GetTile(), parn.GetTile())) {
					// An error occured while building a piece of road. TODO: handle some. 
					  switch (AIError.GetLastError()) {
					    case AIError.ERR_ALREADY_BUILT:
					     // thanks
					    break;
					    case AIError.ERR_VEHICLE_IN_THE_WAY:
						  local x = 50;
						  while (x-- > 0) {
							  AIController.Sleep(x + 1);
							  AIRoad.BuildRoad(path.GetTile(), parn.GetTile())
							  ErrMessage("Retry build road:" + x);
							  if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
							  if (AIError.GetLastError() != AIError.ERR_VEHICLE_IN_THE_WAY) break;
						  }
						  break;
					    case AIError.ERR_NOT_ENOUGH_CASH:
						  local addmoney = 0;
						  local pos_income = AIVehicleList().Count();
						  local wait_time = pos_income * 2 + 5;
						  while (Bank.Get(addmoney += 1000) && pos_income > 1) {
							  AIController.Sleep(wait_time);
							  AIRoad.BuildRoad(path.GetTile(), parn.GetTile());
							  ErrMessage("Retry build road");
							  if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
							  if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
						  }
						  break;
					    default:
						  ErrMessage("Unhandled error Build Road");
						  break;
					}
				}
			}
			else {
				if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					/* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
					if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
					if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == parn.GetTile()) {
						AILog.Info("Build a road tunnel");
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
							/* An error occured while building a tunnel. TODO: handle it. */
						}
					}
					else {
						local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) + 1);
						bridge_list.Valuate(AIBridge.GetMaxSpeed);
						bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
						AILog.Info("build a pieces of a bridge");
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), parn.GetTile())) {
							/* An error occured while building a bridge. TODO: handle it. */
							switch (AIError.GetLastError()) {
							case AIError.ERR_NOT_ENOUGH_CASH:
							  while (bridge_list.HasNext()) {
							    local bridge = bridge_list.Next();
							    if (!Bank.Get(AIBridge.GetPrice(bridge, AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) + 1))) continue;
							    if (AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge, path.GetTile(), parn.GetTile())) break;
							  }
							  break;
							default:
								ErrMessage("Unhandled error ");
								break;
							}
						}
					}
				}
			}
		}
		path = parn;
	}
	/* check existing road first */
	local r = (real_job) ? this.Path(service, number, false) : (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH);
	AILog.Info("Tracking:" + r +" " + txt);
	return r;
}
function BuildingHandler::road::Vehicle(service)
{
  AILog.Info("Build Vehicle");
  local available = -1;
  if (AIVehicle.IsValidVehicle(service.Info.MainVhcID)) {
    StartClonedVehicle(service.Info.MainVhcID, service.Info.Depot.Body, 2);
    ErrMessage("Made 2 Cloning");
    return 1;
  }
  else {
    local _engines = SpeedyRoadEngine();
    local myVhc = null;
    for(local ID_eng = _engines.Begin(); _engines.HasNext() ; ID_eng = _engines.Next()) {
      if (AIEngine.GetCargoType(ID_eng) == service.Info.CargoID) {
        available = 0;
        myVhc = AIVehicle.BuildVehicle(service.Info.Depot.Body, ID_eng);
        ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
      }
      else {
        if (AIEngine.CanRefitCargo(ID_eng, service.Info.CargoID)) {
          available = 0;
          myVhc = AIVehicle.BuildVehicle(service.Info.Depot.Body, ID_eng);
          AIVehicle.RefitVehicle(myVhc, service.Info.CargoID);
          ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
        }
        else continue;
      }
      if (!AIOrder.AppendOrder(myVhc, service.Info.SourceStation.Body, AIOrder.AIOF_FULL_LOAD)) {
        ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
        AIVehicle.SellVehicle(myVhc);
        continue;
      }
      if (!AIOrder.AppendOrder(myVhc, service.Info.DestinationStation.Body, AIOrder.AIOF_NONE)) {
        ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
        AIVehicle.SellVehicle(myVhc);
        continue;
      }
      AIOrder.AppendOrder(myVhc, service.Info.Depot.Body, AIOrder.AIOF_NONE);
      if (AIVehicle.IsValidVehicle(myVhc)) { 
        service.Info.MainVhcID = myVhc;
        return 1;
      }
    }
    if (available == -1) AILog.Info("No Vehicle available");
    return available;
  }
}

/**
 * 
 * name: BuildingHandler.rail
 * @note class of Rail builder // use fake namespace
 */
 
class BuildingHandler.rail {
  _mother = null;
  constructor(main) {
  this._mother = main;
  }
  
  function Depot(service);
  function Station(service);
  function Path(service);
  function Track(service);
  function Vehicle(service);
}

function BuildingHandler::rail::Depot(service)
{
  local rad = 1;
  local done = false;
  local built_s = Tile.RailDepot(service.Info.SourcePos);
  if (!built_s.IsEmpty()) {
    service.Info.Depot.Body = built_s.Begin();
    service.Info.Depot.Head = AIRail.GetRailDepotFrontTile(service.Info.Depot.Body);
    return true;
  }
  local body = GetRailStationBackTile(service.Info.SourceStation.Body, 3);
  local head = GetRailStationBackTile(service.Info.SourceStation.Body, 2);
  done = AIRail.BuildRailDepot(body, head);
  if (done) {
			  service.Info.Depot.Body = body;
			  service.Info.Depot.Head = head;			  
			  return true;
  }
	while (!done && rad < 20) {
    local Gpos = GeneratorPos(rad, service.Info.SourcePos, service.Info.SourceIsTown);
	  local pos = null;	  
	  while (pos = resume Gpos) {
	    if (!Tile.IsMine(pos.Head)) AITile.DemolishTile(pos.Head);
	    done = AIRail.BuildRailDepot(pos.Head, pos.Body);
	    //AISign.BuildSign(pos.Body,"b");
	    ErrMessage("Rail Depot at " + service.Info.SourceText);
			if (done) {
			  service.Info.Depot.Body = pos.Head;
			  service.Info.Depot.Head = pos.Body;
			  return true;
			}
			AIController.Sleep(1);
    }
	  ErrMessage("Rail Depot at " + service.Info.SourceText);
	  rad++;
	}
  return false;
 }
function BuildingHandler::rail::Station(service, is_source)
{
  AILog.Info("Build Station");
  local dloc = service.Info.DestinationPos;
	local sloc = service.Info.SourcePos;
	local dt = AIIndustry.GetIndustryType(service.Info.DestinationID);
	local st = AIIndustry.GetIndustryType(service.Info.SourceID);
	local a = (is_source) ? IndustrySourceTile(service.Info.SourceID, service.Info.CargoID) : IndustryDestinationTile(service.Info.DestinationID, service.Info.CargoID);
	a.Valuate(AITile.IsBuildableRectangle,1,6);
	a.KeepValue(1);
	local c_pos = PosClass();
	for (local co = a.Begin(); a.HasNext(); co = a.Next()) {
		c_pos.Head = RailStationDirection(co, (is_source) ? sloc : dloc) ;
		local built = AIRail.BuildNewGRFRailStation (co, c_pos.Head, 1, 3, AIStation.STATION_JOIN_ADJACENT, service.Info.CargoID, st, dt, AIMap.DistanceManhattan(sloc,dloc) , is_source) &&
		AIRail.BuildRailTrack((is_source) ? GetRailStationFrontTile(co) : GetRailStationBackTile(co), c_pos.Head);
		if (!built) built = AIRail.BuildRailStation (co, c_pos.Head, 1, 3, AIStation.STATION_JOIN_ADJACENT) && 
		AIRail.BuildRailTrack((is_source) ? GetRailStationFrontTile(co) : GetRailStationBackTile(co), c_pos.Head);
		if (built) { 
		  c_pos.ID = AIStation.GetStationID(co);
		  c_pos.Body = co;
		  if (is_source) service.Info.SourceStation = c_pos;
		  else service.Info.DestinationStation = c_pos;
		  return true;
		  }
		ErrMessage("Build Station");
		AIController.Sleep(5);
	}
	AILog.Info("Finished");
  return false;
}
function BuildingHandler::rail::Path(service, is_back)
{
  AILog.Info("Build Path");
  local pathfinder = RailPathFinder();
	pathfinder.cost.tile = 100;
	local ignored = AITileList();
	local tile_a = service.Info.SourcePos;
	local tile_b = service.Info.DestinationPos;
	//AILog.Info("A=" + tile_a + " B=" + tile_b);
	//ignored.AddRectangle(tile_b + AIMap.GetTileIndex(-2, 1), tile_b + AIMap.GetTileIndex(-1, 2));
	//ignored.AddRectangle(tile_b + AIMap.GetTileIndex(3, 1), tile_b + AIMap.GetTileIndex(4, 2));
	local nodes =[], source = [], dest = [];
	nodes.push(GetRailStationFrontTile(service.Info.SourceStation.Body));
	nodes.push(GetRailStationFrontTile(service.Info.SourceStation.Body, 2));
	source.push(nodes);
	ignored.AddTile(GetRailStationFrontTile(service.Info.SourceStation.Body));
	ignored.AddTile(GetRailStationBackTile(service.Info.DestinationStation.Body));
	nodes.clear();
	nodes.push(GetRailStationBackTile(service.Info.DestinationStation.Body, 2));
	nodes.push(GetRailStationBackTile(service.Info.DestinationStation.Body));
	dest.push(nodes);
	pathfinder.cost.max_cost = AIMap.DistanceManhattan(tile_a, tile_b) * 1 * pathfinder.cost.tile;
	pathfinder.InitializePath(source, dest, ignored);
	////pathfinder.InitializePath([[GetRailStationBackTile(tile_b), tile_b]], [[tile_a, GetRailStationFrontTile(tile_a)]], ignored);
	ErrMessage("Path finding init:");
	local x = 1;
	local path = false;
	do {
		path = pathfinder.FindPath(1);
		ErrMessage("Path finding:" + x++);
		if (x > 1000) break;
	} while (path == null || path == false);
	service.Info.Path = path;
  return (path == null || path == false);
}
function BuildingHandler::rail::Track(service, is_back)
{
  AILog.Info("Build Track");
  local path = service.Info.Path;
  local prev = null;
  local prevprev = null;
  if (path == false) return false;
  while (path != null) {
    if (prevprev != null) {
      if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
        if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
          AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev);
        } 
        else {
          local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
          bridge_list.Valuate(AIBridge.GetMaxSpeed);
          bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
          AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile());
        }
        prevprev = prev;
        prev = path.GetTile();
        path = path.GetParent();
      } 
      else {
        AIRail.BuildRail(prevprev, prev, path.GetTile());
      }
    }
    if (path != null) {
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    }
  }
  return false;
}
function BuildingHandler::rail::Vehicle(service)
{
  AILog.Info("Build Vehicle");
  return false;
}
