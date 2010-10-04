/*  09.03.20 - rail.nut
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
 *
 * name: BuildingHandler.rail
 * @note class of rail builder // use fake namespace
 */

class BuildingHandler.rail {
	/** The mother instance. */
	_mother = null;
	/** path table in use */
	_path_table = null;
	/** ignored tiles */
	_ignored_tiles = null;

	constructor(main) {
		this._mother = main;
		this._path_table = {};
		_ignored_tiles = [];
	}
}

/**
 * Rail Depot builder
 * @param service class
 * @param is_source to determine where to build this depot
 * @return true if the depot can build or has been build
 */
function BuildingHandler::rail::Depot(service, is_source)
{
    AILog.Info("Try to Build Rail Depot");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    //local built_s = is_source ? service.Source.Depots : service.Destination.Depots;
    local c_pos = Platform();
    /* check if i've one
    foreach (pos, val in built_s) {
        if (!AIRail.IsRailDepotTile(pos)) continue;
        c_pos.SetBody(pos);
        c_pos.SetHead(AIRail.GetRailDepotFrontTile(pos));
        if (is_source) service.SourceDepot = c_pos;
        else service.DestinationDepot = c_pos;
        AILog.Info("Depot Not need as I have one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    local result = false;
    local name = "", Gpos = null;
    if (is_source) {
        name = service.Source.GetName();
        Gpos = Generate.Pos(service.Source.GetArea(), service.Info.Source, false);
    } else {
        name = service.Destination.GetName();
        Gpos = Generate.Pos(service.Destination.GetArea(), service.Info.Destination, false);
    }

    if (!this._mother.State.TestMode) {
        local location = is_source ? service.Info.DepotStart : service.Info.DepotEnd;
        local pos = location[1][0];
        local head = location[1][1];
        local tip = -1;
        if (!AITile.IsBuildable(head)) {
            AILog.Info("default fail");
            pos = location[0][0];
            head = location[0][1];
        }
        if (AITile.GetMaxHeight(pos) == 0) return;
        local addmoney = 0;
        local wait_time = AIVehicleList().Count() * 100 + 5;
        Debug.Sign(pos,"depot");
        Debug.Sign(head,"head");
        result = Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos, head));
        while (!result && Bank.Get(addmoney += TransAI.Factor10)) {
            AIController.Sleep(wait_time);
            result = Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos, head));
        }
        local exit_p = Tiles.FrontMore(head, tip);
        AIRail.BuildRailTrack(head, AIRail.RAILTRACK_NE_SW);
        AIRail.BuildRailTrack(head, AIRail.RAILTRACK_NW_SE);
        AIRail.BuildRailTrack(head, AIRail.RAILTRACK_NW_NE);
        AIRail.BuildRailTrack(head, AIRail.RAILTRACK_SW_SE);
        AIRail.BuildRailTrack(head, AIRail.RAILTRACK_NW_SW);
        AIRail.BuildRailTrack(head, AIRail.RAILTRACK_NE_SE);
        local depot_path = [];
        local exit_ = Tiles.Buildable(Tiles.Adjacent(head));
        foreach (idx, val in exit_) depot_path.push([idx, head]);
        c_pos.SetBody(pos);
        c_pos.SetHead(head);
        service.IgnoreTileList.AddTile(head);
        if (is_source) {
            service.SourceDepot = c_pos;
            service.Info.DepotStart = depot_path;
            service.Info.SourceDepot = pos;
        } else {
            service.DestinationDepot = c_pos;
            service.Info.DepotEnd = depot_path;
        }
        return result;
    }
    while (c_pos = resume Gpos) {
        AIController.Sleep(1);
        if (Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(c_pos.GetBody(), c_pos.GetHead()))) {
            this._mother.State.LastCost = money_need.GetCosts();
            return true;
        } else {
            money_need.ResetCosts();
            if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH)  return false;
        }
    }
    return false;
}

/**
 * Rail Station builder
 * @param service class
 * @param is_source to determine where to build this station
 * @return true if the station can build or has been build
 */
function BuildingHandler::rail::Station(service, is_source)
{
    AILog.Info("Try to Build Rail Station");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local pos = Platform();
    local key = "UTIL";
    local validID = -1;
    local table_util = {};
    
    if (is_source) {
    	table_util = {
	    	check_fn = AITile.GetCargoProduction,
	    	stasiun = service.SourceStation,
	    	name = service.Source.GetName(),
	    	areas = service.Source.GetArea(),
	    	location = service.Source.GetLocation(),
    	}
    } else {
    	table_util = {
	    	check_fn = AITile.GetCargoAcceptance,
	    	stasiun = service.DestinationStation,
	    	name = service.Destination.GetName(),
	    	areas = service.Destination.GetArea(),
	    	location = service.Destination.GetLocation(),
    	}
    }

    /* if dir == NE_SW */
    local table_NE_SW = {
        x = 12,
        y = 3,
        xs = 2,        
        ys = 1,
        opset = AIMap.GetTileIndex(-4, 0),
        head1 = [AIMap.GetTileIndex(-4, 0), AIMap.GetTileIndex(-3, 0)],
        head2 = [AIMap.GetTileIndex(6, 1), AIMap.GetTileIndex(5, 1)],
        depot1 = AIMap.GetTileIndex(-4, 1),
        depot2 = AIMap.GetTileIndex(6, 0),
        depotside = [AIMap.GetTileIndex(-5, 1), AIMap.GetTileIndex(7, 0)],
        range = [AIMap.GetTileIndex(-4, 0), AIMap.GetTileIndex(6, 1)],
    }
    local table_NW_SE = {
        x = 3,
        y = 12,
        xs = 1,
        ys = 2,
        opset = AIMap.GetTileIndex(0, -4),
        head1 = [AIMap.GetTileIndex(1, -4), AIMap.GetTileIndex(1, -3)],
        head2 = [AIMap.GetTileIndex(0, 6), AIMap.GetTileIndex(0, 5)],
        depot1 = AIMap.GetTileIndex(0, -4),
        depot2 = AIMap.GetTileIndex(1, 6),
        depotside = [AIMap.GetTileIndex(0, -5), AIMap.GetTileIndex(1, 7)],
        range = [AIMap.GetTileIndex(0, -4), AIMap.GetTileIndex(0, 6)],
    }
	local _read = {};
	_read[AIRail.RAILTRACK_NW_SE] <- table_NW_SE;
	_read[AIRail.RAILTRACK_NE_SW] <- table_NE_SW;
	_read[key] <- table_util;
    

    _read[key].stasiun.SetWidth(2);
    _read[key].stasiun.SetLength(3);
    
    local built_s = Tiles.StationOn(_read[key].location);
    local prodacc = Assist.GetMaxProd_Accept(_read[key].areas, service.Info.Cargo, is_source);
    built_s.Valuate(_read[key].check_fn, service.Info.Cargo, 2, 3, Stations.RailRadius());
    built_s.KeepAboveValue(prodacc - 2);
    /* check if i've one */
    while (built_s.Count() > 0) {
        AILog.Info("check existing");
        AIController.Sleep(1);
        local base = built_s.Begin();
        built_s.RemoveTop(1);
        local posID = AIStation.GetStationID(base);
        if (!AIStation.IsValidStation(posID)) continue;        
        /*skip the same ID */
        if (posID == validID) continue;        
        validID = posID;
        if (!AIStation.HasStationType(posID, AIStation.STATION_TRAIN)) continue;
        if (!AIRail.IsRailStationTile(posID)) continue;
        base = AIStation.GetLocation(posID);
        /* check if i really need to build other one */
        local train_here = AIVehicleList_Station(posID);
        train_here.Valuate(AIVehicle.GetVehicleType);
        train_here.KeepValue(AIVehicle.VT_RAIL);
        if (train_here.Count()) continue;
        Debug.Sign(base, "stasion");
        _read[key].stasiun.SetID(posID);
        local dir = AIRail.GetRailStationDirection(base);
        _read[key].stasiun.SetDirection(dir);
        //if (dir == 0) continue; fixed ?
        local start_pos = base + _read[dir].opset;
        if (dir == AIRail.RAILTRACK_NW_SE) {
            if (!Platform.RailTemplateNW_SE(start_pos)) {
                Tiles.DemolishRect(start_pos, base + _read[dir].range[1]);
                continue;
            }
        }
        if (dir == AIRail.RAILTRACK_NE_SW) {
            if (!Platform.RailTemplateNE_SW(start_pos)) {
                Tiles.DemolishRect(start_pos, base + _read[dir].range[1]);
                continue;
            }
        }
        pos.SetBody(base);
        pos.SetHead(pos.FindLastTile(_read[key].stasiun.GetDirection(), true, 1));
        pos.SetBack(pos.FindLastTile(_read[key].stasiun.GetDirection(), false, 0));
        pos.SetBackHead(pos.FindLastTile(_read[key].stasiun.GetDirection(), false, 1));
        _read[key].stasiun.SetPlatform(0, pos);
        _read[key].stasiun.SetupAllPlatform();
        local start_path = [];
        start_path.push([base + _read[dir].head1[0], base + _read[dir].head1[1]]);
        start_path.push([base + _read[dir].head2[0], base + _read[dir].head2[1]]);
        local depot_path = [];
        depot_path.push([base + _read[dir].depot1, base + _read[dir].head1[0]]);
        depot_path.push([base + _read[dir].depot2, base + _read[dir].head2[0]]);
        service.IgnoreTileList.RemoveTile(start_path[0][1]);
        service.IgnoreTileList.RemoveTile(start_path[1][1]);
        service.IgnoreTileList.AddTile(base + _read[dir].depotside[0]);
        service.IgnoreTileList.AddTile(base + _read[dir].depotside[1]);
        if (is_source) {
            service.SourceStation = _read[key].stasiun;
            service.Info.StartPath = start_path;
            service.Info.DepotStart = depot_path;
        } else {
            service.DestinationStation  = _read[key].stasiun;
            service.Info.EndPath = start_path;
            service.Info.DepotEnd = depot_path;
        }
        AILog.Info("I have empty station one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    AILog.Info("find a good place");
    
    _read[key].areas.Valuate(_read[key].check_fn, service.Info.Cargo, 2, 3, Stations.RailRadius());
    _read[key].areas.KeepAboveValue(prodacc - 2);
    _read[key].areas.Valuate(AIMap.DistanceMax, _read[key].location);
    _read[key].areas.RemoveValue(0);
    _read[key].areas.Sort(AIAbstractList.SORT_BY_VALUE, true);
    if (!AIStation.IsValidStation(validID)) validID = 0;
    AILog.Info("Prod/Accept Area:" + _read[key].areas.Count());
    for (local base = _read[key].areas.Begin(); _read[key].areas.HasNext(); base = _read[key].areas.Next()) {
        AIController.Sleep(1);
        if (AITile.GetMaxHeight(base) == 0) continue;
        pos.SetBody(base);
        local dir = pos.FindDirection(_read[key].location);
        local start_pos = base + _read[dir].opset;
        local station_end = base + AIMap.GetTileIndex(_read[dir].xs, _read[dir].ys);
        if (!AITile.IsBuildableRectangle(start_pos, _read[dir].x, _read[dir].y)) continue;
        AILog.Info("Buildability Passed");
        
        
        if (!Tiles.IsLevel(base, station_end)) {
            AILog.Info("Terraforming station...");
            if (this._mother.State.TestMode) AITile.LevelTiles(base, station_end);
            else Tiles.MakeLevel(base, station_end);
        }
        //if (!this._mother.State.TestMode) if (tiles.Count() != Tiles.Flat(tiles).Count()) continue;
        _read[key].stasiun.SetDirection(dir);
        local result = AIRail.BuildNewGRFRailStation(base, dir, _read[key].stasiun.GetWidth(), _read[key].stasiun.GetLength(), AIStation.STATION_JOIN_ADJACENT || validID,
            service.Info.Cargo, AIIndustry.GetIndustryType(service.Source.GetID()), AIIndustry.GetIndustryType(service.Destination.GetID()),
            service.Info.R_Distance, is_source);
        if (!result) result = AIRail.BuildRailStation(base, dir, _read[key].stasiun.GetWidth(), _read[key].stasiun.GetLength(), AIStation.STATION_JOIN_ADJACENT || validID);
        if (Debug.ResultOf("Rail station at " + _read[key].name, result)) {
            if (!this._mother.State.TestMode) {
                _read[key].stasiun.SetID(AIStation.GetStationID(base));
                if (!AIStation.IsValidStation(_read[key].stasiun.GetID())) {
                    continue;
                }
                //Debug.Sign(start_pos, "start");
                if (dir == AIRail.RAILTRACK_NW_SE) {
                    if (!Tiles.IsLevel(base + AIMap.GetTileIndex(2, 0), base + _read[dir].range[0])) {
                        AILog.Info("Terraforming NW station...");
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(2, 0), base + _read[dir].range[0]);
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(2, 0), base + _read[dir].range[0]);
                    }
                    if (!Tiles.IsLevel(base + AIMap.GetTileIndex(2, 2), base + _read[dir].depotside[1])) {
                        AILog.Info("Terraforming SE station...");
                        Tiles.MakeLevel(base + _read[dir].depotside[1], base + AIMap.GetTileIndex(2, 2));
                        Tiles.MakeLevel(base + _read[dir].depotside[1], base + AIMap.GetTileIndex(2, 2));
                    }
                    if (!Debug.ResultOf("Platform template", Platform.RailTemplateNW_SE(base + _read[dir].range[0]))) {
                        Tiles.DemolishRect(start_pos, base + _read[dir].range[1]);
                        continue;
                    }
                }
                if (dir == AIRail.RAILTRACK_NE_SW) {
                    if (!Tiles.IsLevel(base + AIMap.GetTileIndex(0, 2), base + _read[dir].range[0])) {
                        AILog.Info("Terraforming NE station...");
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(0, 2), base + _read[dir].range[0]);
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(0, 2), base + _read[dir].range[0]);
                    }
                    if (!Tiles.IsLevel(base + AIMap.GetTileIndex(2, 2), base + _read[dir].depotside[1])) {
                        AILog.Info("Terraforming SW station...");
                        Tiles.MakeLevel(base + _read[dir].depotside[1], base + AIMap.GetTileIndex(2, 2));
                        Tiles.MakeLevel(base + _read[dir].depotside[1], base + AIMap.GetTileIndex(2, 2));
                    }
                    if (!Debug.ResultOf("Platform template", Platform.RailTemplateNE_SW(base + _read[dir].range[0]))) {
                        Tiles.DemolishRect(start_pos, base + _read[dir].range[1]);
                        continue;
                    }
                }
                pos.SetBody(base);
                pos.SetHead(pos.FindLastTile(_read[key].stasiun.GetDirection(), true, 1));
                pos.SetBack(pos.FindLastTile(_read[key].stasiun.GetDirection(), false, 0));
                pos.SetBackHead(pos.FindLastTile(_read[key].stasiun.GetDirection(), false, 1));
                _read[key].stasiun.SetPlatform(0, pos);
                _read[key].stasiun.SetupAllPlatform();
                local start_path = [];
                start_path.push([base + _read[dir].head1[0], base + _read[dir].head1[1]]);
                start_path.push([base + _read[dir].head2[0], base + _read[dir].head2[1]]);
                local depot_path = [];
                depot_path.push([base + _read[dir].depot1, base + _read[dir].head1[0]]);
                depot_path.push([base + _read[dir].depot2, base + _read[dir].head2[0]]);
                service.IgnoreTileList.RemoveTile(start_path[0][1]);
                service.IgnoreTileList.RemoveTile(start_path[1][1]);
                service.IgnoreTileList.AddTile(base + _read[dir].depotside[0]);
                service.IgnoreTileList.AddTile(base + _read[dir].depotside[1]);
                if (is_source) {
                    service.SourceStation = _read[key].stasiun;
                    service.Info.SourceStation = _read[key].stasiun.GetID();
                    service.Info.StartPath = start_path;
                    service.Info.DepotStart = depot_path;
                } else {
                    service.DestinationStation  = _read[key].stasiun;
                    service.Info.EndPath = start_path;
                    service.Info.DepotEnd = depot_path;
                }
            }
            this._mother.State.LastCost = money_need.GetCosts();
            return true;
        } else {
            if (this._mother.State.TestMode && AIError.GetLastError() == AIError.ERR_FLAT_LAND_REQUIRED) return true;
            money_need.ResetCosts();
            if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) break;
            continue;
        }
    }
    AILog.Info("Not found");
    return false;
}
/**
 * Pathfinder rail
 * @param service class
 * @param number the code number wich path to find
 * @param is_finding wether to only check a path of find it
 * @return true if the path is found
 */
