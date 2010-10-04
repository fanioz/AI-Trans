/*
 *      09.03.20
 *      build.road.nut
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
 * BuildingHandler.road
 * Class of Road builder
 */

class BuildingHandler.road {
  _mother = null; /// < The mother instance.

  constructor(main) {
    this._mother = main;
  }

/**
 *
 * Depot builder
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

function BuildingHandler::road::Depot(service, is_source)
{
    AILog.Info("Try to Build Depot");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local built_s = Tiles.Depot(is_source ? service.Source.Location : service.Destination.Location);
    local c_pos = Platform();
    /* check if i've one */
    foreach (pos, val in built_s) {
        if (!AIRoad.IsRoadDepotTile(pos)) continue;
        c_pos.SetBody(pos);
        c_pos.SetHead(AIRoad.GetRoadDepotFrontTile(pos));
        if (is_source) service.SourceDepot = c_pos;
        else service.DestinationDepot = c_pos;
        AILog.Info("Depot Not need as I have one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    local name = "", areas = null, location = null, is_town = false, t_location = -1;
    if (is_source) {
        c_pos = service.SourceDepot;
        name = service.Source.Name;
        areas = Tiles.Flat(service.Source.Area);
        t_location = service.Destination.Location;
        is_town = service.Source.IsTown;
    } else {
        c_pos = service.DestinationDepot;
        name = service.Destination.Name;
        areas = Tiles.Flat(service.Destination.Area);
        t_location = service.Source.Location;
        is_town = service.Destination.IsTown;
    }
    if (is_town) areas = Tiles.Roads(areas);
    local Gpos = Gen.Pos(areas, t_location);
    while (c_pos = resume Gpos) {
        AIController.Sleep(1);
        if (!this.pre_build(c_pos.GetBody(), c_pos.GetHead())) continue;
        if (Debug.ResultOf("Build Depot at " + name, AIRoad.BuildRoadDepot(c_pos.GetBody(), c_pos.GetHead()))) {
            if (is_source) service.SourceDepot = c_pos;
            else service.DestinationDepot = c_pos;
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

/* internal pre building helper */
function BuildingHandler::road::pre_build(body, head)
{
    if (Tiles.IsMine(body) || Tiles.IsMine(head)) return false;
    if (!Tiles.IsRoadBuildable(body)) if (!AITile.DemolishTile(body)) return false;
    if (!AIRoad.AreRoadTilesConnected(head, body)) {
        if (!Tiles.IsRoadBuildable(head)) return false;
        AIRoad.BuildRoad(head, body);
    }
    if (!this._mother.State.TestMode && !AIRoad.AreRoadTilesConnected(head, body)) return false;
    return true;
}

function BuildingHandler::road::Station(service, is_source)
{
    AILog.Info("Try to Build Station");
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local c_pos = Stations();
    local prod_accept = false;
    local validID = -1;
    local built_s = Tiles.StationOn(is_source ? service.Source.Location : service.Destination.Location);
    local check_fn = is_source ? AITile.GetCargoProduction : AITile.GetCargoAcceptance ;
    built_s.Valuate(check_fn, service.Cargo, 1, 1, Stations.RoadRadius());
    built_s.KeepAboveValue(6);
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
        } else {
            service.DestinationStation = c_pos;
        }
        AILog.Info("I have empty station one");
        this._mother.State.LastCost = money_need.GetCosts();
        return true;
    }
    /* find a good place */
    local pos = null, name = "", areas = null, location = null, is_town = false;
    if (is_source) {
        //pos = service.SourceStation;
        name = service.Source.Name;
        areas = service.Source.Area;
        location = service.Source.Location;
        is_town = service.Source.IsTown;
    } else {
        //pos = service.DestinationStation;
        name = service.Destination.Name;
        areas = service.Destination.Area;
        location = service.Destination.Location;
        is_town = service.Destination.IsTown;
    }
    if (is_town) areas = Tiles.Flat(Tiles.Roads(areas));
    local Gpos = Gen.Pos(areas, location);
    if (!AIStation.IsValidStation(validID)) validID = 0;
    while (pos = resume Gpos) {
        AIController.Sleep(1);
        //AIStation.IsValidStation(c_pos.ID) ? c_pos.ID :
        //Debug.Sign(pos.GetBody(), "B");
        //Debug.Sign(pos.GetHead(), "H");
        if (check_fn(pos.GetBody(), service.Cargo, 1, 1, Stations.RoadRadius()) < 7) continue;
        if (!this.pre_build(pos.GetBody(), pos.GetHead())) continue;
        local result = AIRoad.BuildRoadStation(pos.GetBody(), pos.GetHead(), Stations.RoadFor(service.Cargo), AIStation.STATION_JOIN_ADJACENT || validID);
        if (Debug.ResultOf("Road station at " + name, result)) {
            if (!this._mother.State.TestMode) {
                local posID =AIStation.GetStationID(pos.GetBody());
                if (!AIStation.IsValidStation(posID)) continue;
                local result = Stations();
                result.SetPlatform(0, pos);
                result.SetID(posID);
                if (is_source) service.SourceStation = result;
                else service.DestinationStation  = result;
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
        }
    }
    return false;
}

function BuildingHandler::road::Path(service, number, is_finding = false)
{
    local txt = (is_finding) ? " Finding:" : " Checking:" ;
    AILog.Info("Path " + number + txt);
    local _from = [];
    local _to = [];
    local Finder = RoadPF();
    local distance = 0;
    local result = false;
    local path = false;
    local ignored_tiles = [];
    if (is_finding) {
        ignored_tiles = Tiles.ToIgnore();
        ignored_tiles.push(service.SourceStation.GetPlatform(0).GetBody());
        ignored_tiles.push(service.DestinationStation.GetPlatform(0).GetBody());
        ignored_tiles.push(service.SourceDepot.GetBody());
        ignored_tiles.push(service.DestinationDepot.GetBody());
    }

    local tile_cost = Finder.cost.tile;
    //Finder.cost.max_cost = distance * tile_cost * 10;
    //Finder.cost.no_existing_road = 2 * tile_cost;
    //Finder.cost.tile = 0.2 * tile_cost;
    Finder.cost.turn = 3 * tile_cost;
    Finder.cost.slope = 2 * tile_cost;
    Finder.cost.bridge_per_tile = 6 * tile_cost;
    Finder.cost.tunnel_per_tile = 10 * tile_cost;
    Finder.cost.coast = 4 * tile_cost;
    Finder.cost.crossing = 12 * tile_cost;
    //Finder.cost.NonFreeTile = 5 * tile_cost; //un implemented custom cost huh?
    Finder.cost.allow_demolition = true;
    Finder.cost.demolition = 12 * tile_cost;
    Finder.cost.max_bridge_length = 100;
    Finder.RegisterCostCallback(Assist.RoadDiscount);

    switch (number) {
        case 0:
            //foreach (tile, val in service.Source.Area) Debug.Sign(tile, "s");
            //foreach (tile, val in service.Destination.Area) _to.push(tile);
            _from = Assist.ListToArray(Tiles.Flat(service.Source.Area));
            _to = Assist.ListToArray(Tiles.Flat(service.Destination.Area));
            Finder.cost.estimate_multiplier = 3;
            //if (is_finding) path = service.Path0;
            break;
        case 1:
            _from.push(service.SourceDepot.GetHead());
            _to.push(service.SourceStation.GetPlatform(0).GetHead());
            //Finder.cost.estimate_multiplier = 1;
            //if (is_finding) path = service.Path1;
            break;
        case 2:
            _from.push(service.DestinationStation.GetPlatform(0).GetHead());
            _to.push(service.DestinationDepot.GetHead());
            //Finder.cost.estimate_multiplier = 1;
            //if (is_finding) path = service.Path2;
            break;
        case 3:
            _from.push(service.DestinationStation.GetPlatform(0).GetHead());
            _from.push(service.DestinationDepot.GetHead());
            _to.push(service.SourceDepot.GetHead());
            _to.push(service.SourceStation.GetPlatform(0).GetHead());
            Finder.cost.estimate_multiplier = 1.5;
            //if (is_finding) path = service.Path3;
            break;
        default : Debug.DontCallMe("Path Selection");
    }

    if (service.IsSubsidy) Finder.cost.estimate_multiplier = 2;

    /* if we are only check is it connected, do bread first search */
    if (!is_finding) {
        Finder.cost.estimate_multiplier = 0;
        Finder.cost.no_existing_road = Finder.cost.max_cost;
    }
    try {
        distance = Debug.ResultOf("Distance",1 + AIMap.DistanceManhattan(_from.top(), _to.top()));
        Finder.InitializePath(_from, _to, ignored_tiles);
    } catch (distance) {
        AILog.Warning("source:" + service.Source.Area.Count());
        AILog.Warning("dest:" + service.Destination.Area.Count());
        AILog.Warning("service:" + service.Readable);
        return false;
    }

    local c =   150;
    while (path == false && c-- > 0) {
        AIController.Sleep(1);
        path  = Finder.FindPath(distance);
    }
    result = Debug.ResultOf("Path " + txt + " stopped at "+ c, (path != null && path != false));
    switch (number) {
        case 0:   service.Path0 <- path; break;
        case 1: service.Path1 <- path; break;
        case 2: service.Path2 <- path; break;
        case 3: service.Path3 <- path; break;
    }
    return result;
}

function BuildingHandler::road::Track(service, number)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    local txt = (this._mother.State.TestMode) ? " (Test)" :" (Real)" ;
    local path = null;
    switch (number) {
        case 0: path = service.Path0; break;
        case 1: path = service.Path1; break;
        case 2: path = service.Path2; break;
        case 3: path = service.Path3; break;
    }
    if (path == null || path == false) return false;
    AILog.Info("Build Track Length=" + path.GetLength() + txt);
    while (path != null) {
        local parn = path.GetParent();
        if (parn != null) {
            //local last_node = path.GetTile();
            if (!Tiles.IsRoadBuildable(parn.GetTile()) && !Tiles.IsMine(parn.GetTile())) AITile.DemolishTile(parn.GetTile());
            if (AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) == 1 ) {
                if (!AIRoad.BuildRoad(path.GetTile(), parn.GetTile())) {
                    // An error occured while building a piece of road. TODO: handle some.
                    switch (AIError.GetLastError()) {
                        case AIError.ERR_AREA_NOT_CLEAR:
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
                            break;
                        case AIError.ERR_NOT_ENOUGH_CASH:
                            local addmoney = 0;
                            local pos_income = AIVehicleList().Count();
                            local wait_time = pos_income * 20 + 5;
                            while (Bank.Get(addmoney += this._mother.ff_factor / 10) && pos_income > 1) {
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
                            } else {
                                local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), parn.GetTile()) + 1);
                                bridge_list.Valuate(AIBridge.GetMaxSpeed);
                                bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);

                                if (Debug.ResultOf("Bridge error", !AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), parn.GetTile()))) {
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
                                            Debug.ResultOf("Unhandled error build bridge/tunnel", null);
                                            //Debug.DontCallMe("Bridge");
                                            break;
                                    }
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

function BuildingHandler::road::Vehicle(service)
{
    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
    local money_need = AIAccounting();
    this._mother.State.LastCost = 0;
    AILog.Info("Build Vehicle ");
    if (AIVehicle.IsValidVehicle(service.MainVhcID)) {
        //local number = service.SourceIsTown ? AITown.GetMaxProduction(service.Source.ID, service.Cargo) :
        //AIIndustry.GetLastMonthProduction(service.SourceID, service.Cargo);
        //number = (number / AIVehicle.GetCapacity(service.MainVhcID, service.Cargo) / 1.5).tointeger();
        Debug.ResultOf("Vehicle build", Vehicles.StartCloned(service.MainVhcID, service.SourceDepot.GetBody(), 2));
        return true;
    } else {
        local myVhc = null;
        local engines = Vehicles.RVEngine(service.TrackType);
        engines.Valuate(IsCargoFit, service.Cargo);
        engines.KeepValue(1);
        engines = Vehicles.SortedEngines(engines);
        while (Debug.ResultOf("engine found", engines.Count()) > 0) {
            local MainEngineID = engines.Pop();
            local name = Debug.ResultOf("RV name", AIEngine.GetName(MainEngineID));
            /* due to needed to check it price in Test Mode */
            this._mother.State.LastCost  = AIEngine.GetPrice(MainEngineID) * 2;
            if (this._mother.State.TestMode && this._mother.State.LastCost > 0) return true;
            /* and don't care with Exec Mode */
            if (AIEngine.GetCargoType(MainEngineID) == service.Cargo) {
                myVhc = AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID);
            } else {
                if (!AIEngine.CanRefitCargo(MainEngineID, service.Cargo)) continue;
                myVhc = AIVehicle.BuildVehicle(service.SourceDepot.GetBody(), MainEngineID);
                AIVehicle.RefitVehicle(myVhc, service.Cargo);
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
            AIOrder.AppendOrder(myVhc, service.DestinationDepot.GetBody(), AIOrder.AIOF_NONE);
            AIOrder.AppendOrder(myVhc, service.SourceDepot.GetBody(), AIOrder.AIOF_NONE);
            //AIOrder.InsertConditionalOrder(myVhc, 1, 0);
            //AIOrder.SetOrderCondition(myVhc, 1, AIOrder.OC_LOAD_PERCENTAGE);
            //AIOrder.SetOrderCompareFunction(myVhc, 1, AIOrder.CF_LESS_THAN);
            //AIOrder.SetOrderCompareValue(myVhc, 1, load_num);
            AIOrder.InsertConditionalOrder(myVhc, 2, 3);
            AIOrder.SetOrderCondition(myVhc, 2, AIOrder.OC_REQUIRES_SERVICE);
            AIOrder.SetOrderCompareFunction(myVhc, 2, AIOrder.CF_IS_FALSE);
            service.MainVhcID = myVhc;
            this._mother.State.LastCost += money_need.GetCosts();
            return true;
        }
    }
    return false;
}
