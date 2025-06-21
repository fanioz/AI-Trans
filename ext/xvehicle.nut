/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2013 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XVehicle class
 * an AIVehicle eXtension
 */
class XVehicle
{
	function MaxSpeed(vhc_ID) {
		local eng = AIVehicle.GetEngineType(vhc_ID);
		return AIEngine.GetMaxSpeed(eng);
	}

	function IsLowSpeed(vhc_ID) {
		return XVehicle.MaxSpeed(vhc_ID) > AIVehicle.GetCurrentSpeed(vhc_ID) * 2;
	}

	function Ungroup(vhc_ID) {
		if (XVehicle.IsRegistered(vhc_ID)) My._Vehicles.rawdelete(vhc_ID);
		return AIGroup.MoveVehicle(0xFFFE, vhc_ID);
	}
	/**
	 * Thumb rule to calculate how many vehicle need yearly
	 * @param ppm prod.per.month
	 * @param dt days to round-trip
	 * @return number (mult by 2 if not pax)
	 */
	function Needed(ppm, capacity, dt) {
		return (ppm * dt / capacity / 30.4375).tointeger();
	}

	/**
	 * Valuator for number of vehicle belong to group
	 * @param grp_id Group ID of vehicle
	 */
	function GroupCount(grp_id) {
		return AIVehicleList_Group(grp_id).Count();
	}

	/**
	 * Valuator for distance of vehicle is below radius ?
	 */
	function DistanceMax(vhc_ID, tile, radius) {
		return AIMap.DistanceMax(AIVehicle.GetLocation(vhc_ID), tile) < radius;
	}

	/**
	 * Try to run a stopped vehicle in depot
	 * @param vhc_ID The ID of vehicle to handle
	 * @return true only if can run vehicle
	 */
	function Run(vhc_ID) {
		return Debug.ResultOf((AIVehicle.GetState(vhc_ID) == AIVehicle.VS_IN_DEPOT) && 
			AIVehicle.StartStopVehicle(vhc_ID), "(re)Starting vehicle");
	}

	/**
	 * Try to send vehicle to depot
	 * @param vhc_ID The ID of vehicle to handle
	 * @return false if can't sell right now, true if can send to depot or already there
	 */
	function TryToSend(vhc_ID) {
		Info("Try To Send");
		if (!::XVehicle.IsRegistered(vhc_ID)) return XVehicle.IsSendToDepot(vhc_ID);
		local flagset = false;
		for (local c = 0; c < AIOrder.GetOrderCount(vhc_ID); c++) {
			local dest = AIOrder.GetOrderDestination(vhc_ID, c);
			if (AIOrder.IsGotoStationOrder(vhc_ID, c)) {
				if (Assist.HasBit(AIOrder.GetOrderFlags(vhc_ID, c), AIOrder.OF_NO_LOAD)) {
					Info("no_loading flag was set");
				} else {
					if (AIVehicle.GetState(vhc_ID) == AIVehicle.VS_AT_STATION)
						Debug.ResultOf(AIOrder.SetOrderFlags(vhc_ID, c, AIOrder.OF_NO_LOAD), "setting no_loading flag");
				}
			}
			if (AIOrder.IsGotoDepotOrder(vhc_ID, c)) {
				if (Assist.HasBit(AIOrder.GetOrderFlags(vhc_ID, c), AIOrder.OF_STOP_IN_DEPOT)) {
					Info("Stop_in_depot was set");
					flagset = true;
				} else {
					local flags = AIOrder.OF_STOP_IN_DEPOT;
					if (!AIMap.IsValidTile(dest)) flags = flags | AIOrder.OF_GOTO_NEAREST_DEPOT;	
					flagset = Debug.ResultOf(AIOrder.SetOrderFlags(vhc_ID, c, flags), "setting stop_in_depot flag");
				}
			}
		}
		if (!flagset) 
			flagset = Debug.ResultOf(AIOrder.AppendOrder(vhc_ID, -1, AIOrder.OF_STOP_IN_DEPOT | AIOrder.OF_GOTO_NEAREST_DEPOT), "Add new stop_in_depot");
		if (!flagset) flagset = XVehicle.IsSendToDepot(vhc_ID);
		Info("Waiting until arrive at depot:", flagset);
		return flagset;
	}

