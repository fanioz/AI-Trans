/**
 *      09.02.06
 *      building.nut
 *
 *      Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
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
	AIController.Sleep(1);
	while (!AICompany.BuildCompanyHQ (location) && loc.HasNext()) {
		AIController.Sleep(10);
		location = loc.Next();
	}
	this._lastCost = this._costHandler.GetCosts();
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
  AISign.BuildSign(body,"b");
  if (Tile.IsMine(body) || Tile.IsMine(head)) return false;
  if (!(AITile.IsBuildable(body) || AITile.DemolishTile(body))) return false;
  //if (! && !(AITile.IsBuildable(head) || AITile.DemolishTile(head))) return false;
  if (!AIRoad.AreRoadTilesConnected(head, body) && !AIRoad.BuildRoad(head, body)) return false;
  /* no problem again here with AITestMode() */
  return (AIRoad.IsRoadDepotTile(body) || AIRoad.BuildRoadDepot(body, head));
}

function BuildingHandler::road::Depot(service, is_source)
{
  AILog.Info("Build Depot");
  local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
  local money_need = AIAccounting();
  local built_s = Tile.RoadDepot(is_source ? service.Info.SourcePos : service.Info.DestinationPos);
  local c_pos = PosClass();
  /* check if i've one */
  if (!built_s.IsEmpty()) {
    local dpt = built_s.Begin();
    c_pos.Body = dpt;
    c_pos.Head = AIRoad.GetRoadDepotFrontTile(dpt);
    if (is_source) service.Info.SourceDepot = c_pos;
    else service.Info.DestinationDepot = c_pos;
    AILog.Info("Depot Not need as I have one");
    return true;
  }
  /* check if i've determined the position*/
  c_pos = (is_source) ? service.Info.SourceDepot : service.Info.DestinationDepot;
  if (AIMap.IsValidTile(c_pos.Body) && AIMap.IsValidTile(c_pos.Head)) {
    if (this._depot(c_pos.Body, c_pos.Head)) return true;
  }
  AILog.Info("Position Invalid, find a new good place");
  /* find a good place */
  local name = (is_source) ? service.Info.SourceText : service.Info.DestinationText;
  local Gpos = Gen.Pos(service, is_source, 3);
	local the_cost = AIAccounting();
	c_pos = null;
	while (c_pos = resume Gpos) {
	  //if (Tile.IsMine(pos.Body)) continue;
    AIController.Sleep(1);
	  //AISign.BuildSign(pos.Body,"b");
		if (MsgResult("Build Depot at " + name, this._depot(c_pos.Body, c_pos.Head))) {
		  if (is_source) service.Info.SourceDepot = c_pos;
      else service.Info.DestinationDepot = c_pos;
		  return true;
		} else {
      if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
			  local addmoney = 0;
			  local wait_time = AIVehicleList().Count() * 2 + 5;
			  AIController.Sleep(wait_time);
		    do {
  		    if (MsgResult("Build Depot at " + name, this._depot(c_pos.Body, c_pos.Head))) {
  		      if (is_source) service.Info.SourceDepot = c_pos;
  		      else service.Info.DestinationDepot = c_pos;
		        this._mother.State.LastCost = money_need.GetCosts();
            return true;
          }
          if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
          AIController.Sleep(wait_time);
        } while (Bank.Get(addmoney += this._mother.Factor));
				//in case come here after break;
				if (Bank.Get(addmoney)) return false;
      }
    }
    AIController.Sleep(1);
	}
  return false;
 }

function BuildingHandler::road::_station(body, head, tipe, id)
{
  AISign.BuildSign(body,"b");
  if (Tile.IsMine(body) || Tile.IsMine(head)) return false;
  if (!(AITile.IsBuildable(body) || AITile.DemolishTile(body))) return false;
  if (!AIRoad.AreRoadTilesConnected(head, body) && !AIRoad.BuildRoad(head, body)) return false;
  /* no problem again here with AITestMode() */
  return (AIRoad.IsRoadStationTile(body) || AIRoad.BuildRoadStation(body, head, tipe, AIStation.STATION_JOIN_ADJACENT || id));
}