function BuildingHandler::rail::Path(service, number, is_finding)
{
    local txt = (is_finding) ? " Finding:" : " Checking:" ;
    AILog.Info("Rail Path " + number + txt);
    local _from = [];
    local _to = [];
    local Finder = RailPF();
    local result = false;
    local path = false;
    
    local tile_cost = 20;
    Finder.cost.tile = tile_cost;
    //Finder.cost.max_cost = distance * tile_cost * 10;
    //Finder.cost.no_existing_rail = 2 * tile_cost;
    Finder.cost.diagonal_tile =  0.4 * tile_cost;
    Finder.cost.turn = 4 * tile_cost;
    Finder.cost.slope =  2 * tile_cost;
    Finder.cost.bridge_per_tile = 10 * tile_cost;
    Finder.cost.tunnel_per_tile = 10 * tile_cost;
    Finder.cost.coast = 4 * tile_cost;
    Finder.cost.crossing = 12 * tile_cost;
    Finder.cost.allow_demolition = true;
    Finder.cost.demolition = 12 * tile_cost;
    Finder.cost.max_bridge_length = 10;
    Finder.cost.max_tunnel_length = 10;
    //Finder.RegisterCostCallback(CheckBridge); // un implemented cost call back


    switch (number) {
        case 0:
            local bodies = Tiles.Buildable(Tiles.Flat(Tiles.Radius(service.Info.Source, 2)));
            foreach (idx, val in bodies) {
                local heads = Tiles.Buildable(Tiles.Flat(Tiles.Adjacent(idx)));
                foreach (head, val in heads) _from.push([head, idx]);
                AIController.Sleep(1);
            }
            bodies = Tiles.Buildable(Tiles.Flat(Tiles.Radius(service.Info.Destination, 2)));
            foreach (idx, val in bodies) {
                local heads = Tiles.Buildable(Tiles.Flat(Tiles.Adjacent(idx)));
                foreach (head, val in heads) _to.push([head, idx]);
                AIController.Sleep(1);
            }
            Finder.cost.max_bridge_length = 100;
    		Finder.cost.max_tunnel_length = 100;
    		Finder.cost.bridge_per_tile = 1 * tile_cost;
    		Finder.cost.tunnel_per_tile = 1 * tile_cost;
            Finder.cost.estimate_multiplier = 20;
            break;
        case 1:
            _from = service.Info.StartPath;
            _to = service.Info.EndPath;
            Finder.cost.estimate_multiplier = 2;
            break;
        case 2:
            _from = service.Info.DepotEnd;
            _to = service.Info.DepotStart;
            Finder.cost.estimate_multiplier = 2;
            break;
        default : Debug.DontCallMe("Path Selection", number);
    }


    if (is_finding) {
        if (number != 0) {
        	foreach (idx, val in Tiles.ToIgnore()) this._ignored_tiles.push(idx);
			foreach (idx, val in service.IgnoreTileList) this._ignored_tiles.push(idx);
        }
    } else {
        /* if we are only check is it connected, do bread first search */
        Finder.cost.estimate_multiplier = 0;
        //Finder.cost.no_existing_road = Finder.cost.max_cost;
        return false;
    }
    
    local distance = 0, dist = 0, cx = 0, cy = 0;
    local scorex = FibonacciHeap(), scorey = FibonacciHeap();
    try {
        distance = Debug.ResultOf("Distance", AIMap.DistanceManhattan(_from.top()[0], _to.top()[0]));        
    } catch (x) {
        AILog.Warning("source:" + _from.len());
        AILog.Warning("dest:" + _to.len());
        return false;
    }
    local m = max(Finder.cost.estimate_multiplier , (distance / 20).tointeger());
    Finder.cost.estimate_multiplier = Debug.ResultOf("Multiplier", m);
    Finder.InitializePath(_from, _to, this._ignored_tiles);

    local c = 0;
    while (path == false && c++ < 250) {
        path  = Finder.FindPath(distance);
        AIController.Sleep(1);        
    }
    
    result = Debug.ResultOf("Path " + txt + " stopped at "+ c, (path != null && path != false));
    this._path_table[number] <- path;
    return result;
}

