/*  09.03.20 - road.nut
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA 02110-1301, USA.
 */

/**
 * BuildingHandler.road
 * Class of Road builder
 */

class BuildingHandler.road {
	/** The mother instance. */
	_mother = null;
	/** path table in use */
	_path_table = null;	
	/** ignored tiles */
	_ignored_tiles = null;

	constructor(main) {
		this._mother = main;
		this._path_table = {};
		this._ignored_tiles = [];
	}
}

/**
 * Road Depot builder
 * @param service class
 * @param is_source to determine where to build this depot
 * @return true if the depot can build or has been build
 */
function BuildingHandler::road::Depot(service, is_source)
{
    AILog.Info("Try to Build Road Depot");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    
    local c_pos = Platform();
    local name = "", areas = null, location = null, is_town = false, t_location = -1;
    if (is_source) {
        c_pos = service.SourceDepot;
        name = service.Source.GetName();
        areas = Tiles.Flat(service.Source.GetArea());
        t_location = service.Info.Destination;
        location = service.Info.Source;
        is_town = service.Source.IsTown();
    } else {
        c_pos = service.DestinationDepot;
        name = service.Destination.GetName();
        areas = Tiles.Flat(service.Destination.GetArea());
        t_location = service.Info.Source;
        location = service.Info.Destination;
        is_town = service.Destination.IsTown();
    }
    
    /* check if i've one */
    local built_s = Tiles.DepotOn(location);
    foreach (pos, val in built_s) {
        if (!AIRoad.IsRoadDepotTile(pos)) continue;
        c_pos.SetBody(pos);
        c_pos.SetHead(AIRoad.GetRoadDepotFrontTile(pos));
        if (is_source) {
        	service.SourceDepot = c_pos;
        	service.Info.SourceDepot = pos;
        } else service.DestinationDepot = c_pos;
        AILog.Info("Depot Not need as I have one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    
    //if (is_town) areas = Tiles.Roads(areas);
    areas.Valuate(AIMap.DistanceManhattan, location);
    areas.KeepBelowValue(10);
    local Gpos = Generate.Pos(areas, t_location, true);
    while (c_pos = resume Gpos) {
        AIController.Sleep(1);
        if (!this.pre_build(c_pos.GetBody(), c_pos.GetHead())) continue;
        if (Debug.ResultOf("Build Road Depot at " + name, AIRoad.BuildRoadDepot(c_pos.GetBody(), c_pos.GetHead()))) {
            if (is_source) {
	        	service.SourceDepot = c_pos;
	        	service.Info.SourceDepot = c_pos.GetBody();
        	} else service.DestinationDepot = c_pos;
            this._mother.State.LastCost = money_need.GetCosts();
            return true;
        } else {
            money_need.ResetCosts();
            if (AIRoad.IsRoadTile(c_pos.GetHead())) AIRoad.RemoveRoad(c_pos.GetBody(), c_pos.GetHead());
            if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH)  return false;
        }
    }
    return false;
}

/** internal pre building helper */
function BuildingHandler::road::pre_build(body, head)
{
	if (AITile.GetMaxHeight(body) == 0) return;
	if (AITile.GetMaxHeight(head) == 0) return;
	if (!Tiles.IsRoadBuildable(head)) {
		if (Tiles.IsMine(head)) return;
		if (!AITile.DemolishTile(head)) return;
	}
	if (!Tiles.IsRoadBuildable(body)) {
		if (Tiles.IsMine(body)) return;
		if (!AITile.DemolishTile(body)) return;
	}
	local area = Tiles.Adjacent(head);
	area.Valuate(Tiles.IsRoadBuildable);
	area.KeepValue(1);
	if (area.Count() < 2) return;
    //if (!this._mother.State.TestMode) Tiles.SetHeight(body, AITile.GetHeight(head));
    if (!AIRoad.AreRoadTilesConnected(head, body)) {        
        AITile.LevelTiles(body, head);
        AIRoad.BuildRoad(body, head);
    }
    if (!this._mother.State.TestMode) return AIRoad.AreRoadTilesConnected(head, body);
    return true;
}

/**
 * Road Station builder
 * @param service class
 * @param is_source to determine where to build this station
 * @return true if the station can build or has been build
 */
function BuildingHandler::road::Station(service, is_source)
{
    AILog.Info("Try to Build Road Station");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local c_pos = Stations();
    local key = "UTIL";
    local validID = -1;
    local table_util = {};
    
    if (is_source) {
    	table_util = {
	    	check_fn = AITile.GetCargoProduction,
	    	name = service.Source.GetName(),
	    	areas = service.Source.GetArea(),
	    	location = service.Source.GetLocation(),
    	}
    } else {
    	table_util = {
	    	check_fn = AITile.GetCargoAcceptance,
	    	name = service.Destination.GetName(),
	    	areas = service.Destination.GetArea(),
	    	location = service.Destination.GetLocation(),
    	}
    }
    
    local _read = {};
	_read[key] <- table_util;
	local prodacc = Assist.GetMaxProd_Accept(_read[key].areas, service.Info.Cargo, is_source);
    local validID = -1;
    local built_s = Tiles.StationOn(_read[key].location);
    built_s.Valuate(_read[key].check_fn, service.Info.Cargo, 1, 1, Stations.RoadRadius());
    built_s.KeepAboveValue(prodacc - 2);
    /* check if i've one */
    foreach (pos, val in built_s) {
        c_pos.SetID(AIStation.GetStationID(pos));
        if (AIStation.IsValidStation(c_pos.GetID())) validID = c_pos.GetID();
        if (!AIStation.HasRoadType(c_pos.GetID(), AIRoad.ROADTYPE_ROAD)) continue;
        c_pos.GetPlatform(0).SetBody(AIStation.GetLocation(c_pos.GetID()));
        /* check if i really need to build other one */
        if (AIVehicleList_Station(c_pos.GetID()).Count() > 1) continue;
        c_pos.GetPlatform(0).SetHead(AIRoad.GetRoadStationFrontTile(c_pos.GetPlatform(0).GetBody()));
        if (is_source) {
            service.SourceStation = c_pos;
            service.Info.SourceStation = c_pos.GetID();
        } else {
            service.DestinationStation = c_pos;
        }
        AILog.Info("I have empty station one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    //if (is_town) areas = Tiles.Flat(Tiles.Roads(areas));
    AILog.Info("find a good place");
    
    _read[key].areas.Valuate(_read[key].check_fn, service.Info.Cargo, 1, 1, Stations.RoadRadius());
    _read[key].areas.KeepAboveValue(prodacc - 2);
    local Gpos = Generate.Pos(_read[key].areas, _read[key].location, true);
    if (!AIStation.IsValidStation(validID)) validID = 0;
    local pos = null;
    while (pos = resume Gpos) {
        AIController.Sleep(1);
        //Debug.Sign(pos.GetBody(), "B");
        //Debug.Sign(pos.GetHead(), "H");        
        if (!this.pre_build(pos.GetBody(), pos.GetHead())) continue;
        local result = AIRoad.BuildRoadStation(pos.GetBody(), pos.GetHead(), Stations.RoadFor(service.Info.Cargo), AIStation.STATION_JOIN_ADJACENT || validID);
        if (Debug.ResultOf("Road station at " + _read[key].name, result)) {
            if (!this._mother.State.TestMode) {
                local posID =AIStation.GetStationID(pos.GetBody());
                if (!AIStation.IsValidStation(posID)) continue;
                local result = Stations();
                result.SetPlatform(0, pos);
                result.SetID(posID);
                if (is_source) {
                	service.SourceStation = result;
                	service.Info.SourceStation = result.GetID();
                } else service.DestinationStation  = result;
            }
            this._mother.State.LastCost = money_need.GetCosts();
            return true;
        } else {
            money_need.ResetCosts();
            if (AIRoad.IsRoadTile(pos.GetHead())) AIRoad.RemoveRoad(pos.GetBody(), pos.GetHead());
            if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
                AILog.Info("Have no money");
                break;
            }
            if (AIError.GetLastError() == AIError.ERR_LOCAL_AUTHORITY_REFUSES) {
                AILog.Info("Local authority angry");
                break;
            }
        }
    }
    AILog.Info("not found");
    return false;
}

/**
 * Road Path Finder
 * @param service class
 * @param number the code number wich path to find
 * @param is_finding wether to only check a path or find it
 * @return true if the path is found
 */
function BuildingHandler::road::Path(service, number, is_finding)
{
    local txt = (is_finding) ? " Finding:" : " Checking:" ;
    AILog.Info("Road Path " + number + txt);
    local _from = [];
    local _to = [];
    local Finder = RoadPF();
    local distance = 0;
    local result = false;
    local path = false;
    
    local tile_cost = 20;
    Finder.cost.tile = tile_cost;
    Finder.cost.no_existing_road = 2 * tile_cost;
    Finder.cost.turn = 4 * tile_cost;
    Finder.cost.slope = 2 * tile_cost;
    Finder.cost.bridge_per_tile = 6 * tile_cost;
    Finder.cost.tunnel_per_tile = 10 * tile_cost;
    Finder.cost.coast = 4 * tile_cost;
    Finder.cost.crossing = 12 * tile_cost;
    Finder.cost.allow_demolition = true;
    Finder.cost.demolition = 12 * tile_cost;
    Finder.cost.max_bridge_length = 50;
    Finder.cost.max_tunnel_length = 50;
    Finder.RegisterCostCallback(Assist.RoadDiscount, service);

    switch (number) {
        case 0:
            if (service.Source.IsTown()) {
                _from.push(service.Source.GetLocation());
            } else {
                local area = Tiles.Flat(service.Source.GetArea());
                area.Valuate(Tiles.IsRoadBuildable);
                area.KeepValue(1);
                area.Valuate(AIMap.DistanceMax, service.Source.GetLocation());
                area.KeepBelowValue(5);
                _from = Assist.ListToArray(area);
            }
            if (service.Destination.IsTown()) {
                _to.push(service.Destination.GetLocation());
            } else {
                local area = Tiles.Flat(service.Destination.GetArea());
                area.Valuate(Tiles.IsRoadBuildable);
                area.KeepValue(1);
                area.Valuate(AIMap.DistanceMax, service.Destination.GetLocation());
                area.KeepBelowValue(5);
                _to = Assist.ListToArray(area);
            }
            Finder.cost.estimate_multiplier = 5;
            break;
        case 1:
            _from.push(service.SourceDepot.GetHead());
            _to.push(service.SourceStation.GetPlatform(0).GetHead());
            //Finder.cost.estimate_multiplier = 1;
            break;
        case 2:
            _from.push(service.DestinationStation.GetPlatform(0).GetHead());
            _to.push(service.DestinationDepot.GetHead());
            //Finder.cost.estimate_multiplier = 1;
            break;
        case 3:
            _from.push(service.DestinationStation.GetPlatform(0).GetHead());
            _from.push(service.DestinationDepot.GetHead());
            _to.push(service.SourceDepot.GetHead());
            _to.push(service.SourceStation.GetPlatform(0).GetHead());
            //Finder.cost.estimate_multiplier = 1.2;
            break;
        default : Debug.DontCallMe("Path Selection");
    }
    
    try {
        distance = Debug.ResultOf("Distance",1 + AIMap.DistanceManhattan(_from.top(), _to.top()));		
    } catch (distance) {
        AILog.Warning("source:" + service.Source.GetName());
        AILog.Warning("dest:" + service.Destination.GetName());        
        return false;
    }
	
	if (is_finding) {
		if (number != 0) {
			this._ignored_tiles.push(service.SourceStation.GetPlatform(0).GetBody());
        	this._ignored_tiles.push(service.DestinationStation.GetPlatform(0).GetBody());
        	this._ignored_tiles.push(service.SourceDepot.GetBody());
        	this._ignored_tiles.push(service.DestinationDepot.GetBody());
		}		
	    local m = max(Finder.cost.estimate_multiplier * 10, (distance / 4).tointeger());
	    Finder.cost.estimate_multiplier = Debug.ResultOf("Multiplier", m / 10);
    } else {
    /* if we are only check is it connected, do bread first search */
        Finder.cost.estimate_multiplier = 0.1;
        Finder.cost.no_existing_road = Finder.cost.max_cost;
    }
        
    local c =  200;
    Finder.InitializePath(_from, _to, 1.5, 100, this._ignored_tiles);
    
    while (path == false && c-- > 0) {        
        path  = Finder.FindPath(distance);
        AIController.Sleep(1);
    }
    result = Debug.ResultOf("Path " + txt + " stopped at "+ c, (path != null && path != false));
    this._path_table[number] <- path;
    
    return result;
}

/**
 * Road Track builder
 * @param service class
 * @param number the code number wich track to build
 * @return true if the track is build
 */
function BuildingHandler::road::Track(service, number)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local txt = (this._mother.State.TestMode) ? " (Test)" :" (Real)" ;
    local path = null;
    if (number in this._path_table) path = this._path_table[number];
    if (path == null || path == false) return false;
    if (number == 3) service.Info.A_Distance = path.GetLength();
    AILog.Info("Build Road Track " + number + " Length=" + path.GetLength() + txt);
    while (path != null) {
        local parn = path.GetParent();
        if (parn != null) {
            //local last_node = path.GetTile();            
            if (AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) == 1 ) {
                if (!AIRoad.BuildRoad(path.GetTile(), parn.GetTile())) {
                    // An error occured while building a piece of road. TODO: handle some.
                    switch (AIError.GetLastError()) {
                        case AIError.ERR_AREA_NOT_CLEAR:
                        	if (!Tiles.IsMine(parn.GetTile())) AITile.DemolishTile(parn.GetTile());
                        	if (AIRoad.BuildRoad(path.GetTile(), parn.GetTile())) break;
                        	service.IgnoreTileList.AddTile(path.GetTile());
                        	break;
                        case AIError.ERR_ALREADY_BUILT:
                            // thanks
                        	break;
                        case AIError.ERR_VEHICLE_IN_THE_WAY:
                            local x = 50;
                            while (x-- > 0) {
                                AIController.Sleep(x + 1);
                                Debug.ResultOf("Retry build road:" + x, AIRoad.BuildRoad(path.GetTile(), parn.GetTile()));
                                if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
                                if (AIError.GetLastError() != AIError.ERR_VEHICLE_IN_THE_WAY) break;
                            }
                            service.IgnoreTileList.AddTile(path.GetTile());
                            break;
                        case AIError.ERR_NOT_ENOUGH_CASH:
                            local addmoney = 0;
                            local pos_income = AIVehicleList().Count();
                            local wait_time = pos_income * 20 + 5;
                            while (Bank.Get(addmoney += TransAI.Factor10) && pos_income > 1) {
                                AIController.Sleep(wait_time);
                                Debug.ResultOf("Retry build road", AIRoad.BuildRoad(path.GetTile(), parn.GetTile()));
                                if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
                                if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
                            }
                            break;
                        default:
                            Debug.ResultOf("Unhandled error Build Road", null);
                            break;
                    }
                }
            } else {
                if (!AIRoad.BuildRoadFull(path.GetTile(), parn.GetTile())) {
                    if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
                        /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
                        //Debug.Sign(path.GetTile(), "from");
                        //Debug.Sign(parn.GetTile(), "to");
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
                                        Debug.ResultOf("Unhandled error build bridge", null);
                                        //Debug.DontCallMe("Bridge");
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
    this._mother.State.LastCost = money_need.GetCosts();
    /* inconsistent return to handle test mode: As long as the cash enough give it true */
    local r = this._mother.State.TestMode ?
        (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) : this.Path(service, number, false) ;
    AILog.Info("Tracking:" + r +" " + txt);
    return r;
}

/**
 * Road Vehicle builder
 * @param service class
 * @return false if no vehicle available/built and true if it was success
 */
function BuildingHandler::road::Vehicle(service)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    this._mother.State.LastCost = 0;
    AILog.Info("Build Road Vehicle ");
    if (AIVehicle.IsValidVehicle(service.Info.MainVhcID)) {
        //local number = service.SourceIsTown ? AITown.GetMaxProduction(service.Info.Source.ID, service.Info.Cargo) :
        //AIIndustry.GetLastMonthProduction(service.Info.SourceID, service.Info.Cargo);
        //number = (number / AIVehicle.GetCapacity(service.Info.MainVhcID, service.Info.Cargo) / 1.5).tointeger();
        service.Info.VehicleNum += Debug.ResultOf("Vehicle build", Vehicles.StartCloned(service.Info.MainVhcID, service.SourceDepot.GetBody(), 2));
        return true;
    } else {
        local myVhc = null;
        local engines = Vehicles.RVEngine(service.Info.TrackType);
        engines.Valuate(Cargo.IsFit, service.Info.Cargo);
        engines.KeepValue(1);
        engines = Vehicles.SortedEngines(engines);
        while (Debug.ResultOf("engine found", engines.Count()) > 0) {
            local MainEngineID = engines.Pop();
            local name = Debug.ResultOf("RV name", AIEngine.GetName(MainEngineID));
            /* due to needed to check it price in Test Mode */
            this._mother.State.LastCost  = AIEngine.GetPrice(MainEngineID) * 2;
            if (this._mother.State.TestMode && this._mother.State.LastCost > 0) return true;
            /* and don't care with Exec Mode */
            if (AIEngine.GetCargoType(MainEngineID) == service.Info.Cargo) {
                myVhc = AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID);
            } else {
                if (!AIEngine.CanRefitCargo(MainEngineID, service.Info.Cargo)) continue;
                myVhc = AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID);
                AIVehicle.RefitVehicle(myVhc, service.Info.Cargo);
            }
            if (!AIVehicle.IsValidVehicle(myVhc)) continue;
            /* ordering */
            if (!AIOrder.AppendOrder(myVhc, service.SourceStation.GetPlatform(0).GetBody(), AIOrder.AIOF_FULL_LOAD_ANY)) {
                Debug.ResultOf("Order failed on Vehicle", name);
                AIVehicle.SellVehicle(myVhc);
                continue;
            }
            if (!AIOrder.AppendOrder(myVhc, service.DestinationStation.GetPlatform(0).GetBody(), AIOrder.AIOF_NONE)) {
                Debug.ResultOf("Order failed on Vehicle", name);
                AIVehicle.SellVehicle(myVhc);
                continue;
            }
            AIOrder.AppendOrder(myVhc, service.DestinationDepot.GetBody(), AIOrder.AIOF_STOP_IN_DEPOT);
            AIOrder.AppendOrder(myVhc, service.SourceDepot.GetBody(), AIOrder.AIOF_NON_STOP_INTERMEDIATE);
            AIOrder.InsertConditionalOrder(myVhc, 2, 3);
            AIOrder.SetOrderCondition(myVhc, 2, AIOrder.OC_AGE);
            AIOrder.SetOrderCompareFunction(myVhc, 2, AIOrder.CF_LESS_THAN);
            AIOrder.SetOrderCompareValue(myVhc, 2, 2);
            service.Info.MainVhcID = myVhc;
            service.Info.VehicleNum = 1;
            this._mother.State.LastCost += money_need.GetCosts();
            return true;
        }
    }
    return false;
}
