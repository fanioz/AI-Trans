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
	 * Try to restart a vehicle in depot
	 * @param vhc_ID The ID of vehicle to handle
	 * @return true only if can restart vehicle
	 */
	function Restart(vhc_ID) {
		return Debug.Echo(
				   (AIOrder.GetOrderCount(vhc_ID) == 4) &&
				   (AIVehicle.GetReliability(vhc_ID) > 40) &&
				   (!Assist.HasBit(AIOrder.GetOrderFlags(vhc_ID, 2), AIOrder.OF_STOP_IN_DEPOT)) &&
				   (AIVehicle.GetState(vhc_ID) == AIVehicle.VS_IN_DEPOT) &&
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
		AIController.Sleep(1);
		local cur_order = AIOrder.ResolveOrderPosition(vhc_ID, AIOrder.ORDER_CURRENT);
		if (cur_order == 0) {
			if (AIVehicle.GetState(vhc_ID) == AIVehicle.VS_AT_STATION)  AIOrder.SkipToOrder(vhc_ID, 1);
		}
		local flags = AIOrder.OF_STOP_IN_DEPOT;
		if (!Assist.HasBit(AIOrder.GetOrderFlags(vhc_ID, 2), flags)) {
			if (AIOrder.SetOrderFlags(vhc_ID, 1, AIOrder.OF_NO_LOAD)) Info("loading flag set");
			//code changed due to bug reported FS#
			if (!AIMap.IsValidTile(AIOrder.GetOrderDestination(vhc_ID, 2))) flags = flags | AIOrder.OF_GOTO_NEAREST_DEPOT;
			if (AIOrder.SetOrderFlags(vhc_ID, 2, flags)) Info("depot flag set");
		}
		Info("Waiting until arrive at destination");
		return true;
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
		return Debug.Echo("Try to give command", AIVehicle.SendVehicleToDepot(vhc_ID));
	}

	/**
	 * Try to duplicate a vehicle in depot
	 * @param vhc_ID_new The vehicle ID to clone
	 * @return true if vehicle is duplicated
	 */
	function TryDuplicate(vhc_ID) {
		Info("try to duplicate");
		if (!XVehicle.IsRegistered(vhc_ID)) return false;
		local tbl = My._Vehicles[vhc_ID];
		if (AIEngine.IsBuildable(tbl.GetEngine())) {
			local vhc = AIVehicle.CloneVehicle(tbl.GetSDepot(), vhc_ID, false);
			if (AIVehicle.IsValidVehicle(vhc)) {
				Info("cloning succeed");
				XVehicle.ResetFlag(vhc);
				if (XVehicle.Restart(vhc)) return true;
			}
			Warn("starting clone failed", AIError.GetLastErrorString());
			if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
				if (!AIVehicle.IsStoppedInDepot(vhc_ID)) return false;
				if (tbl.SourceIsProducing()) XVehicle.ResetFlag(vhc_ID);
				XVehicle.Restart(vhc_ID);
			}
			XVehicle.Sell(vhc);
		}
		XVehicle.Sell(vhc_ID);
		return XVehicle.GetReplacement(tbl);
	}

	/**
	 * Reset flag orders
	*/
	function ResetFlag(vhc) {
		local flags = Assist.SetBitOff(AIOrder.GetOrderFlags(vhc, 1), AIOrder.OF_NO_LOAD);
		Debug.ResultOf(AIOrder.SetOrderFlags(vhc, 1, flags), "loading flag re-set");
		flags = Assist.SetBitOff(AIOrder.GetOrderFlags(vhc, 2), AIOrder.OF_STOP_IN_DEPOT) | AIOrder.OF_SERVICE_IF_NEEDED;
		Debug.ResultOf(AIOrder.SetOrderFlags(vhc, 2, flags), "depot flag re-set");
	}

	/**
	 * Get Replacement for vehicle
	 * @param vhc_ID Vehicle ID to select
	 * @return ID of new vehicle
	 */
	function GetReplacement (tbl) {
		local engine = tbl.GetEngine();
		local vt = tbl.GetVType();
		local vtname = CLString.VehicleType(vt);
		local engine_new = AIGroup.GetEngineReplacement (AIGroup.GROUP_ALL, engine);
		if (AIEngine.IsValidEngine(engine_new)) {
			Info("AutoReplacement for", vtname, "was set to", AIEngine.GetName(engine_new));
			return true;
		}
		Info ("try to find engine replacement for", vtname);
		local v_man = VehicleMaker (vt);
		v_man.SetCargo (tbl.GetCargo());
		if (!v_man.HaveEngineFor(tbl.GetTrack())) {
			Warn ("could'nt find an engine");
			return false;
		};
		v_man.SortEngine();
		engine_new = (vt == AIVehicle.VT_RAIL) ? v_man.GetFirstLoco() : v_man.GetFirst();
		AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine, engine_new);
		v_man.SetDepotA (tbl.GetSDepot());
		v_man.SetDepotB (tbl.GetDDepot());
		v_man.SetStationA (tbl.GetSStation());
		v_man.SetStationB (tbl.GetDStation());
		while (Debug.ResultOf (v_man.TryBuild (), "try buy engine")) {
			if (v_man.IsBuilt()) {
				Info ("New vehicle", v_man.GetVehicle());
				v_man.SetNextOrder();				
				if (XVehicle.Restart(v_man.GetVehicle())) return true;
			}
			AIVehicle.SellVehicle (v_man.GetVehicle());
		}
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
		local route = RouteSaver();
		route.Validate (vhc_id);
		if (route.IsValidRoute()) {
			//Info ("route is valid(1)");
			return true;
		}
		local orders = CLList (AIStationList_Vehicle (vhc_id));
		if (orders.Count() < 2) {
			Warn ("couldn't detect vehicle destinations");
			return false;
		}
		local id1 = orders.Begin();
		local id2 = orders.Next();
		Info ("found", AIStation.GetName (id1));
		Info ("found", AIStation.GetName (id2));
		local dest1 = AIStation.GetLocation (id1);
		local dest2 = AIStation.GetLocation (id2);
		local vt = AIVehicle.GetVehicleType (vhc_id);
		local vhc_list1 = AIVehicleList_Station (id1);
		local vhc_list2 = AIVehicleList_Station (id2);
		vhc_list1.Valuate (AIVehicle.GetVehicleType);
		vhc_list1.KeepValue (vt);
		vhc_list1.Valuate (XVehicle.IsRegistered);
		vhc_list1.KeepValue (1);
		foreach (vhc, grp in vhc_list1) {
			if (!vhc_list2.HasItem (vhc)) continue;
			Info ("found a friend:", AIVehicle.GetName (vhc));
			if (!XVehicle.CanJoinOrder (vhc_id, vhc)) continue;
			route.Validate (vhc_id);
			if (route.IsValidRoute()) {
				Info ("route is valid(2)");
				return true;
			}
		}
		//manually rebuild

		orders.Clear();
		for (local c = 0; c < AIOrder.GetOrderCount (vhc_id); c++) {
			if (AIOrder.IsGotoDepotOrder (vhc_id, c)) {
				local depot = AIOrder.GetOrderDestination (vhc_id, c);
				if (AIMap.IsValidTile(depot)) orders.AddItem (depot, AIMap.DistanceManhattan (depot, dest1));
			}
		}
		orders.SortValueAscending();
		local depot1 = orders.Count() ? orders.Pop() : -1;
		if (!AIMap.IsValidTile(depot1)) {
			depot1 = Assist.FindDepot(dest1, vt, XVehicle.GetTrack(vhc_id));
		}
		local depot2 = orders.Count() ? orders.Pop() : -1;
		if (!AIMap.IsValidTile(depot2)) {
			depot1 = Assist.FindDepot(dest2, vt, XVehicle.GetTrack(vhc_id));
		}
		local vhcman = VehicleMaker(vt);
		vhcman.SetVehicle(vhc_id);
		vhcman.SetStationA(dest1);
		vhcman.SetStationB(dest2);
		vhcman.SetMainOrder();
		vhcman.SetCargo(XCargo.OfVehicle(vhc_id));
		vhcman.SetDepotA(depot1);
		vhcman.SetDepotB(depot2);
		vhcman.SetNextOrder();
		route.Validate(vhc_id);
		if (route.IsValidRoute()) {
			Info("route is valid(3)");
			return true;
		}
		AIOrder.RemoveOrder(vhc_id, 0);
		return false;
	}

	function IsRegistered(vhc_id) { return My._Vehicles.rawin(vhc_id); }

	/**
	 * Grouping vehicle
	 * @param serv Service tabel
	 */
	function MakeGroup(vhc_id, tabel) {
		local name = tabel.GetKey();
		local vt = tabel.GetVType();
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
			grp = AIGroup.CreateGroup(vt);
			AIGroup.SetName(grp, name)
		}
		tabel._grp_id = grp;
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
 		if (!AIVehicle.IsValidVehicle(idx)) {
 			Warn(idx, "is not a valid vehicle");
 			return;
 		}
 		local tabel = {};
 		tabel.Stations <- [];
		tabel.Depots <- [];
		tabel.Waypoints <- []; ///might not needed
		for (local c=0;c<AIOrder.GetOrderCount(idx);c++) {
			local dest = AIOrder.GetOrderDestination(idx, c);
			if (AIOrder.IsGotoStationOrder(idx, c))
				tabel.Stations.push(dest);
			if (AIOrder.IsGotoDepotOrder(idx, c))
				tabel.Depots.push(dest);
			if (AIOrder.IsGotoWaypointOrder(idx, c)) 
				tabel.Waypoints.push(dest);
		}
		if (tabel.Stations.len()<1) {
			Warn(AIVehicle.GetName(idx), "stations stop less than 1");
			return;
		}
		tabel.StationsID <- clone tabel.Stations;
		for(local c=0;c<tabel.Stations.len();c++) {
			tabel.StationsID[c] = AIStation.GetStationID(tabel.Stations[c]);
			if (!AIStation.IsValidStation(tabel.StationsID[c])) {
				Warn(AIVehicle.GetName(idx), "has an invalid station");
				return;
			}
		}
		tabel.Cargo <- XCargo.OfVehicle(idx);
		tabel.IsTown <- [true, true];
		tabel.ServID <- [-1, -1];
		local src = [true, false];
		local func = [AIIndustryList_CargoProducing, AIIndustryList_CargoAccepting];
		for (local x=0;x<2;x++) {
			local list = func[x](tabel.Cargo);
			if (list.IsEmpty()) {
				//from town
				assert(XCargo.TownStd.HasItem(tabel.Cargo));
				tabel.IsTown[x] = true;
				tabel.ServID[x] = XTown.GetID(tabel.Stations[x]);
				if (!AITown.IsValidTown(tabel.ServID[x])) {
					Warn("Goto station name", AIStation.GetName(tabel.Stations[x]));
					Warn("Capture screen at tile", CLString.Tile(tabel.Stations[x]));
					//CRASH_CANT_DETECT_STATION_BELONG_TO();
					return;
				}
			} else {
				tabel.ServID[x] = XIndustry.GetID(tabel.Stations[x], src[x], tabel.Cargo);
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
						return;
					}
					tabel.IsTown[x] = true;
				}
			}
		}
		tabel.Key <- Service.CreateKey(tabel.ServID[0], tabel.ServID[1], tabel.Cargo, tabel.VhcType);
		tabel.VhcCapacity <- AIVehicle.GetCapacity(idx, tabel.Cargo);
		tabel.VhcType <- AIVehicle.GetVehicleType(idx);
 		tabel.VhcID <- idx;
 		tabel.Orders <- XVehicle.GetOrders(idx);
 		tabel.Engine <- AIVehicle.GetEngineType(idx);
		tabel.MaxSpeed <- AIEngine.GetMaxSpeed(tabel.Engine);
		tabel.StationType <- XStation.GetTipe(tabel.VhcType, tabel.Cargo);
		tabel.Track <- XVehicle.GetTrack(idx);
		return true;
 	}
}