function BuildingHandler::road::Station(service, is_source)
{
  AILog.Info("Build Station");
  local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
  local money_need = AIAccounting();
  local c_pos = PosClass();
  local built_s = MyStationTile(is_source ? service.Info.SourcePos : service.Info.DestinationPos);
  /* check if i've one */
  for (local pos = built_s.Begin(); built_s.HasNext(); pos = built_s.Next()) {
    c_pos.ID = AIStation.GetStationID(pos);
    if (!AIStation.HasRoadType(c_pos.ID, AIRoad.ROADTYPE_ROAD)) continue;
    local prod_accept = (is_source) ?
      AITile.GetCargoProduction(pos, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) :
      AITile.GetCargoAcceptance(pos, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) ;
    if (prod_accept < 5) continue;
    /* check if i really need to build other one */
    local v_number = AIVehicleList_Station(c_pos.ID);
    if (v_number.Count() > 0) continue;
    c_pos.Body = AIStation.GetLocation(c_pos.ID);
    c_pos.Head = AIRoad.GetRoadStationFrontTile(c_pos.Body);
    if (is_source) service.Info.SourceStation = c_pos;
    else service.Info.DestinationStation = c_pos;
    AILog.Info("I have empty station one");
    this._mother.State.LastCost = money_need.GetCosts();
    return true;
  }
  /* check if i've determined the position*/
  c_pos = (is_source) ? service.Info.SourceStation : service.Info.DestinationStation;
  if (AIMap.IsValidTile(c_pos.Body) && AIMap.IsValidTile(c_pos.Head)) {
    if (this._station(c_pos.Body, c_pos.Head, RoadStationOf(service.Info.CargoID), c_pos.ID)) return true;
  }
  AILog.Info("Position Invalid, find a new good place");
  /* find a good place */
  local name = (is_source) ? service.Info.SourceText : service.Info.DestinationText;
  local Gpos = Gen.Pos(service, is_source, 1);
	local pos = null;
	while (pos = resume Gpos) {
    //if (Tile.IsMine(pos.Body)) continue;
    local prod_accept = (is_source) ?
      AITile.GetCargoProduction(pos.Body, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) :
      AITile.GetCargoAcceptance(pos.Body, service.Info.CargoID, 1, 1, RoadStationRadius(RoadStationOf(service.Info.CargoID))) ;
    if (prod_accept < 8) continue;
	  if (MsgResult("Road Station at " + name, this._station(pos.Body, pos.Head, RoadStationOf(service.Info.CargoID), c_pos.ID))) {
      pos.ID = AIStation.GetStationID(pos.Body);
      if (is_source) service.Info.SourceStation = pos;
      else service.Info.DestinationStation = pos;
      this._mother.State.LastCost = money_need.GetCosts();
		  return true;
    } else {
			if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
			  local addmoney = 0;
				local pos_income = AIVehicleList().Count();
				local wait_time =  pos_income * 2 + 5;
				AIController.Sleep(wait_time);
				do {
				  if (MsgResult("Road Station at " + name, this._station(pos.Body, pos.Head, RoadStationOf(service.Info.CargoID), c_pos.ID))) {
            pos.ID = AIStation.GetStationID(pos.Body);
            if (is_source) service.Info.SourceStation = pos;
            else service.Info.DestinationStation = pos;
            this._mother.State.LastCost = money_need.GetCosts();
			      return true;
				  }
					if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
					AIController.Sleep(wait_time);
        } while (Bank.Get(addmoney += this._mother.Factor) && pos_income > 1);
				//in case come here after break;
				if (!Bank.Get(addmoney)) return false;
      }
    }
		AIController.Sleep(1);
	}
  return false;
}

