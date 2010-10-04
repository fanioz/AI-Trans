/*  09.04.12 vehicles.nut
 *
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
 *  Vehicle related static functions
 */
class Vehicles
{
	/**
	 * Try to send vehicle to depot
	 * @param vhc_ID The ID of vehicle to handle
	 * @return false if can't sell right now, true if can send to depot or already there
	 */
	static function TryToSend(vhc_ID)
	{
		if (!Debug.ResultOf("Vehicle try to send is valid", AIVehicle.IsValidVehicle(vhc_ID))) return;
		local name = Debug.ResultOf("It named", AIVehicle.GetName(vhc_ID));
        /*
        VS_RUNNING  The vehicle is currently running.
        VS_STOPPED  The vehicle is stopped manually.
        VS_IN_DEPOT     The vehicle is stopped in the depot.
        VS_AT_STATION   The vehicle is stopped at a station and is currently loading or unloading.
        VS_BROKEN   The vehicle has broken down and will start running again in a while.
        VS_CRASHED  The vehicle is crashed (and will never run again).
        */
        local is_train = (AIVehicle.GetVehicleType(vhc_ID) == AIVehicle.VT_RAIL);
        AIController.Sleep(1);
        local vhc_state = AIVehicle.GetState(vhc_ID);
        local cargo_in = AIVehicle.GetCargoLoad(vhc_ID, Vehicles.CargoType(vhc_ID, is_train));
        local current_order = AIOrder.ResolveOrderPosition(vhc_ID, AIOrder.ORDER_CURRENT);
        switch (vhc_state) {
            case AIVehicle.VS_BROKEN :
            case AIVehicle.VS_RUNNING :
                /* don't send to depot */
                if (Debug.ResultOf(name + " is going to source/destination", current_order < 2)) break;
                /* otherwise it heading to depot, */
                return Vehicles.IsSendToDepot(vhc_ID);
                break;
            case AIVehicle.VS_AT_STATION :
                if (Debug.ResultOf(name + " is unloading", current_order == 1)) return Vehicles.IsSendToDepot(vhc_ID);
                if (Debug.ResultOf(name + " is loading", current_order == 0)) {
                    if (cargo_in > 0) AIVehicle.SkipToVehicleOrder(vhc_ID, 1);
                    else return Vehicles.IsSendToDepot(vhc_ID);
                }
                break;
            case AIVehicle.VS_CRASHED :
            /* just make sure it is stopped inside depot */
            case AIVehicle.VS_STOPPED :
            case AIVehicle.VS_IN_DEPOT : return AIVehicle.IsStoppedInDepot(vhc_ID);
            case AIVehicle.VS_INVALID: AILog.Warning("Invalid state " + name); break;
            default : Debug.DontCallMe("unknown Vehicle state", vhc_state);
        }
        return false;
    }

    /**
     * Get cargo of vehicle by check it engine
     * @param vhc_ID The ID of vehicle
     * @param is_wagon. To check wagon cargo
     * @return cargoID of that vehicle
     */
    static function CargoType(vhc_ID, is_wagon)
    {
        local engine = AIVehicle.GetEngineType(vhc_ID);
        if (is_wagon) engine = AIVehicle.GetWagonEngineType(vhc_ID, 1);
        return AIEngine.GetCargoType(engine);
    }

	/**
	 * Can Send vehicle to depot ?
	 * - Give a try to send vehicle to depot
	 * @param vhc_ID The ID of vehicle to handle
	 * @return true if vehicle has been sent to depot
	 */
	static function IsSendToDepot(vhc_ID)
	{
		AIController.Sleep(5);
		if (AIVehicle.IsStoppedInDepot(vhc_ID)) return true;
		/* maybe yes .. maybe no, but let assume true because we checked it :-)*/
		//if (Tiles.IsDepotTile(AIOrder.GetOrderDestination(vhc_ID, AIOrder.ORDER_CURRENT))) return true;
		if (AIOrder.GetOrderCount(vhc_ID) < 5) AIOrder.RemoveOrder(vhc_ID, 0);
		local retry = 3;
		local msg = "Sending " + AIVehicle.GetName(vhc_ID) + " to depot(" +  retry + ")";
		while (retry-- > 0) {
			AIController.Sleep(retry);
			if (Debug.ResultOf(msg, AIVehicle.SendVehicleToDepot(vhc_ID))) return true;
			if (AIVehicle.GetVehicleType(vhc_ID) != AIVehicle.VT_RAIL) AIVehicle.ReverseVehicle(vhc_ID);
			AIController.Sleep(retry * 2);
			if (Debug.ResultOf(msg, AIVehicle.SendVehicleToDepot(vhc_ID))) return true;
		}
		/*can't send, maybe congested line */
		return false
	}

