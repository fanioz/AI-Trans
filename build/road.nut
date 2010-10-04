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

	/** road builder constructor */
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

    local name = "", areas = null, location = null, is_town = false, t_location = -1;
    if (is_source) {
        name = service.Source.GetName();
        areas = Tiles.Flat(service.Source.GetArea());
        t_location = service.Info.Destination;
        location = service.Info.Source;
        is_town = service.Source.IsTown();
    } else {
        name = service.Destination.GetName();
        areas = Tiles.Flat(service.Destination.GetArea());
        t_location = service.Info.Source;
        location = service.Info.Destination;
        is_town = service.Destination.IsTown();
    }
    
    /* check if i've one */
    local built_s = Tiles.DepotOn(location, 10);
    foreach (pos, val in built_s) {
        if (!AIRoad.IsRoadDepotTile(pos)) continue;
        if (is_source) service.Info.SourceDepot = pos
        else service.Info.DstDepot = pos;
        AILog.Info("Depot Not need as I have one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    
    areas.Valuate(AIMap.DistanceManhattan, location);
    areas.KeepBelowValue(10);
    local Gpos = Generate.Pos(areas, t_location, true);
    while (Gpos.getstatus() == "suspended") {
    	local pos = resume Gpos;
    //if (is_town) areas = Tiles.Roads(areas);
        AIController.Sleep(1);
        if (!this.pre_build(pos.GetLocation(), pos.GetHead())) continue;
        if (Debug.ResultOf("Build Road Depot at " + name, AIRoad.BuildRoadDepot(pos.GetLocation(), pos.GetHead()))) {
            if (is_source) service.Info.SourceDepot = pos.GetLocation()
        	else service.Info.DstDepot = pos.GetLocation();
            this._mother.State.LastCost = money_need.GetCosts();
            return true;
        } else {
            money_need.ResetCosts();
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
        AITile.LevelTiles(head, body);
        AIRoad.BuildRoad(body, head);
    }
    if (this._mother.State.TestMode) return true;
    return AIRoad.AreRoadTilesConnected(head, body); 
}

/**
 * Road Station builder
 * @param service class
 * @param is_source to determine where to build this station
 * @return true if the station can build or has been build
 */
function BuildingHandler::road::Station(service, is_source)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local validID = -1;
    local check_fn = null, name = null, areas = null, 
    	location = null, acceptance = null, stasiun = null;
    if (is_source) {
    	check_fn = AITile.GetCargoProduction;
    	name = service.Source.GetName();
    	areas = service.Source.GetArea();
    	location = service.Source.GetLocation();
    	stasiun = service.SourceStation.weakref();
    	acceptance = 5;
    } else {
    	check_fn = AITile.GetCargoAcceptance;
    	name = service.Destination.GetName();
    	areas = service.Destination.GetArea();
    	location = service.Destination.GetLocation();
    	stasiun = service.DestinationStation.weakref();
    	acceptance = 8;
    }
	AILog.Info("Try to Build Road Station at " + name);
    local built_s = Tiles.StationOn(location);
    /* check if i've one */
    foreach (id, val in built_s) {
    	local loc = AIStation.GetLocation(id);
    	if (!AIRoad.IsRoadStationTile(loc)) continue;
    	if (AIRoad.HasRoadType(loc) != service.Info.TrackType) continue;
    	if (check_fn(loc, service.Info.Cargo, 1, 1, stasiun.ref().GetRadius()) < acceptance) continue;
    	stasiun.ref().SetLocation(loc);
        stasiun.ref().SetID(id);
        validID = id;
        
        /* check if i really need to build other one */
        if (stasiun.ref().GetVehicleList().Count() > 1) continue;
        if (is_source) {
            service.Info.SourceStation = id;
        }
        AILog.Info("I have empty station one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    AILog.Info("find a good place");
    stasiun.ref().SetStationType(service.Info.RoadStationType);
    areas.Valuate(check_fn, service.Info.Cargo, 1, 1, stasiun.ref().GetRadius());
    areas.RemoveBelowValue(acceptance);
    AILog.Info("Count:" + areas.Count());
    local Gpos = Generate.Pos(areas, location, true);
    if (!AIStation.IsValidStation(validID)) validID = AIStation.STATION_JOIN_ADJACENT;
    Debug.ClearErr();
    
    while (Gpos.getstatus() == "suspended") {
    	local pos = resume Gpos;
    	if (typeof pos != "instance") continue;
    	if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) return;
    	if (AIError.GetLastError() == AIError.ERR_LOCAL_AUTHORITY_REFUSES) return;
        AIController.Sleep(1);
        //Debug.Sign(pos.GetBody(), "B");
        //Debug.Sign(pos.GetHead(), "H");        
        if (!this.pre_build(pos.GetLocation(), pos.GetHead())) continue;
        AILog.Info("Prebuild passed");
        local result = AIRoad.BuildRoadStation(pos.GetLocation(), pos.GetHead(), service.Info.RoadStationType, validID);
        if (Debug.ResultOf("Road station at " + name, result)) {
            if (this._mother.State.TestMode) {
            	this._mother.State.LastCost = money_need.GetCosts();
            	return true;
            }
            stasiun.ref().SetID(AIStation.GetStationID(pos.GetLocation()));
            stasiun.ref().SetLocation(pos.GetLocation());
            if (is_source) {
            	service.Info.SourceStation = stasiun.ref().GetID();
            }
            return true;
        } else {
            money_need.ResetCosts();
            if (AIRoad.IsRoadTile(pos.GetHead())) AIRoad.RemoveRoad(pos.GetLocation(), pos.GetHead());
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
    local Finder = null;
    local distance = 0;
    local result = false;
    local path = false;
    	
    switch (number) {
        case 0:
            if (service.Source.IsTown()) {
                _from.push(service.Source.GetLocation());
            } else {
                local area = Tiles.Flat(service.Source.GetArea());
                area.Valuate(
                	function(idx, dst)
                	{
                		return (AIRoad.IsRoadTile(idx) || (AIMap.DistanceMax(idx, dst) < 2))
                	}, service.Source.GetLocation()
                	);
                area.KeepValue(1);
                _from = Assist.ListToArray(area);
            }
            if (service.Destination.IsTown()) {
                _to.push(service.Destination.GetLocation());
            } else {
                local area = Tiles.Flat(service.Destination.GetArea());
                area.Valuate(
                	function(idx, dst)
                	{
                		return (AIRoad.IsRoadTile(idx) || (AIMap.DistanceMax(idx, dst) < 2))
                	}, service.Destination.GetLocation()
                	);
                area.KeepValue(1);
                _to = Assist.ListToArray(area);
            }
            break;
        case 1:
            _from.push(AIRoad.GetRoadDepotFrontTile(service.Info.SourceDepot));
            _to.push(AIRoad.GetRoadStationFrontTile(service.SourceStation.GetLocation()));
            break;
        case 2:
            _from.push(AIRoad.GetRoadStationFrontTile(service.DestinationStation.GetLocation()));
            _to.push(AIRoad.GetRoadDepotFrontTile(service.Info.DstDepot));
            break;
        case 3:
            _from.push(AIRoad.GetRoadStationFrontTile(service.DestinationStation.GetLocation()));
            _from.push(AIRoad.GetRoadDepotFrontTile(service.Info.DstDepot));
            _to.push(AIRoad.GetRoadDepotFrontTile(service.Info.SourceDepot));
            _to.push(AIRoad.GetRoadStationFrontTile(service.SourceStation.GetLocation()));
            break;
        default : Debug.DontCallMe("Path Selection");
    }
	
	/* pre condition */
	if (_from.len() == 0) return;
	if (_to.len() == 0) return;
	if (!AIMap.IsValidTile(_from.top())) return;
	if (!AIMap.IsValidTile(_from.top())) return;
    local dist = AIMap.DistanceManhattan(_from.top(), _to.top());
    
	if (is_finding) {
		Finder = Route.RoadFinder();
		if (number == 0) {
			Finder._estimate_multiplier = 10;
		} else {
			Finder._estimate_multiplier = 2;
			this._ignored_tiles.push(service.SourceStation.GetLocation());
        	this._ignored_tiles.push(service.DestinationStation.GetLocation());
        	this._ignored_tiles.push(service.Info.SourceDepot);
        	this._ignored_tiles.push(service.Info.DstDepot);
		}
    } else {
    	Finder = Route.RoadTracker();
    }
    
    Finder.InitializePath(_from, _to, this._ignored_tiles);
    
    local c = 0;
    while (path == false) {
    	Finder._max_bridge_length = max(5, c + 3);
    	if (c % 10 == 0) Finder._estimate_multiplier ++;
        path = Finder.FindPath(dist);
        AIController.Sleep(1);
        if (Debug.ResultOf("Road Path " + txt, c++) == 102) break;
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
    local last_node = path.GetTile();
    local first_node = -1;
    AILog.Info("Build Road Track " + number + " Length=" + path.GetLength() + txt);
    while (path != null) {
    	first_node = path.GetTile();
        local parn = path.GetParent();
        if (parn != null) {            
            if (AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) == 1 ) {
            	local track_cost = money_need.GetCosts();
                if (!AIRoad.BuildRoad(path.GetTile(), parn.GetTile())) {
                    // An error occured while building a piece of road. TODO: handle some.
                    switch (AIError.GetLastError()) {
                        case AIError.ERR_AREA_NOT_CLEAR:
                        	if (!Tiles.IsMine(parn.GetTile())) AITile.DemolishTile(parn.GetTile());
                        	if (AIRoad.BuildRoad(path.GetTile(), parn.GetTile())) break;
                        	this._ignored_tiles.push(path.GetTile());
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
                            this._ignored_tiles.push(path.GetTile());
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
                } else TransAI.Cost.Road[service.Info.TrackType] <- money_need.GetCosts() - track_cost;
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
    if (this._mother.State.TestMode) return (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH);
    local r = this.Path(service, number, false);
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
        service.Info.VehicleNum += Debug.ResultOf("Vehicle build", Vehicles.StartCloned(service.Info.MainVhcID, service.Info.SourceDepot, 2));
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
            service.Info.BusTruckEngine = MainEngineID; 
            this._mother.State.LastCost  = AIEngine.GetPrice(MainEngineID) * 2;
            if (this._mother.State.TestMode && this._mother.State.LastCost > 0) return true;
            /* and don't care with Exec Mode */
            if (AIEngine.GetCargoType(MainEngineID) == service.Info.Cargo) {
                myVhc = AIVehicle.BuildVehicle(service.Info.SourceDepot, MainEngineID);
            } else {
                if (!AIEngine.CanRefitCargo(MainEngineID, service.Info.Cargo)) continue;
                myVhc = AIVehicle.BuildVehicle(service.Info.SourceDepot, MainEngineID);
                AIVehicle.RefitVehicle(myVhc, service.Info.Cargo);
            }
            if (!AIVehicle.IsValidVehicle(myVhc)) continue;
            /* ordering */
            if (!AIOrder.AppendOrder(myVhc, service.SourceStation.GetLocation(), AIOrder.AIOF_FULL_LOAD_ANY)) {
                Debug.ResultOf("Order failed on Vehicle", name);
                AIVehicle.SellVehicle(myVhc);
                continue;
            }
            if (!AIOrder.AppendOrder(myVhc, service.DestinationStation.GetLocation(), AIOrder.AIOF_NONE)) {
                Debug.ResultOf("Order failed on Vehicle", name);
                AIVehicle.SellVehicle(myVhc);
                continue;
            }
            Vehicles.SetNextOrder(myVhc, service.Info.SourceDepot, service.Info.DstDepot);
            service.Info.MainVhcID = myVhc;
            service.Info.VehicleNum = 1;
            this._mother.State.LastCost += money_need.GetCosts();
            return true;
        }
    }
    return false;
}