	/**
	 * simplified is type of vehicle
	 */
	function IsTrain(vhc_ID) {
		return AIVehicle.GetVehicleType(vhc_ID) == AIVehicle.VT_RAIL;
	}

	function IsRoad(vhc_ID) {
		return AIVehicle.GetVehicleType(vhc_ID) == AIVehicle.VT_ROAD;
	}

	function IsAircraft(vhc_ID) {
		return AIVehicle.GetVehicleType(vhc_ID) == AIVehicle.VT_AIR;
	}

	function IsShip(vhc_ID) {
		return AIVehicle.GetVehicleType(vhc_ID) == AIVehicle.VT_WATER;
	}

	/**
	 * Sell completely
	 */
	function Sell(vhc_ID) {
		if (!AIVehicle.IsStoppedInDepot(vhc_ID)) return false;
		if (XVehicle.IsTrain(vhc_ID)) AIVehicle.SellWagonChain(vhc_ID, 0);
		return AIVehicle.SellVehicle(vhc_ID);
	}

	/**
	 * Can Send vehicle to depot ?
	 * - Give a try to send vehicle to depot
	 * @param vhc_ID The ID of vehicle to handle
	 * @return true if vehicle has been sent to depot
	 */
	function IsSendToDepot(vhc_ID) {
		if (AIVehicle.IsStoppedInDepot(vhc_ID)) {
			Info("Already stopped in");
			return true;
		}
		if (AIOrder.IsGotoDepotOrder(vhc_ID, AIOrder.ORDER_CURRENT) &&
				Assist.HasBit(AIOrder.GetOrderFlags(vhc_ID, AIOrder.ORDER_CURRENT), AIOrder.OF_STOP_IN_DEPOT)) {
			Info("Already sent to depot");
			return true;
		}
		if (::XVehicle.IsRoad(vhc_ID) && XVehicle.IsLowSpeed(vhc_ID)) {
			Info("Try to reverse");
			AIVehicle.ReverseVehicle(vhc_ID);
		}
		return Debug.Echo(AIVehicle.SendVehicleToDepot(vhc_ID), "Try to give command");
	}