	/**
	 * CanClone a vehicle in depot 
	 * @param vhc_ID_new The vehicle ID to clone
	 * @return 0 if no vehicle is cloned
	 */
	static function CanClone(vhc_ID)
	{
		local ord_pos = AIOrder.ResolveOrderPosition(vhc_ID, 4);
		local srcdepot = AIOrder.IsGotoDepotOrder(vhc_ID, ord_pos) ? AIOrder.GetOrderDestination(vhc_ID, ord_pos) : AIVehicle.GetLocation(vhc_ID);
		
		return Vehicles.StartCloned(vhc_ID, srcdepot, 2);	
	}

	/**
	 * CanReplace vehicle
	 * @param vhc_ID Vehicle ID to select
	 */
 	static function CanReplace(vhc_ID)
    {
        local depot = AIVehicle.GetLocation(vhc_ID);
        switch (AIVehicle.GetVehicleType(vhc_ID)) {
            case AIVehicle.VT_RAIL :
                /* pick a loco */
                local vhc_eng = AIVehicle.GetEngineType(vhc_ID);
                local wagon_id = AIVehicle.GetWagonEngineType(vhc_ID, 1);
                local cargo = Vehicles.CargoType(vhc_ID, true);
                
                local locos = Vehicles.RailEngine(1, AIEngine.GetRailType(vhc_eng));
                locos.Valuate(AIEngine.HasPowerOnRail, AIEngine.GetRailType(vhc_eng));
                locos.KeepValue(1);
                if (Debug.ResultOf("loco found", locos.Count()) < 1) return;
                locos = Vehicles.SortedEngines(locos);
                while (locos.Count() > 0) {
                    local MainEngineID = locos.Pop();
                    local engine_name = Debug.ResultOf("Loco Name", AIEngine.GetName(MainEngineID));
                    if (!AIEngine.CanPullCargo(MainEngineID, cargo)) continue;
                    local loco_id = AIVehicle.BuildVehicle(depot, MainEngineID);
                    if (!AIVehicle.IsValidVehicle(loco_id)) continue;
                    if (AIEngine.CanRefitCargo(MainEngineID, cargo)) AIVehicle.RefitVehicle(loco_id, cargo);
                    if (AIVehicle.HasSharedOrders(vhc_ID)) AIOrder.ShareOrders(loco_id,vhc_ID)
                    else AIOrder.CopyOrders (loco_id,vhc_ID);
                    if (AIOrder.GetOrderCount(loco_id) != AIOrder.GetOrderCount(vhc_ID)) {
                        AIVehicle.SellVehicle(loco_id);
                        continue;
                    }
                    if (!AIVehicle.MoveWagonChain(vhc_ID, 1, loco_id, 0)) {
                        AIVehicle.SellVehicle(loco_id);
                        continue;
                    }
                    AIGroup.MoveVehicle(AIVehicle.GetGroupID(vhc_ID), loco_id);
                    return AIVehicle.StartStopVehicle(loco_id);
                }
                break;
            case AIVehicle.VT_ROAD :
	            local myVhc = null;
	            local vhc_eng = AIVehicle.GetEngineType(vhc_ID);
	            local cargo = Vehicles.CargoType(vhc_ID, false);
		        local engines = Vehicles.RVEngine(AIEngine.GetRoadType(vhc_eng));
		        engines = Vehicles.EngineCargo(engines, cargo);
		        engines = Vehicles.SortedEngines(engines);
		        while (Debug.ResultOf("engine found", engines.Count()) > 0) {
		            local MainEngineID = engines.Pop();
		            local name = Debug.ResultOf("RV name", AIEngine.GetName(MainEngineID));
		            myVhc = AIVehicle.BuildVehicle(depot, MainEngineID);
		            if (!AIVehicle.IsValidVehicle(myVhc)) continue;
		            if (AIEngine.GetCargoType(MainEngineID) != cargo) {
		                AIVehicle.RefitVehicle(myVhc, cargo);
		            }
		            /* ordering */
		            if (AIVehicle.HasSharedOrders(vhc_ID)) AIOrder.ShareOrders(myVhc, vhc_ID)
                    else AIOrder.CopyOrders (myVhc, vhc_ID);
                    if (AIOrder.GetOrderCount(myVhc) != AIOrder.GetOrderCount(vhc_ID)) {
                        AIVehicle.SellVehicle(myVhc);
                        continue;
                    }
                    if (!AIVehicle.MoveWagonChain(vhc_ID, 1, myVhc, 0)) {
                        AIVehicle.SellVehicle(myVhc);
                        continue;
                    }
                    AIGroup.MoveVehicle(AIVehicle.GetGroupID(vhc_ID), myVhc);
                    return AIVehicle.StartStopVehicle(myVhc);
		        }
            default : Debug.DontCallMe("stop in depot" , AIVehicle.GetVehicleType(vhc_ID));
        }
    }
    