/**
 * Rail Track builder
 * @param service class
 * @param number the code number wich track to build
 * @return true if the track is build
 */
function BuildingHandler::rail::Track(service, number)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local txt = (this._mother.State.TestMode) ? " (Test)" :" (Real)" ;
    local path = null;
    if (number in this._path_table) path = this._path_table[number];
    if (path == null || path == false) return false;
    if (number == 1) service.Info.A_Distance = path.GetLength();
    local path_for_check = path;
    AILog.Info("Build Rail Track " + number + " Length=" + path.GetLength() + txt);
    local prev = null;
    local prevprev = null;
    while (path != null) {
        if (prevprev != null) {
            if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
                /*if (AIMap.DistanceManhattan(prev, path.GetTile()) == 2) {
                }*/
                if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
                    if (!AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev)) {
                        /* error build tunnel */
                        switch (AIError.GetLastError()) {
                            case AIError.ERR_PRECONDITION_FAILED : break;
                        }
                        service.IgnoreTileList.AddTile(prev);
                    }
                }
                else {
                    local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
                    bridge_list.Valuate(AIBridge.GetMaxSpeed);
                    bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
                    if (!AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile())) {
                        /* error build bridge */
                        switch (AIError.GetLastError()) {
                            case AIError.ERR_PRECONDITION_FAILED : break;
                            case AIError.ERR_NOT_ENOUGH_CASH:
                                while (bridge_list.HasNext()) {
                                    local bridge = bridge_list.Next();
                                    if (!Bank.Get(AIBridge.GetPrice(bridge, AIMap.DistanceManhattan(path.GetTile(), prev) + 1))) continue;
                                    if (AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge, path.GetTile(), prev)) break;
                                }
                                break;

                        }
                        service.IgnoreTileList.AddTile(prev);
                    }
                }
                //prevprev = prev;
                //prev = path.GetTile();
                //path = path.GetParent();
            }
            else {
                if (!AIRail.BuildRail(prevprev, prev, path.GetTile())) {
                    switch (AIError.GetLastError()) {
                        case AIError.ERR_PRECONDITION_FAILED :
                            break;
                        case AIError.ERR_AREA_NOT_CLEAR:
                            if (!Tiles.IsMine(prev)) if (!AITile.DemolishTile(prev)) {
                            	service.IgnoreTileList.AddTile(prev);
                            	return false;
                            }
                            AIRail.BuildRail(prevprev, prev, path.GetTile());                            
                            break;
                        case AIError.ERR_ALREADY_BUILT:
                            // thanks
                            break;
                        case AIError.ERR_VEHICLE_IN_THE_WAY:
                            local x = 50;
                            while (x-- > 0) {
                                AIController.Sleep(x + 1);
                                Debug.ResultOf("Retry build rail:" + x, AIRail.BuildRail(prevprev, prev, path.GetTile()));
                                if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
                                if (AIError.GetLastError() != AIError.ERR_VEHICLE_IN_THE_WAY) break;
                            }
                            service.IgnoreTileList.AddTile(prev);
                            break;
                        case AIError.ERR_NOT_ENOUGH_CASH:
                            local addmoney = 0;
                            local pos_income = AIVehicleList().Count();
                            local wait_time = pos_income * 20 + 5;
                            while (Bank.Get(addmoney += TransAI.Factor10) && pos_income > 1) {
                                AIController.Sleep(wait_time);
                                Debug.ResultOf("Retry build rail", AIRail.BuildRail(prevprev, prev, path.GetTile()));
                                if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
                                if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) break;
                            }
                            break;
                        default:
                            Debug.ResultOf("Unhandled error Build Rail", prev);
                            break;
                    }
                }
            }
        }
        if (path != null) {
            prevprev = prev;
            prev = path.GetTile();
            path = path.GetParent();
        }
    }
    this._mother.State.LastCost = money_need.GetCosts();
    if (this._mother.State.TestMode) return (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH);
    return Assist.CheckRailConnection(path_for_check);
}

