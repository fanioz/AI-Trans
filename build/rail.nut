/*
 *      09.03.20
 *      build.rail.nut
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
 * name: BuildingHandler.rail
 * @note class of rail builder // use fake namespace
 */

class BuildingHandler.rail {
  _mother = null; /// the mother instance
  _service = null;

  constructor(main) {
    this._mother = main;
    this._service = null;
  }

/**
 *
 * name: Depot
 * @param service class
 * @param is_source to determine where to build this depot
 * @return true if the depot can build or has been build
 */
  function Depot(service, is_source);

/**
 *
 * name: Path
 * @param service class
 * @param number the code number wich path to find
 * @param is_finding wether to only check a path of find it
 * @return true if the path is found
 */
  function Path(service, number, is_finding = false);

/**
 *
 * name: Station
 * @param service class
 * @param is_source to determine where to build this station
 * @return true if the station can build or has been build
 */
  function Station(service, is_source);

/**
 *
 * name: Track
 * @param service class
 * @param number the code number wich track to build
 * @return true if the track is build
 */
  function Track(service, number);

/**
 *
 * name: Vehicle
 * @param service class
 * @return false if no vehicle available/built and true if it was success
 */
  function Vehicle(service);
}

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
        c_pos = service.SourceDepot;
        name = service.Source.Name;
        Gpos = Gen.Pos(service.Source.Area, service.Source.Location, false);
    } else {
        c_pos = service.DestinationDepot;
        name = service.Destination.Name;
        Gpos = Gen.Pos(service.Destination.Area, service.Destination.Location, false);
    }

    if (!this._mother.State.TestMode) {
        local location = is_source ? service.DepotStart : service.DepotEnd;
        local pos = location[1][0];
        local head = location[1][1];
        local tip = -1;
        if (!AITile.IsBuildable(head)) {
            AILog.Info("default fail");
            pos = location[0][0];
            head = location[0][1];
        }
        local addmoney = 0;
        local wait_time = AIVehicleList().Count() * 100 + 5;
        Debug.Sign(pos,"depot");
        Debug.Sign(head,"head");
        result = Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos, head));
        while (!result && Bank.Get(addmoney += this._mother.ff_factor / 10)) {
            AIController.Sleep(wait_time);
            result = Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos, head));
        }
        local exit_p = FrontMore(head, tip);
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
        service.IgnorePath.AddTile(head);
        if (is_source) {
            service.SourceDepot = c_pos;
            service.DepotStart <- depot_path;
        } else {
            service.DestinationDepot = c_pos;
            service.DepotEnd <- depot_path;
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

function BuildingHandler::rail::Station(service, is_source)
{
    AILog.Info("Try to Build Rail Station");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local stasiun = Stations();
    local pos = Platform();
    local check_fn = is_source ? AITile.GetCargoProduction : AITile.GetCargoAcceptance ;
    local validID = -1;

    /* if dir == NE_SW */
    local table_NE_SW = {
        x = 11,
        xs = 2,
        y = 3,
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
        y = 11,
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
    local read_table = {};
    read_table[AIRail.RAILTRACK_NW_SE] <- table_NW_SE;
    read_table[AIRail.RAILTRACK_NE_SW] <- table_NE_SW;

    local built_s = Tiles.StationOn(is_source ? service.Source.Location : service.Destination.Location);
    local prodacc = Assist.GetMaxProd_Accept(is_source ? service.Source.Area : service.Destination.Area, service.Cargo, is_source);
    built_s.Valuate(check_fn, service.Cargo, 2, 3, Stations.RailRadius());
    built_s.KeepAboveValue(prodacc - 1);
    /* check if i've one */
    while (built_s.Count() > 0) {
        AILog.Info("check existing");
        AIController.Sleep(1);
        local base = built_s.Begin();
        built_s.RemoveTop(1);
        local posID = AIStation.GetStationID(base);
        if (!AIStation.HasStationType(posID, AIStation.STATION_TRAIN)) continue;
        /*skip the same ID */
        if (posID == validID) continue;
        if (AIStation.IsValidStation(posID)) validID = posID;
        else continue;
        base = AIStation.GetLocation(posID);
        /* check if i really need to build other one */
        local train_here = AIVehicleList_Station(posID);
        train_here.Valuate(AIVehicle.GetVehicleType);
        train_here.KeepValue(AIVehicle.VT_RAIL);
        if (train_here.Count() > 0) continue;
        Debug.Sign(base, "stasion");
        stasiun.SetID(posID);
        local dir = AIRail.GetRailStationDirection(base);
        if (dir == 0) continue;
        local start_pos = base + read_table[dir].opset;
        if (dir == AIRail.RAILTRACK_NW_SE) {
            if (!Platform.RailTemplateNW_SE(start_pos)) {
                AllocateLand(start_pos, base + read_table[dir].range[1]);
                continue;
            }
        }
        if (dir == AIRail.RAILTRACK_NE_SW) {
            if (!Platform.RailTemplateNE_SW(start_pos)) {
                AllocateLand(start_pos, base + read_table[dir].range[1]);
                continue;
            }
        }
        pos.SetBody(base);
        pos.SetHead(pos.FindLastTile(stasiun.GetDirection(), true, 1));
        pos.SetBack(pos.FindLastTile(stasiun.GetDirection(), false, 0));
        pos.SetBackHead(pos.FindLastTile(stasiun.GetDirection(), false, 1));
        stasiun.SetPlatform(0, pos);
        stasiun.SetupAllPlatform();
        local start_path = [];
        start_path.push([base + read_table[dir].head1[0], base + read_table[dir].head1[1]]);
        start_path.push([base + read_table[dir].head2[0], base + read_table[dir].head2[1]]);
        local depot_path = [];
        depot_path.push([base + read_table[dir].depot1, base + read_table[dir].head1[0]]);
        depot_path.push([base + read_table[dir].depot2, base + read_table[dir].head2[0]]);
        service.IgnorePath.RemoveTile(start_path[0][1]);
        service.IgnorePath.RemoveTile(start_path[1][1]);
        service.IgnorePath.AddTile(base + read_table[dir].depotside[0]);
        service.IgnorePath.AddTile(base + read_table[dir].depotside[1]);
        if (is_source) {
            service.SourceStation = stasiun;
            service.StartPath <- start_path;
            service.DepotStart <- depot_path;
        } else {
            service.DestinationStation  = stasiun;
            service.EndPath <- start_path;
            service.DepotEnd <- depot_path;
        }
        AILog.Info("I have empty station one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    AILog.Info("find a good place");
    local name = "", areas = null, stasiun = null;
    local location = null;
    if (is_source) {
        stasiun = service.SourceStation;
        name = service.Source.Name;
        areas = service.Source.Area;
        location = service.Source.Location;
    } else {
        stasiun = service.DestinationStation;
        name = service.Destination.Name;
        areas = service.Destination.Area;
        location = service.Destination.Location;
    }

    stasiun.SetWidth(2);
    stasiun.SetLength(3);
    areas.Valuate(check_fn, service.Cargo, 2, 3, Stations.RailRadius());
    areas.KeepAboveValue(prodacc - 2);
    areas.Valuate(AIMap.DistanceMax, location);
    areas.RemoveValue(0);
    areas.Sort(AIAbstractList.SORT_BY_VALUE, true);
    if (!AIStation.IsValidStation(validID)) validID = 0;
    for (local base = areas.Begin(); areas.HasNext(); base = areas.Next()) {
        AIController.Sleep(1);
        pos.SetBody(base);
        local dir = pos.FindDirection(location);
        local start_pos = base + read_table[dir].opset;
        if (!AITile.IsBuildableRectangle(start_pos, read_table[dir].x, read_table[dir].y)) continue;
        AILog.Info("Buildability Passed");
        local tiles = AITileList();
        tiles.AddRectangle(base, base + AIMap.GetTileIndex(read_table[dir].xs, read_table[dir].ys));
        if (tiles.Count() != Tiles.Flat(tiles).Count()) {
            AILog.Info("Terraforming station...");
            if (this._mother.State.TestMode) AITile.LevelTiles(base, base + AIMap.GetTileIndex(read_table[dir].xs, read_table[dir].ys));
            else Tiles.MakeLevel(base, base + AIMap.GetTileIndex(read_table[dir].xs, read_table[dir].ys));
        }
        //if (!this._mother.State.TestMode) if (tiles.Count() != Tiles.Flat(tiles).Count()) continue;
        stasiun.SetDirection(dir);
        local result = AIRail.BuildNewGRFRailStation(base, dir, stasiun.GetWidth(), stasiun.GetLength(), AIStation.STATION_JOIN_ADJACENT || validID,
            service.Cargo, AIIndustry.GetIndustryType(service.Source.ID), AIIndustry.GetIndustryType(service.Destination.ID),
            service.Distance, is_source);
        if (!result) result = AIRail.BuildRailStation(base, dir, stasiun.GetWidth(), stasiun.GetLength(), AIStation.STATION_JOIN_ADJACENT || validID);
        if (Debug.ResultOf("Rail station at " + name, result)) {
            if (!this._mother.State.TestMode) {
                stasiun.SetID(AIStation.GetStationID(base));
                if (!AIStation.IsValidStation(stasiun.GetID())) {
                    continue;
                }
                Debug.Sign(start_pos, "start");
                if (dir == AIRail.RAILTRACK_NW_SE) {
                    tiles.Clear();
                    tiles.AddRectangle(base + AIMap.GetTileIndex(2, 0), base + read_table[dir].range[0]);
                    if (tiles.Count() != Tiles.Flat(tiles).Count()) {
                        AILog.Info("Terraforming NW station...");
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(2, 0), base + read_table[dir].range[0]);
                    }
                    tiles.Clear();
                    tiles.AddRectangle(base + AIMap.GetTileIndex(2, 2), base + read_table[dir].depotside[1]);
                    if (tiles.Count() != Tiles.Flat(tiles).Count()) {
                        AILog.Info("Terraforming SE station...");
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(2, 2), base + read_table[dir].depotside[1]);
                    }
                    if (!Debug.ResultOf("Platform template", Platform.RailTemplateNW_SE(base + read_table[dir].range[0]))) {
                        AllocateLand(start_pos, base + read_table[dir].range[1]);
                        continue;
                    }
                }
                if (dir == AIRail.RAILTRACK_NE_SW) {
                    tiles.Clear();
                    tiles.AddRectangle(base + AIMap.GetTileIndex(0, 2), base + read_table[dir].range[0]);
                    if (tiles.Count() != Tiles.Flat(tiles).Count()) {
                        AILog.Info("Terraforming NE station...");
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(0, 2), base + read_table[dir].range[0]);
                    }
                    tiles.Clear();
                    tiles.AddRectangle(base + AIMap.GetTileIndex(2, 2), base + read_table[dir].depotside[1]);
                    if (tiles.Count() != Tiles.Flat(tiles).Count()) {
                        AILog.Info("Terraforming SW station...");
                        Tiles.MakeLevel(base + AIMap.GetTileIndex(2, 2), base + read_table[dir].depotside[1]);
                    }
                    if (!Debug.ResultOf("Platform template", Platform.RailTemplateNE_SW(base + read_table[dir].range[0]))) {
                        AllocateLand(start_pos, base + read_table[dir].range[1]);
                        continue;
                    }
                }
                pos.SetBody(base);
                pos.SetHead(pos.FindLastTile(stasiun.GetDirection(), true, 1));
                pos.SetBack(pos.FindLastTile(stasiun.GetDirection(), false, 0));
                pos.SetBackHead(pos.FindLastTile(stasiun.GetDirection(), false, 1));
                stasiun.SetPlatform(0, pos);
                stasiun.SetupAllPlatform();
                local start_path = [];
                start_path.push([base + read_table[dir].head1[0], base + read_table[dir].head1[1]]);
                start_path.push([base + read_table[dir].head2[0], base + read_table[dir].head2[1]]);
                local depot_path = [];
                depot_path.push([base + read_table[dir].depot1, base + read_table[dir].head1[0]]);
                depot_path.push([base + read_table[dir].depot2, base + read_table[dir].head2[0]]);
                service.IgnorePath.RemoveTile(start_path[0][1]);
                service.IgnorePath.RemoveTile(start_path[1][1]);
                service.IgnorePath.AddTile(base + read_table[dir].depotside[0]);
                service.IgnorePath.AddTile(base + read_table[dir].depotside[1]);
                if (is_source) {
                    service.SourceStation = stasiun;
                    service.StartPath <- start_path;
                    service.DepotStart <- depot_path;
                } else {
                    service.DestinationStation  = stasiun;
                    service.EndPath <- start_path;
                    service.DepotEnd <- depot_path;
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

function BuildingHandler::rail::Path(service, number, is_finding = false)
{
    local txt = (is_finding) ? " Finding:" : " Checking:" ;
    AILog.Info("Rail Path " + number + txt);
    local _from = [];
    local _to = [];
    local Finder = Rail();
    local result = false;
    local path = false;
    local ignored_tiles = [];

    local tile_cost = 20;
    Finder.cost.tile = 0.5 * tile_cost;
    //Finder.cost.max_cost = distance * tile_cost * 10;
    //Finder.cost.no_existing_rail = 2 * tile_cost;
    Finder.cost.diagonal_tile =  0.4 * tile_cost;
    Finder.cost.turn = 4 * tile_cost;
    Finder.cost.slope =  4 * tile_cost;
    Finder.cost.bridge_per_tile = 8 * tile_cost;
    Finder.cost.tunnel_per_tile = 6 * tile_cost;
    Finder.cost.coast = 8 * tile_cost;
    Finder.cost.crossing = 24 * tile_cost;
    //Finder.cost.NonFreeTile = 5 * tile_cost; //un implemented custom cost huh?
    Finder.cost.allow_demolition = true;
    Finder.cost.demolition = 24 * tile_cost;
    Finder.cost.max_bridge_length = 50;
    Finder.cost.max_tunnel_length = 50;
    //Finder.RegisterCostCallback(CheckBridge); // un implemented cost call back


    switch (number) {
        case 0:
            local bodies = Tiles.Buildable(Tiles.Flat(Tiles.Radius(service.Source.Location, 2)));
            foreach (idx, val in bodies) {
                local heads = Tiles.Buildable(Tiles.Flat(Tiles.Adjacent(idx)));
                foreach (head, val in heads) _from.push([head, idx]);
            }
            bodies = Tiles.Buildable(Tiles.Flat(Tiles.Radius(service.Destination.Location, 2)));
            foreach (idx, val in bodies) {
                local heads = Tiles.Buildable(Tiles.Flat(Tiles.Adjacent(idx)));
                foreach (head, val in heads) _to.push([head, idx]);
            }
            Finder.cost.estimate_multiplier = 5;
            break;
        case 1:
            _from = service.StartPath;
            _to = service.EndPath;
            Finder.cost.estimate_multiplier = 1.5;
            break;
        case 2:
            _from = service.DepotEnd;
            _to = service.DepotStart;
            Finder.cost.estimate_multiplier = 1.2;
            break;
        default : Debug.DontCallMe("Path Selection", number);
    }


    if (is_finding) {
        ignored_tiles = Tiles.ToIgnore();
        if (number != 0)  foreach (idx, val in service.IgnorePath) ignored_tiles.push(idx);
    } else {
        /* if we are only check is it connected, do bread first search */
        Finder.cost.estimate_multiplier = 0;
        //Finder.cost.no_existing_road = Finder.cost.max_cost;
        return false;
    }
    local distance = 0, dist = 0, cx = 0, cy = 0;
    local scorex = BinaryHeap(), scorey = BinaryHeap();
    try {
        distance = AIMap.DistanceManhattan(_from.top()[0], _to.top()[0]);
        //Debug.Sign(_from.top()[0], "from");
        //Debug.Sign(_to.top()[0],"to");
        Finder.InitializePath(_from, _to, ignored_tiles);
    } catch (distance) {
        AILog.Warning("source:" + _from.len());
        AILog.Warning("dest:" + _to.len());
        return false;
    }

    local c =   200;
    //local d = max(((1000 - distance) / 1000).tointeger(), 2);
    while (path == false && c-- > 0) {
        AIController.Sleep(1);
        path  = Finder.FindPath(distance);
        if (c % 10 == 0) this._mother._commander.Evaluate();
    }
    result = Debug.ResultOf("Path " + txt + " stopped at "+ c, (path != null && path != false));
    switch (number) {
        case 0:  service.Path0 <- path; break;
        case 1: service.Path1 <- path; break;
        case 2: service.Path2 <- path; break;
        case 3: service.Path3 <- path; break;
    }
    return result;
}

function BuildingHandler::rail::Track(service, number)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local txt = (this._mother.State.TestMode) ? " (Test)" :" (Real)" ;
    local path = null;
    try {
        switch (number) {
            case 0: path = service.Path0; break;
            case 1: path = service.Path1; break;
            case 2: path = service.Path2; break;
            case 3: path = service.Path3; break;
        }
    } catch (path) {
        return false;
    }
    if (path == null || path == false) return false;
    local path_for_check = path;
    AILog.Info("Build Rail Track Length=" + path.GetLength() + txt);
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
                        service.IgnorePath.AddTile(prev);
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
                        service.IgnorePath.AddTile(prev);
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
                            if (!Tiles.IsMine(prev, false)) if (!AITile.DemolishTile(prev)) return false;
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
                            break;
                        case AIError.ERR_NOT_ENOUGH_CASH:
                            local addmoney = 0;
                            local pos_income = AIVehicleList().Count();
                            local wait_time = pos_income * 20 + 5;
                            while (Bank.Get(addmoney += this._mother.ff_factor / 10) && pos_income > 1) {
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
    return CheckRailConnection(path_for_check);
}

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
    if (AIVehicle.IsValidVehicle(service.MainVhcID)) {
        //activated if we use existing rail
        //local number = service.SourceIsTown ? AITown.GetMaxProduction(service.Source.ID, service.Cargo) :
        //AIIndustry.GetLastMonthProduction(service.SourceID, service.Cargo);
        //number = (number / AIVehicle.GetCapacity(service.MainVhcID, service.Cargo) / 1.5).tointeger();
        Debug.ResultOf("Vehicle build", Vehicles.StartCloned(service.MainVhcID, service.SourceDepot.GetBody(), 2));
        return true;
    }

    local loco_id = -1;

    /* pick a loco */
    local locos = Vehicles.WagonEngine(0);
    locos.Valuate(AIEngine.HasPowerOnRail, service.TrackType);
    locos.KeepValue(1);
    if (Debug.ResultOf("loco found", locos.Count()) < 1) return false;
    locos = Vehicles.SortedEngines(locos);
    while (locos.Count() > 0) {
        /* due to needed to check it price in Test Mode */
        local MainEngineID = locos.Pop();
        local engine_name = AIEngine.GetName(MainEngineID);
        if (!AIEngine.CanPullCargo(MainEngineID, service.Cargo)) continue;
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
        if (AIEngine.CanRefitCargo(MainEngineID, service.Cargo)) AIVehicle.RefitVehicle(loco_id, service.Cargo);

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
        AIOrder.AppendOrder(loco_id, service.DestinationDepot.GetBody(), AIOrder.AIOF_NONE);
        AIOrder.AppendOrder(loco_id, service.SourceDepot.GetBody(), AIOrder.AIOF_NON_STOP_INTERMEDIATE);
        AIOrder.InsertConditionalOrder(loco_id, 2, 3);
        AIOrder.SetOrderCondition(loco_id, 2, AIOrder.OC_REQUIRES_SERVICE);
        AIOrder.SetOrderCompareFunction(loco_id, 2, AIOrder.CF_IS_FALSE);
        service.MainVhcID = loco_id;
        break;
    }

    if (!AIVehicle.IsValidVehicle(loco_id) && !this._mother.State.TestMode) return false;

    local loco_length = AIVehicle.GetLength(loco_id);
    local wagon_id = -1;

    /* pick a wagon */
    local wagons = Vehicles.WagonEngine();
    wagons.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
    wagons.KeepValue(1);
    if (Debug.ResultOf("wagon found", wagons.Count()) < 1) {
        AIVehicle.SellVehicle(loco_id);
        return false;
    }

    wagons = Vehicles.SortedEngines(wagons);
    while (wagons.Count() > 0) {
        local MainEngineID = wagons.Pop();
        local wagon_name = AIEngine.GetName(MainEngineID);
        if (!IsCargoFit(MainEngineID, service.Cargo)) continue;
        this._mother.State.LastCost += AIEngine.GetPrice(MainEngineID) * 6;
        if (this._mother.State.TestMode && this._mother.State.LastCost > 0) return true;
        local total_length = 0;
        local wagon_count = 0;
        local max = service.SourceStation.GetLength() * 16;
        while (total_length < max) {
            wagon_id = AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID);
            if (!AIVehicle.IsValidVehicle(wagon_id)) break;
            if (AIEngine.GetCargoType(MainEngineID) != service.Cargo) AIVehicle.RefitVehicle(wagon_id, service.Cargo);
            if (AIEngine.GetCargoType(MainEngineID) != service.Cargo) {
                AIVehicle.SellVehicle(wagon_id);
                break;
            }
            if (AIVehicle.MoveWagon(wagon_id, 0, loco_id, 0)) wagon_count++;
            total_length = Debug.ResultOf("Loco len", AIVehicle.GetLength(loco_id));
        }
        if (total_length % max != 0) AIVehicle.SellWagon(loco_id, wagon_count);
    }
    if (AIVehicle.GetLength(loco_id) > loco_length) {
        service.MainVhcID = loco_id;
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
    try {
        switch (number) {
            case 0: path = service.Path0; break;
            case 1: path = service.Path1; break;
            case 2: path = service.Path2; break;
            case 3: path = service.Path3; break;
        }
    } catch (path) {
        return false;
    }
    if (path == null || path == false) return false;
    AILog.Info("Build Signal Length=" + path.GetLength() + txt);
    local c = 0;
    while (path != null) {
        local parn = path.GetParent();
        if ((c % 2 == 0) && parn != null && (AIRail.GetSignalType(path.GetTile(), parn.GetTile()) == AIRail.SIGNALTYPE_NONE))
            if (!AIRail.BuildSignal(path.GetTile(), parn.GetTile(), AIRail.SIGNALTYPE_NORMAL)) {
                while (AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY) {
                    AIController.Sleep(5);
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