	/**
	 * Upgrade vehicle by check it engine
	 * @param engine_id_new The new engine ID of vehicle
	 */
	static function UpgradeEngine(engine_id_new)
	{
		AILog.Info("Try Upgrading Vehicle");
		local cargo = -1;
		foreach(vhc_id, val in AIVehicleList()) {
			AIController.Sleep(1);
			local group_id = AIVehicle.GetGroupID(vhc_id);            
			local engine_id_old = AIVehicle.GetEngineType(vhc_id);
			if (AIGroup.GetEngineReplacement(group_id, engine_id_old) == engine_id_new) continue; 
			local old_v_type = AIVehicle.GetVehicleType(vhc_id);
			local new_v_type = AIEngine.GetVehicleType(engine_id_new);
			if (new_v_type != old_v_type) continue;
			if (AIEngine.IsArticulated(engine_id_new) && new_v_type == AIVehicle.VT_ROAD) 
			cargo = Vehicles.CargoType(vhc_id, old_v_type == AIVehicle.VT_RAIL);			 			
			if (!Cargo.IsFit(engine_id_new, cargo)) continue;
			if (new_v_type == AIVehicle.VT_RAIL) {
				if (!AIEngine.CanPullCargo(engine_id_new, cargo)) continue;
				local r_type = AIEngine.GetRailType(engine_id_old);
				if (!(AIEngine.CanRunOnRail(engine_id_new, r_type) || AIEngine.HasPowerOnRail(engine_id_new, r_type))) continue;
			}
			/* todo :: it slightly hard to replace also using .EngineCanRefitCargo without table*/
			Debug.ResultOf("Upgrading " + AIEngine.GetName(engine_id_old) + " to " + AIEngine.GetName(engine_id_new), AIGroup.SetAutoReplace(group_id,  engine_id_old,  engine_id_new));
		}
	}

    /**
     * Start the cloned vehicle
     * @param vhc_id The ID of main vehicle
     * @param depot The tile of depot to build a clone
     * @param number The number of clone to build
     */
	static function StartCloned(vhc_id, depot, number)
	{
		local built = 0;
		AILog.Info("Try clone " + number + " Vehicle");
		for (local x = 0; x < number; x++) {
			local id = AIVehicle.CloneVehicle (depot, vhc_id, true);
			if (AIVehicle.IsValidVehicle(id)) {
				built++;
			 	AIVehicle.StartStopVehicle(id);
			}
		}
		return built;
	}
	
	/**
	 * Filter engine that is fit for cargo
	 * @param engines AIEngineList
	 * @param cargo Cargo to fit
	 * @return AIEngine list that is fit
	 */
	static function EngineCargo(engines, cargo)
	{
		local eng = engines;
		eng.Valuate(Cargo.IsFit, cargo);
		eng.KeepValue(1);
		return eng;
	}