/**
 * Rail Vehicle builder
 * @param service class
 * @return false if no vehicle available/built and true if it was success
 */
function BuildingHandler::rail::Vehicle(service)
{
    /*
     * what value will be returned ?
     * in normal case loco + wagon = true if can build completely
     * in test mode loco + wagon = true if available
     * otherwise will be asumed as 'fail'
     */
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    this._mother.State.LastCost = 0;
    AILog.Info("Build Rail Vehicle ");
    if (AIVehicle.IsValidVehicle(service.Info.MainVhcID)) {
        //activated if we use existing rail
        //local number = service.SourceIsTown ? AITown.GetMaxProduction(service.Source.ID, service.Cargo) :
        //AIIndustry.GetLastMonthProduction(service.SourceID, service.Cargo);
        //number = (number / AIVehicle.GetCapacity(service.MainVhcID, service.Cargo) / 1.5).tointeger();
        service.Info.VehicleNum += Debug.ResultOf("Vehicle build", Vehicles.StartCloned(service.Info.MainVhcID, service.SourceDepot.GetBody(), 2));
        return true;
    }

    local loco_id = -1;

    /* pick a loco */
    local locos = Vehicles.WagonEngine(0);
    locos.Valuate(AIEngine.HasPowerOnRail, service.Info.TrackType);
    locos.KeepValue(1);    
    if (Debug.ResultOf("loco found", locos.Count()) < 1) return false;
    locos = Vehicles.SortedEngines(locos);
    while (locos.Count() > 0) {
        /* due to needed to check it price in Test Mode */
        local MainEngineID = locos.Pop();
        local engine_name = AIEngine.GetName(MainEngineID);
        if (!AIEngine.CanPullCargo(MainEngineID, service.Info.Cargo)) continue;
        this._mother.State.LastCost = AIEngine.GetPrice(MainEngineID) * 1.5 ;
        if (this._mother.State.TestMode && this._mother.State.LastCost > 0) break;
        local addmoney = AIEngine.GetPrice(MainEngineID);
        local wait_time = AIVehicleList().Count() * 10 + 5;
        loco_id = Debug.ResultOf("Try to buy " + engine_name, AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID));
        while (!AIVehicle.IsValidVehicle(loco_id) && Bank.Get(addmoney += this._mother.ff_factor / 10)) {
            AIController.Sleep(wait_time);
            loco_id = Debug.ResultOf("(retry buy " + engine_name, AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID));
            if (AIVehicle.IsValidVehicle(loco_id)) break;
        }
        if (AIEngine.CanRefitCargo(MainEngineID, service.Info.Cargo)) AIVehicle.RefitVehicle(loco_id, service.Info.Cargo);

        /* ordering */
        if (!AIOrder.AppendOrder(loco_id, service.SourceStation.GetPlatform(0).GetBody(), AIOrder.AIOF_FULL_LOAD_ANY)) {
            Debug.ResultOf("Order failed on Vehicle", AIEngine.GetName(MainEngineID));
            AIVehicle.SellVehicle(loco_id);
            continue;
        }
        if (!AIOrder.AppendOrder(loco_id, service.DestinationStation.GetPlatform(0).GetBody(), AIOrder.AIOF_NONE)) {
            Debug.ResultOf("Order failed on Vehicle", AIEngine.GetName(MainEngineID));
            AIVehicle.SellVehicle(loco_id);
            continue;
        }
        AIOrder.AppendOrder(loco_id, service.DestinationDepot.GetBody(), AIOrder.AIOF_STOP_IN_DEPOT);
        AIOrder.AppendOrder(loco_id, service.SourceDepot.GetBody(), AIOrder.AIOF_NON_STOP_INTERMEDIATE);
        AIOrder.InsertConditionalOrder(loco_id, 2, 3);
        AIOrder.SetOrderCondition(loco_id, 2, AIOrder.OC_AGE);
        AIOrder.SetOrderCompareFunction(loco_id, 2, AIOrder.CF_LESS_THAN);
        AIOrder.SetOrderCompareValue(loco_id, 2, 2);  	
        service.Info.MainVhcID = loco_id;
        break;
    }

    if (!AIVehicle.IsValidVehicle(loco_id) && !this._mother.State.TestMode) return false;

    local loco_length = AIVehicle.GetLength(loco_id);
    local wagon_id = -1;

    /* pick a wagon */
    local wagons = Vehicles.WagonEngine(1);
    wagons.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
    wagons.KeepValue(1);
    if (Debug.ResultOf("wagon found", wagons.Count()) < 1) {
        AIVehicle.SellVehicle(loco_id);
        return false;
    }

    wagons = Vehicles.SortedEngines(wagons);
    while (wagons.Count()) {
        local MainEngineID = wagons.Pop();
        //local wagon_name = Debug.ResultOf("Name", AIEngine.GetName(MainEngineID));
        if (!Cargo.IsFit(MainEngineID, service.Info.Cargo)) continue;        
        this._mother.State.LastCost += AIEngine.GetPrice(MainEngineID) * 6;
        if (this._mother.State.TestMode && this._mother.State.LastCost > 0) return true;
        local total_length = 0;
        local wagon_count = 0;
        local max = service.SourceStation.GetLength() * 16;
        while (total_length < max) {
            wagon_id = AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID);
            if (!AIVehicle.IsValidVehicle(wagon_id)) break;
            if (AIEngine.GetCargoType(MainEngineID) != service.Info.Cargo) AIVehicle.RefitVehicle(wagon_id, service.Info.Cargo);
            if (AIEngine.GetCargoType(MainEngineID) != service.Info.Cargo) {
                AIVehicle.SellVehicle(wagon_id);
                break;
            }
            if (AIVehicle.MoveWagon(wagon_id, 0, loco_id, 0)) wagon_count++;
            total_length = Debug.ResultOf("Loco len", AIVehicle.GetLength(loco_id));
        }
        if (total_length % max != 0) AIVehicle.SellWagon(loco_id, wagon_count);
    }
    if (AIVehicle.GetLength(loco_id) > loco_length) {
        service.Info.MainVhcID = loco_id;
        service.Info.VehicleNum = 1;
        return true;
    }
    AIVehicle.SellVehicle(loco_id);
    return false;
}