	/**
	 * Try to duplicate a vehicle in depot
	 * @param vhc_ID_new The vehicle ID to clone
	 * @return true if vehicle is duplicated
	 */
	function TryDuplicate(vhc_ID) {
		Info("try to duplicate");
		if (!XVehicle.IsRegistered(vhc_ID)) return false;
		local key = My._Vehicles[vhc_ID];
		local tbl = Service.Data.Routes[key];
		if (AIEngine.IsBuildable(tbl.Engine)) {
			local vhc = AIVehicle.CloneVehicle(tbl.Depots[0], vhc_ID, false);
			if (AIVehicle.IsValidVehicle(vhc)) {
				Info("cloning succeed");
				XVehicle.ResetFlag(vhc);
				if (XVehicle.Run(vhc)) return true;
			}
			Warn("starting clone failed", AIError.GetLastErrorString());
			if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
				if (!AIVehicle.IsStoppedInDepot(vhc_ID)) return false;
				if (Service.SourceIsProducing(tbl)) XVehicle.ResetFlag(vhc_ID);
				XVehicle.Run(vhc_ID);
			}
			XVehicle.Sell(vhc);
		}
		XVehicle.Sell(vhc_ID);
		return XVehicle.GetReplacement(key);
	}

	/**
	 * Reset flag orders
	*/
	function ResetFlag(vhc) {
		for (local c = 0; c < AIOrder.GetOrderCount(vhc); c++) {
			if (AIOrder.IsGotoStationOrder(vhc, c)) {
				local flags = Assist.SetBitOff(AIOrder.GetOrderFlags(vhc, c), AIOrder.OF_NO_LOAD);
				Debug.ResultOf(AIOrder.SetOrderFlags(vhc, c, flags), "loading flag re-set");
				break;
			}
		}
		for (local c = 0; c < AIOrder.GetOrderCount(vhc); c++) {
			if (AIOrder.IsGotoDepotOrder(vhc, c)) {
				local flags = Assist.SetBitOff(AIOrder.GetOrderFlags(vhc, c), AIOrder.OF_STOP_IN_DEPOT) | AIOrder.OF_SERVICE_IF_NEEDED;
				Debug.ResultOf(AIOrder.SetOrderFlags(vhc, c, flags), "depot flag re-set");
			}
		}
	}

	/**
	 * Get Replacement for vehicle
	 * @param vhc_ID Vehicle ID to select
	 * @return ID of new vehicle
	 */
	function GetReplacement (key) {
		local tbl = Service.Data.Routes[key];
		local engine = tbl.Engine;
		local vt = tbl.VhcType;
		local vtname = CLString.VehicleType(vt);
		local engine_new = AIGroup.GetEngineReplacement (AIGroup.GROUP_ALL, engine);
		Info ("try to find engine replacement for", vtname);
		local v_man = VehicleMaker (vt);
		v_man.SetCargo (tbl.Cargo);
		if (!v_man.HaveEngineFor(tbl.Track)) {
			Warn ("could'nt find an engine");
			return false;
		};
		v_man.SortEngine();
		engine_new = (vt == AIVehicle.VT_RAIL) ? v_man.GetFirstLoco() : v_man.GetFirst();
		if (AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine, engine_new)) {
			Info("AutoReplacement for", vtname, "was set to", AIEngine.GetName(engine_new));
		}
		v_man.SetDepotA (tbl.Depots[0]);
		if (tbl.Depots.len()>1) v_man.SetDepotB (tbl.Depots[1]);
		v_man.SetStationA (tbl.Stations[0]);
		v_man.SetStationB (tbl.Stations[1]);
		Money.Get(0);
		if (vt == AIVehicle.VT_RAIL) {
			v_man.TryBuildRail();
		} else {
			v_man.TryBuild();
		}
		//while (Debug.ResultOf (v_man.TryBuild (), "try buy engine")) {
			if (v_man.IsBuilt()) {
				Info ("New vehicle", v_man.GetVehicle());
				if (XVehicle.Run(v_man.GetVehicle())) return true;
			}
			AIVehicle.SellVehicle (v_man.GetVehicle());
		//}
		Info ("failed on build vehicle");
		return false;
	}

	function CanJoinOrder (new_v, old_v) {
		/* ordering */
		if (! (AIVehicle.IsValidVehicle (new_v) && AIVehicle.IsValidVehicle (old_v))) return false;
		while (AIOrder.GetOrderCount (new_v)) AIOrder.RemoveOrder (new_v, 0);
		return AIOrder.CopyOrders (new_v, old_v);
	}

	function Register (vhc_id) {
		local route = XVehicle.ReadRoute(vhc_id);
		if (route.IsValid) {
			My._Vehicles[route.VhcID] <- route.Key;
			Service.Data.Routes.rawset(route.Key, route);
			return true;
		}
		return false;
	}

	function IsRegistered(vhc_id) { return My._Vehicles.rawin(vhc_id) && Service.Data.Routes.rawin(My._Vehicles[vhc_id]); }

	/**
	 * Grouping vehicle
	 * @param serv Service tabel
	 */
	function MakeGroup(vhc_id, name) {
		local vt = AIVehicle.GetVehicleType(vhc_id);
		local grp = -1;
		local grp_list = AIGroupList();
		grp_list.Valuate(AIGroup.GetVehicleType);
		grp_list.KeepValue(vt);
		foreach(idx, val in grp_list) {
			if (AIGroup.GetName(idx) == name) {
				if (AIVehicle.GetGroupID(vhc_id) == idx) return true;
				grp = idx;
				break;
			}
		}
		if (!AIGroup.IsValidGroup(grp)) {
			grp = AIGroup.CreateGroup(vt, AIGroup.GROUP_INVALID);
			AIGroup.SetName(grp, name)
		}
		Service.Data.Routes[name].GroupID = grp;
		return AIGroup.MoveVehicle(grp, vhc_id);
	}

	/**
	 * Get current track type of vehicle
	*/
	function GetTrack(vhc_id) {
		if (XVehicle.IsRoad(vhc_id)) return AIVehicle.GetRoadType(vhc_id);
		if (XVehicle.IsShip(vhc_id)) return 1;
		return XEngine.GetTrack(AIVehicle.GetEngineType(vhc_id));
	}
	
	/**
	* Get orders of vehicle in array
	* structure
	Stations = [{tile, pos},{tile, pos}]
	Depots = [[tile, pos],[tile, pos]]
	Waypoints = [[tile, pos],[tile, pos],..]
	StopLocations = [[stop, pos],..]
	Flags = [[flags, pos],..]
	Conditional =[
	{	conditional = pos
		jumpTo = tile
		condition = condition
		cmpFunction = function
		cmpValue = value
	}]
	*/
	function GetOrders(vhc_id) {
		local t = { Stations = [], Depots = [], Waypoints = [], StopLocations = [], Flags = [], Conditional =[]};
		for (local c = 0; c < AIOrder.GetOrderCount(vhc_id); c++) {
			local dest = {Tile = AIOrder.GetOrderDestination(vhc_id, c), Pos = c};
			if (AIOrder.IsGotoStationOrder(vhc_id, c)) {
				t.Stations.push(dest);
				t.StopLocations.push({Stop = AIOrder.GetStopLocation(vhc_id, c), Pos = c});
				//Info("station pos:", dest.Pos, "dest:", dest.Tile, "flags:", AIOrder.GetOrderFlags(vhc_id, c));
			}
			if (AIOrder.IsGotoDepotOrder(vhc_id, c)) {
				t.Depots.push(dest);
			}
			if (AIOrder.IsGotoWaypointOrder(vhc_id, c)) {
				t.Waypoints.push(dest);
			}
			t.Flags.push({Flags = AIOrder.GetOrderFlags(vhc_id, c), Pos = c });
			if (AIOrder.IsConditionalOrder(vhc_id, c)) {
				t.Conditional.push({ Pos = c,
					JumpTo = AIOrder.GetOrderJumpTo(vhc_id, c),
					Condition = AIOrder.GetOrderCondition(vhc_id, c),
					CmpFunction = AIOrder.GetOrderCompareFunction(vhc_id, c),
					CmpValue = AIOrder.GetOrderCompareValue(vhc_id, c)
				});
			}
		}
		t.Total <- AIOrder.GetOrderCount(vhc_id);
		return t;
	}
	/**
	* @param orders use orders returned from GetOrders()
	*/
	function SetOrders(vhc_id, orders) {
		local conditionalOrd = [];
		local neworder = array(orders.Total, {});
		//new pos
		while (orders.Stations.len() > 0) {
			local item = orders.Stations.pop();
			neworder[item.Pos] = { Tile = item.Tile};
			//Info("station pos:", item.Pos, "tile:", item.Tile);
		}
		while (orders.Depots.len() > 0) {
			local item = orders.Depots.pop();
			neworder[item.Pos] = { Tile = item.Tile};
			//Info("depot pos:", item.Pos, "tile:", item.Tile);
		}
		while (orders.Waypoints.len() > 0) {
			local item = orders.Waypoints.pop();
			neworder[item.Pos] = { Tile = item.Tile};
			//Info("wp pos:", item.Pos, "tile:", item.Tile);
		}
		while (orders.Conditional.len() > 0) {
			local item = orders.Conditional.pop();
			neworder[item.Pos] = {
				conditional = item.Pos,
				jumpTo = item.JumpTo,
				condition = item.Condition,
				cmpFunction = item.CmpFunction,
				cmpValue = item.CmpValue
			};
		}
		//existing pos
		while (orders.StopLocations.len() > 0) {
			local item = orders.StopLocations.pop();
			neworder[item.Pos].stopLocation <- item.Stop;
		}
		while (orders.Flags.len() > 0) {
			local item = orders.Flags.pop();
			neworder[item.Pos].flags <- item.Flags;
			//Info("flag pos:", item.Pos, "flag:", item.Flags);
		}
		
		AIController.Sleep(1);
		while(AIOrder.GetOrderCount(vhc_id) > 0) AIOrder.RemoveOrder(vhc_id, 0);
		while (neworder.len() > 0) {
			local t = neworder.pop();
			if (t.rawin("conditional")) {
				conditionalOrd.push(t);
				continue;
			}
			local dest = -1;
			local flags = AIOrder.OF_NONE;
			if (t.rawin("Tile")) dest = t.Tile;
			if (t.rawin("flags")) flags = t.flags;
			//Info("Setting dest:", dest, "flags:", flags);
			//Debug.Echo(AIOrder.AreOrderFlagsValid(dest, flags),"flag valid");
			Debug.Echo(AIOrder.InsertOrder(vhc_id, 0, dest, flags),"re-Setting order");
			if (t.rawin("stopLocation")) AIOrder.SetStopLocation(vhc_id, 0, t.stopLocation);
		}
		
		while (conditionalOrd.len() > 0) {
			local t = conditionalOrd.pop();
			AIOrder.InsertConditionalOrder(vhc_id, t.conditional, t.jumpTo);
			AIOrder.SetOrderCondition(vhc_id, t.conditional, t.condition);
			AIOrder.SetOrderCompareFunction(vhc_id, t.conditional, t.cmpFunction);
			AIOrder.SetOrderCompareValue(vhc_id, t.conditional, t.cmpValue);
		}
	}
	
	/**
	Read route from a vehicle
	@return true if route is readable
	*/
	function ReadRoute(idx) {
 		local tabel = Service.NewRoute();
 		if (!AIVehicle.IsValidVehicle(idx)) {
 			Warn(idx, "is not a valid vehicle");
 			return tabel;
 		}
 		tabel.VhcID = idx;
		tabel.Cargo = XCargo.OfVehicle(idx);
		tabel.VhcType = AIVehicle.GetVehicleType(idx);
		tabel.StationType = XStation.GetTipe(tabel.VhcType, tabel.Cargo);
		tabel.VhcCapacity = AIVehicle.GetCapacity(idx, tabel.Cargo);
 		tabel.Engine = AIVehicle.GetEngineType(idx);
		tabel.MaxSpeed = AIEngine.GetMaxSpeed(tabel.Engine);
		tabel.Track = XVehicle.GetTrack(idx);
		tabel.GroupID = AIVehicle.GetGroupID(idx);
		
		for (local c=0;c<AIOrder.GetOrderCount(idx);c++) {
			local dest = AIOrder.GetOrderDestination(idx, c);
			if (AIOrder.IsGotoStationOrder(idx, c))
				tabel.Stations.push(dest);
			if (AIOrder.IsGotoDepotOrder(idx, c))
				tabel.Depots.insert(0, dest);
			if (AIOrder.IsGotoWaypointOrder(idx, c)) 
				tabel.Waypoints.push(dest);
		}
		if (tabel.Stations.len()<1) {
			Warn(AIVehicle.GetName(idx), "stations stop less than 1");
			return tabel;
		}
		tabel.StationsID = clone tabel.Stations;
		for(local c=0;c<tabel.Stations.len();c++) {
			tabel.StationsID[c] = AIStation.GetStationID(tabel.Stations[c]);
			if (!AIStation.IsValidStation(tabel.StationsID[c])) {
				Warn(AIVehicle.GetName(idx), "has an invalid station");
				return tabel;
			}
		}
		tabel.Key = Service.CreateKey(tabel.StationsID[0], tabel.StationsID[1], tabel.Cargo, tabel.VhcType, tabel.Track);
		
		if (Service.Data.Routes.rawin(tabel.Key)) {
			Service.Data.Routes[tabel.Key].VhcID = tabel.VhcID;
			Service.Data.Routes[tabel.Key].VhcCapacity = max(Service.Data.Routes[tabel.Key].VhcCapacity, tabel.VhcCapacity);
			if (AIEngine.GetDesignDate(Service.Data.Routes[tabel.Key].Engine) < AIEngine.GetDesignDate(tabel.Engine)) {
				AIGroup.SetAutoReplace(Service.Data.Routes[tabel.Key].GroupID, Service.Data.Routes[tabel.Key].Engine, tabel.Engine);
				Service.Data.Routes[tabel.Key].Engine = tabel.Engine;
				Service.Data.Routes[tabel.Key].MaxSpeed = tabel.MaxSpeed;
			}
			return Service.Data.Routes[tabel.Key];
		}
		
		local src = [true, false];
		local func = [AIIndustryList_CargoProducing, AIIndustryList_CargoAccepting];
		for (local x=0;x<2;x++) {
			local list = func[x](tabel.Cargo);
			if (list.IsEmpty()) {
				// This means no industry produces/accepts this cargo.
				// Before we assume it's a town cargo, we must verify it.
				
				if (!XCargo.TownStd.HasItem(tabel.Cargo) && !XCargo.TownEffect.HasItem(tabel.Cargo)) {
					// This is an industrial cargo, but its source/destination industry might be disappeared.So it is no longer valid.
					Error("Could not find an industry for cargo '" , XCargo.Label[tabel.Cargo], "'. The industry may have closed. Marking route as invalid.");
					return tabel;
				}
				tabel.IsTown[x] = true;
				tabel.ServID[x] = XTown.GetID(tabel.Stations[x]);
				if (!AITown.IsValidTown(tabel.ServID[x])) {
					Warn("Goto station name", AIStation.GetName(tabel.StationsID[x]));
					Warn("Capture screen at tile", CLString.Tile(tabel.Stations[x]));
					//CRASH_CANT_DETECT_STATION_BELONG_TO();
					return tabel;
				}
			} else {
				tabel.ServID[x] = XIndustry.GetID(AITileList_StationType(tabel.StationsID[x],tabel.StationType), src[x], tabel.Cargo);
				if (AIIndustry.IsValidIndustry(tabel.ServID[x])) {
					//from industry
					tabel.IsTown[x] = false;
				} else {
					//might be town
					if (XCargo.TownStd.HasItem(tabel.Cargo)) {
						tabel.ServID[x] = XTown.GetID(tabel.Stations[x]);
					} else {
						tabel.ServID[x] = -1;
					}
					if (!AITown.IsValidTown(tabel.ServID[x])) {
						//not both
						Warn("Goto station name", AIStation.GetName(tabel.StationsID[x]));
						Warn("Capture screen at tile", CLString.Tile(tabel.Stations[x]));
						//CRASH_CANT_DETECT_STATION_BELONG_TO();
						return tabel;
					}
					tabel.IsTown[x] = true;
				}
			}
		}
 		if (tabel.Depots.len()==0) {
			tabel.Depots.push(Assist.FindDepot(tabel.Stations[0], 20, tabel.VhcType, tabel.Track));
		}
		if (tabel.Depots.len()==1) {
			tabel.Depots.push(-1);
		}
		tabel.LastBuild = AIDate.GetCurrentDate() - AIVehicle.GetAge(idx);
		tabel.IsValid = true;
		return tabel;
 	}
 	
 	function GetStationType(idx) {
 		local vhcType = AIVehicle.GetVehicleType(idx);
 		local cargo = XCargo.OfVehicle(idx);
		return XStation.GetTipe(vhcType, cargo);
 	}
}