    /**
     * Road vehicle engine list
     * @param track_type Type of track usable
     * @return Road EngineList for track type
     */
	static function RVEngine(track_type)
	{
		local engines = AIEngineList(AIVehicle.VT_ROAD);
		engines.Valuate(AIEngine.IsArticulated);
		engines.KeepValue(0);
		engines.Valuate(AIEngine.GetRoadType);
		engines.KeepValue(track_type);
		return engines;
	}

	/**
	 * AIEngineList of wagon or not types
	 * @param yes 0 to select wagon 1 to select loco
	 * @param track_type Track type needed for this engine
	 * @return AIEngineList for the type
	 */
	static function RailEngine(yes, track_type)
	{
		local engines = AIEngineList(AIVehicle.VT_RAIL);
		engines.Valuate(AIEngine.IsWagon);
		engines.RemoveValue(yes);
		engines.Valuate(AIEngine.CanRunOnRail, track_type);
		engines.KeepValue(1);
		return engines;
	}

	/**
	 * Get group name of vehicle. Its contain service key.
	 * @param vc_id Vehicle ID to get
	 * @return string name of it group
	 */
    static function GroupName(vhc_id)
    {
		return AIGroup.GetName(AIVehicle.GetGroupID(vhc_id));
    }

	/**
	 * Sort engine list by scoring them
	 * @param engines AIEngineList
	 * @return Heap of sorted list
	 */
	static function SortedEngines(engines)
	{
		local heap = FibonacciHeap();
		local score = 1000000;
		foreach (idx, val in engines) {
			AIController.Sleep(1);
			if (AIEngine.IsWagon(idx)) {
				score -= AIEngine.GetCapacity(idx);
				heap.Insert(idx, score);
				continue;
			}
			
			local vtype = AIEngine.GetVehicleType(idx);
			if (vtype == AIVehicle.VT_ROAD) {
				score -=  AIEngine.GetMaxSpeed(idx);
			}
			
			if (vtype == AIVehicle.VT_RAIL) {
				score -= AIEngine.GetPower(idx);
				if (!TransAI.Setting.Get(Const.Settings.realistic_acceleration)) {
						score -= AIEngine.GetMaxTractiveEffort(idx);
				}
			}
			heap.Insert(idx, score);
		}
		return heap;
	}

	/**
	 * Count vehicle at tile
	 * @param vhc_lst Vehicle list to count ( use AIVehicleList() to all)
	 * @param ... Tile index of location
	 * @return number of vehicle on that tile
	 */
	static function CountAtTile(vhc_lst, ...)
	{
		if (vargc < 1) return 0;
		local vc = 0;
		for(local c = 0; c < vargc; c++) {
			foreach (idx, val in vhc_lst) {
				if (AIVehicle.GetLocation(idx) == vargv[c]) vc++;
			}
		}
		return vc;
	}
	
	/**
	 * Set common depot and conditional order
	 * @param myVhc Vehicle ID
	 * @param srcDepot Source depot
	 * @param dstDepot Destination depot
	 */
	static function SetNextOrder(myVhc, srcDepot, dstDepot)
	{ 
		AIOrder.AppendOrder(myVhc, dstDepot, AIOrder.AIOF_STOP_IN_DEPOT);
		AIOrder.AppendOrder(myVhc, srcDepot, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
		AIOrder.InsertConditionalOrder(myVhc, 2, 3);
		AIOrder.SetOrderCondition(myVhc, 2, AIOrder.OC_AGE);
		AIOrder.SetOrderCompareFunction(myVhc, 2, AIOrder.CF_LESS_THAN);
		AIOrder.SetOrderCompareValue(myVhc, 2, (AIVehicle.GetMaxAge(myVhc) / 366).tointeger());
	}
	
	/**
	 * Sell completely
	 */
	function SellRailVhc(vhcid)
	{
		AIVehicle.SellWagonChain(vhcid, 0);
		return AIVehicle.SellVehicle(vhcid);
	}
}

/**
 * Try add vehicle
 */
class Task.AddVehicle extends DailyTask
{
	constructor()
	{    	
		::DailyTask.constructor("Vehicle Addition task");
		::DailyTask.SetKey(7);        
	}