function BuildingHandler::rail::Signal(service, number)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local txt = (this._mother.State.TestMode) ? " (Test)" :" (Real)" ;
    local path = null;
    if (number in this._path_table) path = this._path_table[number];
    if (path == null || path == false) return false;
    AILog.Info("Build Signal Length=" + path.GetLength() + txt);
    local c = 0;
    while (path != null) {
        local parn = path.GetParent();
        if ((c % 4 == 1) && parn != null && (AIRail.GetSignalType(path.GetTile(), parn.GetTile()) == AIRail.SIGNALTYPE_NONE))
            if (!AIRail.BuildSignal(path.GetTile(), parn.GetTile(), AIRail.SIGNALTYPE_NORMAL)) {
                while (AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY) {
                    AIController.Sleep(5);
                    AIRail.BuildSignal(path.GetTile(), parn.GetTile(), AIRail.SIGNALTYPE_NORMAL);
                }
                local money = 0;
                while (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH ) {
                	money += TransAI.Factor10;
                	AIController.Sleep((money / 1000).tointeger());
                	AIRail.BuildSignal(path.GetTile(), parn.GetTile(), AIRail.SIGNALTYPE_NORMAL);
                }
            }
        if (path != null) {
            path = parn;
            c++;
        }
    }
    this._mother.State.LastCost = money_need.GetCosts();
    return true;
}
