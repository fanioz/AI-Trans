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
		this._ignored_tiles = [];
	}
	
	/**
	 * Rail Track builder
	 * @param service class
	 * @param number the code number wich track to build
	 * @return true if the track is build
	 */
	function Track(service, number)
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
		local c = 0;
		local prev = null;
		local prevprev = null;
		while (path != null) {
			if (prevprev != null) {
				if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
					if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
						if (!AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev)) {
								/* error build tunnel */
								switch (AIError.GetLastError()) {
								    case AIError.ERR_PRECONDITION_FAILED : break;
								}
							this._ignored_tiles.push(prev);
						}
					} else {
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
										if (AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge, path.GetTile(), prev)) break;
									}
								break;
							}
							this._ignored_tiles.push(prev);
						}
					}
				} else {
					if (AIRail.BuildRail(prevprev, prev, path.GetTile())) {
						c++;
						if ((c % 4 == 1) && (AIRail.GetSignalType(prevprev, prev) == AIRail.SIGNALTYPE_NONE)) {
							AIRail.BuildSignal(prevprev, prev, AIRail.SIGNALTYPE_PBS);
						}
					} else {
						switch (AIError.GetLastError()) {
							case AIError.ERR_PRECONDITION_FAILED : break;
							case AIError.ERR_AREA_NOT_CLEAR:
								if (!Tiles.IsMine(prev) && !AIRail.IsRailTile(prev)) if (!AITile.DemolishTile(prev)) {
									this._ignored_tiles.push(prev);
									return;
								}
								if (!AIRail.BuildRail(prevprev, prev, path.GetTile())) return;                            
								break;
							case AIError.ERR_ALREADY_BUILT: break;
							case AIError.ERR_VEHICLE_IN_THE_WAY:
								local x = 50;
								while (x-- > 0) {
								    AIController.Sleep(x + 1);
								    Debug.ResultOf("Retry build rail:" + x, AIRail.BuildRail(prevprev, prev, path.GetTile()));
								    if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) break;
								    if (AIError.GetLastError() != AIError.ERR_VEHICLE_IN_THE_WAY) break;
								}
								this._ignored_tiles.push(prev);
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
	 * Rail Depot builder
	 * @param service class
	 * @param is_source to determine where to build this depot
	 * @return true if the depot can build or has been build
	 */
	function Depot(service, is_source)
	{
	    AILog.Info("Try to Build Rail Depot");
	    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
	    local money_need = AIAccounting();
	    /* find a good place */
	    local data = null;
	    local result = false;
	    local name = "", Gpos = null;
	    
	    if (is_source) {
	        name = service.Source.GetName();
	        Gpos = Generate.Pos(service.Source.GetArea(), service.Info.Source, false);
	        data = service.SourceStation.GetData();
	    } else {
	        name = service.Destination.GetName();
	        Gpos = Generate.Pos(service.Destination.GetArea(), service.Info.Destination, false);
	        data = service.DestinationStation.GetData();
	    }
	    
	    if (this._mother.State.TestMode) {
	    	while (Gpos.getstatus() == "suspended") {
		    	local pos = resume Gpos;
		        AIController.Sleep(1);
		        if (Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos.GetLocation(), pos.GetHead()))) {
		            this._mother.State.LastCost = money_need.GetCosts();
		            return true;
		        } else {
		            money_need.ResetCosts();
		            if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH)  return false;
		        }
		    }
		    return true;
	    }
	    local location = [[data.Right, data.HeadRight[1]], [data.Left, data.HeadLeft[1]]];
	    local start_pos = data.Base + data.opset; 
	    local pos =  start_pos + location[0][0];
	    local head = start_pos + location[0][1];
	    local tip = -1;
	    if (!AITile.IsBuildable(pos)) {
	        AILog.Info("default fail");
	        pos = start_pos + location[1][0];
	        head = start_pos + location[1][1];
	    }
	    local addmoney = 0;
	    local wait_time = AIVehicleList().Count() * 100 + 5;
	    //Debug.Sign(pos,"depot");
	    //Debug.Sign(head,"head");
	    result = Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos, head));
	    while (!result && Bank.Get(addmoney += TransAI.Factor10)) {
	        AIController.Sleep(wait_time);
	        result = Debug.ResultOf("Build Rail Depot at " + name, AIRail.BuildRailDepot(pos, head));
	    }
	    // build all track
	    Assist.BuildAllTrack(head);
	    local depot_path = [];
	    local exit_ = Tiles.Buildable(Tiles.Adjacent(head), 1);
	    foreach (idx, val in exit_) depot_path.push([idx, head]);
	    this._ignored_tiles.push(head);
	    if (is_source) {
	        service.Info.DepotStart = depot_path;
	        service.Info.SourceDepot = pos;
	    } else {
	        service.Info.DstDepot = pos;
	        service.Info.DepotEnd = depot_path;
	    }
	    return result;
	}

	/**
	 * Pathfinder rail
	 * @param service class
	 * @param number the code number wich path to find
	 * @param is_finding wether to only check a path of find it
	 * @return true if the path is found
	 */
	function Path(service, number, is_finding)
	{
	    local txt = (is_finding) ? " Finding:" : " Checking:" ;
	    AILog.Info("Rail Path " + number + txt);
	    local _from = [];
	    local _to = [];
	    local Finder = null;
	    local result = false;
	    local path = false;
	    
	    if (is_finding) {
	    	Finder = Route.RailFinder();
	    	Finder.cost.estimate_multiplier = 2; 
	    } else {
	        /* if we are only check is it connected, do bread first search */
	        Finder = Route.RailTracker();
	        Finder.cost.estimate_multiplier = 0;
	        return false;
	    }
	
	    switch (number) {
	        case 0:
	            local bodies = service.Source.GetArea();
	            bodies.Valuate(AITile.IsBuildable);
	            bodies.KeepValue(1);
	            bodies.Valuate(AIMap.DistanceMax, service.Info.Destination);
	            bodies.Sort(AIAbstractList.SORT_BY_VALUE, true);
	            foreach (idx, val in bodies) {
	            	if (!AIMap.IsValidTile(idx)) continue;
	                local heads = Tiles.Buildable(Tiles.Flat(Tiles.Adjacent(idx)), 1);
	                foreach (head, val in heads) {
	                	if (!AIMap.IsValidTile(head)) continue;
	                	_from.push([head, idx]);
	                	break;
	                }
	                AIController.Sleep(1);
	            }
	            bodies = service.Destination.GetArea();
	            bodies.Valuate(AITile.IsBuildable);
	            bodies.KeepValue(1);
	            bodies.Valuate(AIMap.DistanceMax, service.Info.Source);
	            bodies.Sort(AIAbstractList.SORT_BY_VALUE, true);
	            foreach (idx, val in bodies) {
	            	if (!AIMap.IsValidTile(idx)) continue;
	                local heads = Tiles.Buildable(Tiles.Flat(Tiles.Adjacent(idx)), 1);
	                foreach (head, val in heads) {
	                	if (!AIMap.IsValidTile(head)) continue;
	                	_to.push([head, idx]);
	                	break
	                }
	                AIController.Sleep(1);
	            }
	            Finder.cost.estimate_multiplier = 30;
	            break;
	        case 1:
	            _from = service.Info.StartPath;
	            _to = service.Info.EndPath;
	            break;
	        case 2:
	            _from = service.Info.DepotEnd;
	            _to = service.Info.DepotStart;
	            
	            break;
	        default : Debug.DontCallMe("Path Selection", number);
	    }
	
	    Finder.InitializePath(_from, _to, this._ignored_tiles);
	
	    local c = 0;
	    while (path == false) {
	    	Finder._max_bridge_length = max(5, c + 3);
	    	if (c % 10 == 0) Finder._estimate_multiplier ++;
	        path  = Finder.FindPath(service.Info.R_Distance);
	        AIController.Sleep(1);
	        if (Debug.ResultOf("Rail Pathfinding", c++) == 102) break;
	    }
	    result = Debug.ResultOf("Path " + txt + " stopped at "+ c, (path != null && path != false));
	    this._path_table[number] <- path;
	    return result;
	}

	
	/**
	 * Rail Vehicle builder
	 * @param service class
	 * @return false if no vehicle available/built and true if it was success
	 */
	function Vehicle(service)
	{
	    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
	    local money_need = AIAccounting();
	    local depot =  service.Info.SourceDepot;
	    this._mother.State.LastCost = 0;
	    AILog.Info("Build Rail Vehicle ");
	    if (AIVehicle.IsValidVehicle(service.Info.MainVhcID)) {
	        service.Info.VehicleNum += Debug.ResultOf("Vehicle build", Vehicles.StartCloned(service.Info.MainVhcID, depot, 2));
	        return true;
	    }
	
	    local loco_id = -1;
	
	    /* pick a loco */
	    local locos = Vehicles.RailEngine(1, service.Info.TrackType);
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
	        service.Info.LocoEngine = MainEngineID; 
	        if (this._mother.State.TestMode && this._mother.State.LastCost > 0) break;
	        local addmoney = AIEngine.GetPrice(MainEngineID);
	        local wait_time = AIVehicleList().Count() * 10 + 5;
	        loco_id = Debug.ResultOf("Try to buy " + engine_name, AIVehicle.BuildVehicle(depot, MainEngineID));
	        while (!AIVehicle.IsValidVehicle(loco_id) && Bank.Get(addmoney += TransAI.Factor10)) {
	            AIController.Sleep(wait_time);
	            loco_id = Debug.ResultOf("(retry buy " + engine_name, AIVehicle.BuildVehicle(depot, MainEngineID));
	        }
	        if (AIEngine.CanRefitCargo(MainEngineID, service.Info.Cargo)) AIVehicle.RefitVehicle(loco_id, service.Info.Cargo);
	
	        /* ordering */
	        if (!AIOrder.AppendOrder(loco_id, service.SourceStation.GetLocation(), AIOrder.AIOF_FULL_LOAD_ANY)) {
	            Debug.ResultOf("Order failed on Vehicle", AIEngine.GetName(MainEngineID));
	            AIVehicle.SellVehicle(loco_id);
	            continue;
	        }
	        if (!AIOrder.AppendOrder(loco_id, service.DestinationStation.GetLocation(), AIOrder.AIOF_NONE)) {
	            Debug.ResultOf("Order failed on Vehicle", AIEngine.GetName(MainEngineID));
	            AIVehicle.SellVehicle(loco_id);
	            continue;
	        }
	        Vehicles.SetNextOrder(loco_id, depot, service.Info.DstDepot);  	
	        service.Info.MainVhcID = loco_id;
	        break;
	    }
	
	    if (!AIVehicle.IsValidVehicle(loco_id) && !this._mother.State.TestMode) return false;
	
	    local loco_length = AIVehicle.GetLength(loco_id);
	    local wagon_id = -1;
	
	    /* pick a wagon */
	    local wagons = Vehicles.RailEngine(0, service.Info.TrackType);
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
	        service.Info.WagonEngine = MainEngineID;
	        if (this._mother.State.TestMode && this._mother.State.LastCost > 0) return true;
	        local total_length = 0;
	        local wagon_count = 0;
	        local max = service.SourceStation.GetLength() * 16;
	        while (total_length < max) {
	            wagon_id = AIVehicle.BuildVehicle(depot, MainEngineID);
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

	/**
	 * Small Rail Station builder. 1 x 3
	 * @param service class
	 * @param is_source to determine where to build this station
	 * @return true if the station can build or has been build
	 */
	function SmallStation(service, is_source)
	{
	    AILog.Info("Try to Build Rail Station " + (is_source ? "source" : "destination"));
	    local ex_test = this._mother.State.TestMode ? AITestMode() : AIExecMode();
	    local money_need = AIAccounting();
	    local validID = -1;
	    local cache = null;
	    local start_path = [];
	    local result = 0;
	    local check_fn = null, areas = null, location = null, prodacc = null;
	    local stasiun = null, name = null;
	    this._mother.State.LastCost = 0;
	    
	    if (is_source) {
	    	cache = service.SourceCacheArea.weakref();
	    	stasiun = service.SourceStation.weakref();
	    	check_fn = AITile.GetCargoProduction;
	    	name = service.Source.GetName();
	    	areas = service.Source.GetArea();
	    	location = service.Source.GetLocation();
	    	prodacc = 5;
		} else {
			cache = service.DestCacheArea.weakref() ;
			stasiun = service.DestinationStation.weakref();
	    	check_fn = AITile.GetCargoAcceptance;
	    	name = service.Destination.GetName();
	    	areas = service.Destination.GetArea();
		    location = service.Destination.GetLocation();
		    prodacc = 8;
	    }
	
	    /* if dir == NE_SW */
	    local table_NE_SW = {
	        opset = AIMap.GetTileIndex(-2, 0),
	        HeadRight = [AIMap.GetTileIndex(0, 0), AIMap.GetTileIndex(1, 0)],
	        HeadLeft = [AIMap.GetTileIndex(6, 0), AIMap.GetTileIndex(5, 0)],
	        Right = AIMap.GetTileIndex(0, 0),
	        Left = AIMap.GetTileIndex(6, 0),
	        DepotSide = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(6, 1)],
	        EndArea = AIMap.GetTileIndex(6, 1),
	        Width = 3,
	        Height = 1,
	        x = 3,
	        y = 1,
	        BuildPlatform = stasiun.ref().RailTemplateNE_SW,
	    }
	    local table_NW_SE = {
	        opset = AIMap.GetTileIndex(0, -2),
	        HeadRight = [AIMap.GetTileIndex(0, 0), AIMap.GetTileIndex(0, 1)],
	        HeadLeft = [AIMap.GetTileIndex(0, 6), AIMap.GetTileIndex(0, 5)],
	        Right = AIMap.GetTileIndex(0, 0),
	        Left = AIMap.GetTileIndex(0, 6),
	        DepotSide = [AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(1, 6)],
	        EndArea = AIMap.GetTileIndex(1, 6),
	        Width = 3,
	        Height = 1,
	        x = 1,
	        y = 3,
	        BuildPlatform = stasiun.ref().RailTemplateNW_SE,
	    }
		local _read = {};
		_read[AIRail.RAILTRACK_NW_SE] <- table_NW_SE;
		_read[AIRail.RAILTRACK_NE_SW] <- table_NE_SW;
	    
		local st_data = {};
	
	    stasiun.ref().SetWidth(1);
	    stasiun.ref().SetLength(3);
	    
	    local built_s = Tiles.StationOn(location);
	    /* check if i've one */
	    foreach (id, val in built_s) {
	    	local loc = AIStation.GetLocation(id);
	    	if (!AIRail.IsRailStationTile(loc)) continue;
	    	if (AIRail.GetRailType(loc) != service.Info.TrackType) continue;
	    	if (check_fn(loc, service.Info.Cargo, 1, 1, stasiun.ref().GetRadius()) < acceptance) continue;
	        stasiun.ref().SetID(id);
	        validID = id;
	        /* check if i really need to build other one */
	        if (stasiun.ref().GetVehicleList().Count() > 1) continue;
	    	local dir = AIRail.GetRailStationDirection(id);
	    	
			st_data = _read[stasiun.ref().GetDirection()];
			st_data.Base <- loc;
			local start_pos = loc + st_data.opset;
			stasiun.ref().SetData(st_data);
	        stasiun.ref().SetID(AIStation.GetStationID(base));
	        stasiun.ref().SetDirection(dir);
	        stasiun.ref().SetLocation(loc);
	        start_path.clear();
	        start_path.push([start_pos + st_data.HeadRight[0], start_pos + st_data.HeadRight[1]]);
	        start_path.push([start_pos + st_data.HeadLeft[0], start_pos + st_data.HeadLeft[1]]);
	        this._ignored_tiles.push(start_pos + st_data.DepotSide[0]);
	        this._ignored_tiles.push(start_pos + st_data.DepotSide[1]);
	        
			if (is_source) {
			    service.Info.SourceStation = stasiun.ref().GetID();
			    service.Info.StartPath = start_path;
			} else {
			    service.Info.EndPath = start_path;
			}
			AILog.Info("I have empty station one");
			this._mother.State.LastCost = money_need.GetCosts();
			return true;
	    }
	    
	    /* find a good place */
	    AILog.Info("find a good place");
		areas.Valuate(AITile.GetMaxHeight);
		areas.RemoveValue(0);
		areas.Valuate(AIMap.DistanceMax, location);
		areas.RemoveValue(0);
		if (cache.ref().Count()) areas = cache.ref();
		areas.Sort(AIAbstractList.SORT_BY_VALUE, true);
		if (!AIStation.IsValidStation(validID)) validID = AIStation.STATION_JOIN_ADJACENT;
		Debug.ClearErr();
		foreach (base, val in areas) {
			AIController.Sleep(1);
			if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) break;
			if (AIError.GetLastError() == AIError.ERR_LOCAL_AUTHORITY_REFUSES) break;
			if (this._mother.State.TestMode && result) break;
			foreach (dir in Const.RailStationDir) {
				money_need.ResetCosts();
				AIController.Sleep(1);
				st_data = _read[dir];
				st_data.Base <- base;
				stasiun.ref().SetData(st_data);
				money_need.ResetCosts();
				if (check_fn(base, service.Info.Cargo, st_data.x, st_data.y, stasiun.ref().GetRadius()) < prodacc) continue;
				local start_pos = base + st_data.opset;
				local t_build = stasiun.ref().CanBuild(start_pos, start_pos + st_data.EndArea);
				switch (t_build) {
					case 1 :
	            		AILog.Info("Need to Terraform first ...");
	            		cache.ref().AddItem(base, 1);
	            		if (!Tiles.MakeLevel(start_pos, start_pos + st_data.EndArea)) continue;
	            		break;
	            	case 2 : 
	            		cache.ref().AddItem(base, 0);
	            		break;
	            	default : 
	            		cache.ref().AddItem(base, 2);
	            		continue;
	        	}
	        	result = AIRail.BuildNewGRFRailStation(base, dir, stasiun.ref().GetWidth(), stasiun.ref().GetLength(),  validID,
	            	service.Info.Cargo, AIIndustry.GetIndustryType(service.Source.GetID()), AIIndustry.GetIndustryType(service.Destination.GetID()),
	            	service.Info.R_Distance, is_source);
	        	if (!result) result = AIRail.BuildRailStation(base, dir, stasiun.ref().GetWidth(), stasiun.ref().GetLength(), validID);
	        	if (Debug.ResultOf("Rail station at " + name, result)) {
	        		if (this._mother.State.TestMode) {
	            		this._mother.State.LastCost = money_need.GetCosts();
	            		if (t_build == 2) return;
	            	}
	                if (!AIRail.BuildRailTrack(start_pos + st_data.HeadRight[1], dir)) {
	                    Tiles.DemolishRect(start_pos, start_pos + st_data.EndArea);
	                    continue;
	                }
	                if (!AIRail.BuildRailTrack(start_pos + st_data.HeadLeft[1], dir)) {
	                    Tiles.DemolishRect(start_pos, start_pos + st_data.EndArea);
	                    continue;
	                }
	                stasiun.ref().SetID(AIStation.GetStationID(base));
	                stasiun.ref().SetDirection(dir);
	                stasiun.ref().SetLocation(base);
	                start_path.clear();
	                start_path.push([start_pos + st_data.HeadRight[0], start_pos + st_data.HeadRight[1]]);
	                start_path.push([start_pos + st_data.HeadLeft[0], start_pos + st_data.HeadLeft[1]]);
	                this._ignored_tiles.push(start_pos + st_data.DepotSide[0]);
	                this._ignored_tiles.push(start_pos + st_data.DepotSide[1]);
	                
					if (is_source) {
					    service.Info.SourceStation = stasiun.ref().GetID();
					    service.Info.StartPath = start_path;
					} else {
					    service.Info.EndPath = start_path;
					}
					TransAI.StationMan.New(stasiun.ref());
	                return true;
	        	}
	    	}
		}
	    AILog.Info("Not found tile anymore");
	}
}