	function Execute()
	{
		if (TransAI.Info.Serviced_Route.len() == 0) return;
		::DailyTask.Execute();    	
		foreach (idx, tabel in TransAI.Info.Serviced_Route) {
			if ((tabel.VehicleType == AIVehicle.VT_RAIL) && !tabel.RailDoubled) continue;
			AILog.Info("=>" + AIVehicle.GetName(tabel.MainVhcID));
			if (tabel.VehicleMaxNum == 0) {
				local dist = Debug.ResultOf("Distance", max(tabel.A_Distance, tabel.R_Distance));
				local vlen = Debug.ResultOf("Vehicle len", AIVehicle.GetLength(tabel.MainVhcID));
				TransAI.Info.Serviced_Route[idx].VehicleMaxNum = ( dist * 16 / vlen).tointeger();
				continue;
			}
			local st_id = tabel.SourceStation;
			local vhclst = AIVehicleList_Station(st_id);
			if (tabel.VehicleNum != vhclst.Count()) {
				TransAI.Info.Serviced_Route[idx].VehicleNum = vhclst.Count();
				continue;
			}
			vhclst.Valuate(AIVehicle.GetAge);
			vhclst.Sort(AIAbstractList.SORT_BY_VALUE, true);
			if (!AIVehicle.IsValidVehicle(tabel.MainVhcID)) {
				TransAI.Info.Serviced_Route[idx].MainVhcID = vhclst.Begin();
				continue;
			}
			local st_loc = AIStation.GetLocation(st_id);
			local depot = tabel.SourceDepot;
			local vhc_count = Vehicles.CountAtTile(vhclst, st_loc, depot);
			if (vhc_count) continue;
			if (Debug.ResultOf("Max. reached", tabel.VehicleNum > tabel.VehicleMaxNum)) {
				AILog.Warning("Try Adding");
				
				local min_capacity = AIVehicle.GetCapacity(tabel.MainVhcID, tabel.Cargo);
				local string_x = "Cargo waiting at " + AIStation.GetName(st_id);
				if (Debug.ResultOf(string_x, AIStation.GetCargoWaiting(st_id, tabel.Cargo)) > min_capacity) {
					Bank.Get(0);
					Debug.ResultOf("Vehicle build", Vehicles.StartCloned(tabel.MainVhcID, depot, 1));
				}
			} else {
				AILog.Warning("Try maximizing");
				Bank.Get(0);
				Debug.ResultOf("Vehicle build", Vehicles.StartCloned(tabel.MainVhcID, depot, 1));
			}
    	}
    }
}

/**
 * Task to sell vehicle 
 */
class Task.SellVehicle extends DailyTask
{
	constructor()
	{    	
		::DailyTask.constructor("Vehicle Seller task");
		::DailyTask.SetKey(7);        
	}

	function Execute()
	{
		::DailyTask.Execute();
		foreach (idx, val in AIVehicleList()) {
			AIController.Sleep(1);
			if (!AIVehicle.IsStoppedInDepot(idx)) continue;
			AILog.Info("" + AIVehicle.GetName(idx) + " is inside depot");
			if (AIOrder.GetOrderCount(idx) < 5) {
				/* it has invalid order */
				Vehicles.SellRailVhc(idx);
				continue;
			}
			if (AIVehicle.GetAgeLeft(idx) > 0) AIVehicle.StartStopVehicle(idx);
			
			local g = AIVehicle.GetGroupID(idx);
			local num = AIGroup.GetNumEngines(g, AIVehicle.GetEngineType(idx)); 
    		switch (num) {
    			case 0 : Debug.DontCallMe("impossible vehicle num", num);
    			case 1 : 
    				if (Vehicles.CanClone(idx) == 0) {
		    			switch (AIError.GetLastError()) {
		    				case AIError.ERR_NOT_ENOUGH_CASH : 
		    					AIVehicle.StartStopVehicle(idx);
		    					continue;
		    				default :
		    					if (Vehicles.CanReplace(idx)) break;
	    						AIVehicle.StartStopVehicle(idx);
	    						continue;
		    			}
    				}
	    		default : Vehicles.SellRailVhc(idx); 
    		}
		}
	}
}