function BuildingHandler::road::Path(service, number, is_finding = false)
{
  local txt = (is_finding) ? "Finding:" : "Checking:" ;
  AILog.Info("Path " + txt + number);

  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  
  local _from = -1;
  local _to = -1;
  local Finder = null;
  local distance = 0;
  local result = false;
  local path = false;
  local ignored_tiles = AITileList();
  if (is_finding) {
    //ignored_tiles = Tile.ToIgnore();
    ignored_tiles.AddTile(service.Info.SourceStation.Body);
    ignored_tiles.AddTile(service.Info.DestinationStation.Body);
    ignored_tiles.AddTile(service.Info.SourceDepot.Body);
    ignored_tiles.AddTile(service.Info.DestinationDepot.Body);
  }

  switch (number) {
    case 1:
    _from = service.Info.SourceStation.Head;
    _to = service.Info.DestinationStation.Head;
    if (is_finding) path = service.Info.Path1;
    break;
    case 2:
    _from = service.Info.DestinationDepot.Head;
    _to = service.Info.DestinationStation.Head;
    if (is_finding) path = service.Info.Path2;
    break;
    case 3:
    _from = service.Info.SourceDepot.Head;
    _to = service.Info.SourceStation.Head;
    if (is_finding) path = service.Info.Path3;    
  }
  
  if (!MsgResult("Valid From", AIMap.IsValidTile(_from))) return false;
  if (!MsgResult("Valid To", AIMap.IsValidTile(_to))) return false;
  if (path != null && path != false) return true;
  distance = 1 + AIMap.DistanceManhattan(_from, _to);
  //local prior = Binary_Heap();
  //for (local t = 0; t < 2; t++) {
  Finder = Road();
  local tile_cost = Finder.cost.tile;
  //Finder.cost.max_cost = distance * tile_cost * 10;
  /* check if find existing road first */
  Finder.cost.no_existing_road = is_finding ? tile_cost * number : Finder.cost.max_cost;
  //Finder.cost.tile = 0.2 * tile_cost;
  //Finder.cost.turn = 3 * tile_cost;
	//Finder.cost.slope = 2 * tile_cost;
  //Finder.cost.bridge_per_tile = 6 * tile_cost;
	//Finder.cost.tunnel_per_tile = 10 * tile_cost;
  //Finder.cost.coast = 4 * tile_cost;
	//Finder.cost.crossing = 12 * tile_cost;
  //Finder.cost.NonFreeTile = 5 * tile_cost; //custom cost huh?
  //Finder.cost.allow_demolition = true;
	//Finder.cost.demolition = 12 * tile_cost;
	Finder.cost.estimate_multiplier = service.Info.Is_Subsidy ? 2 : 1.2 ;
  Finder.InitializePath([_from], [_to], 3.5 - number, 20, ignored_tiles);

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

function BuildingHandler::road::Track(service, number)
{
  local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
  local money_need = AIAccounting();
  local txt = (this._mother.State.TestMode) ? "(Test)" :"(Real)" ;
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
						  while (Bank.Get(addmoney += this._mother.Factor / 10) && pos_income > 1) {
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
			  if (!AIRoad.BuildRoadFull(path.GetTile(), parn.GetTile())) {
			    if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					  /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
					  if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
					  if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == parn.GetTile()) {
  						AILog.Info("Build a road tunnel");
	  					if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
		  					/* An error occured while building a tunnel. TODO: handle it. */
			  			}
				  	} else {
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
		}
  path = parn;
  }
  /* check existing road first */
  this._mother.State.LastCost = money_need.GetCosts();
  local r = this._mother.State.TestMode ? 
 	  (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) : this.Path(service, number, false) ;
  AILog.Info("Tracking:" + r +" " + txt);
  return r;
}

function BuildingHandler::road::Vehicle(service)
{
  local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
  local money_need = AIAccounting();
  AILog.Info("Build Vehicle");
  local available = -1;
  if (AIVehicle.IsValidVehicle(service.Info.MainVhcID)) {
    local number = service.Info.SourceIsTown ? AITown.GetMaxProduction(service.Info.SourceID, service.Info.CargoID) :
      AIIndustry.GetLastMonthProduction(service.Info.SourceID, service.Info.CargoID);
    number = (number / AIVehicle.GetCapacity(service.Info.MainVhcID, service.Info.CargoID)).tointeger();
    StartClonedVehicle(service.Info.MainVhcID, service.Info.SourceDepot.Body, number);
    this._mother.State.LastCost = money_need.GetCosts();
    return 1;
  }
  else {
    local _engines = SpeedyRoadEngine();
    local myVhc = null;
    for(local ID_eng = _engines.Begin(); _engines.HasNext() ; ID_eng = _engines.Next()) {
      if (AIEngine.GetCargoType(ID_eng) == service.Info.CargoID) {
        available = 0;
        myVhc = AIVehicle.BuildVehicle(service.Info.SourceDepot.Body, ID_eng);
        ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
      }
      else {
        if (AIEngine.CanRefitCargo(ID_eng, service.Info.CargoID)) {
          available = 0;
          myVhc = AIVehicle.BuildVehicle(service.Info.SourceDepot.Body, ID_eng);
          AIVehicle.RefitVehicle(myVhc, service.Info.CargoID);
          ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
        }
        else continue;
      }
      local load_num = service.Info.SourceIsTown ? 10 : 90;
      if (!AIOrder.AppendOrder(myVhc, service.Info.SourceStation.Body, AIOrder.AIOF_NONE)) {
        ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
        AIVehicle.SellVehicle(myVhc);
        continue;
      }
      if (!AIOrder.AppendOrder(myVhc, service.Info.DestinationStation.Body, AIOrder.AIOF_NONE)) {
        ErrMessage("Vehicle = " + AIEngine.GetName(ID_eng));
        AIVehicle.SellVehicle(myVhc);
        continue;
      }
      AIOrder.AppendOrder(myVhc, service.Info.SourceDepot.Body, AIOrder.AIOF_NONE);
      if (AIVehicle.IsValidVehicle(myVhc)) {
        service.Info.MainVhcID = myVhc;
        AIOrder.InsertConditionalOrder(myVhc, 1, 0);
        AIOrder.SetOrderCondition(myVhc, 1, AIOrder.OC_LOAD_PERCENTAGE);
        AIOrder.SetOrderCompareFunction(myVhc, 1, AIOrder.CF_LESS_THAN);
        AIOrder.SetOrderCompareValue(myVhc, 1, load_num);
        return 1;
      }
    }
    if (available == -1) AILog.Info("No Vehicle available");
    this._mother.State.LastCost = money_need.GetCosts();
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
