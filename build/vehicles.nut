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
    id = -1;
    constructor(id)
    {
        this.id = id;
    }

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

    static function Sold(vhc_ID)
    {
        if (!AIVehicle.IsStoppedInDepot(vhc_ID)) return false;
        local depot = AIVehicle.GetLocation(vhc_ID);
        switch (AIVehicle.GetVehicleType(vhc_ID)) {
            case AIVehicle.VT_RAIL :
                if (AIOrder.GetOrderCount(vhc_ID) < 5) {
                    AIVehicle.SellWagonChain(vhc_ID, 0);
                    return AIVehicle.SellVehicle(vhc_ID);
                }
                /* pick a loco */
                local vhc_eng = AIVehicle.GetEngineType(vhc_ID);
                local wagon_id = AIVehicle.GetWagonEngineType(vhc_ID, 1);
                local cargo = AIEngine.GetCargoType(wagon_id);
                
                local locos = Vehicles.WagonEngine(0);
                locos.Valuate(AIEngine.HasPowerOnRail, AIEngine.GetRailType(vhc_eng));
                locos.KeepValue(1);
                if (Debug.ResultOf("loco found", locos.Count()) < 1) return false;
                locos = Vehicles.SortedEngines(locos);
                while (locos.Count() > 0) {
                    local MainEngineID = locos.Pop();
                    local engine_name = Debug.ResultOf("Loco Name", AIEngine.GetName(MainEngineID));
                    if (!AIEngine.CanPullCargo(MainEngineID, cargo)) continue;
                    local loco_id = AIVehicle.BuildVehicle(depot, MainEngineID);
                    if (!AIVehicle.IsValidVehicle(loco_id)) continue;
                    if (AIEngine.CanRefitCargo(MainEngineID, cargo)) AIVehicle.RefitVehicle(loco_id, cargo);
                    if (AIVehicle.HasSharedOrders(vhc_ID)) AIOrder.ShareOrders(loco_id,vhc_ID);
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
                    AIVehicle.StartStopVehicle(loco_id);
                    return AIVehicle.SellVehicle(vhc_ID);
                }
                break;
            case AIVehicle.VT_ROAD :
            	Vehicles.StartCloned(vhc_ID, depot, 2);
                return AIVehicle.SellVehicle(vhc_ID);
            default : Debug.DontCallMe("stop in depot" , AIVehicle.GetVehicleType(vhc_ID));
        }
    }

	/**
	 * upgrade vehicle by check it engine
	 * @param engine_id_new The new engine ID of vehicle
	 */
	static function UpgradeEngine(engine_id_new)
	{
		AILog.Info("Try Upgrading Vehicle");
		foreach(vhc_id, val in AIVehicleList()) {
			AIController.Sleep(1);
			local group_id = AIVehicle.GetGroupID(vhc_id);            
			local engine_id_old = AIVehicle.GetEngineType(vhc_id);
			if (AIGroup.GetEngineReplacement(group_id, engine_id_old) == engine_id_new) continue; 
			local old_v_type = AIVehicle.GetVehicleType(vhc_id);
			local new_v_type = AIEngine.GetVehicleType(engine_id_new);
			if (new_v_type != old_v_type) continue; 
			local cargo = Vehicles.CargoType(vhc_id, old_v_type == AIVehicle.VT_RAIL);			 			
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

    static function ReplaceVhc(vhc_id)
    {
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
            if (AIVehicle.StartStopVehicle(AIVehicle.CloneVehicle (depot, vhc_id, true))) built++;
        }
        return built;
    }

    static function EngineCargo(engines, cargo)
    {
        engines.Valuate(Cargo.IsFit, cargo);
        engines.KeepValue(1);
        return engines;
    }

    static function RVEngine(track_type)
    {
        local engines = AIEngineList(AIVehicle.VT_ROAD);
        engines.Valuate(AIEngine.IsArticulated);
        engines.KeepValue(0);
        engines.Valuate(AIEngine.GetRoadType);
        engines.KeepValue(track_type);
        return engines;
    }

    static function WagonEngine(yes)
    {
        local engines = AIEngineList(AIVehicle.VT_RAIL);
        engines.Valuate(AIEngine.IsWagon);
        engines.KeepValue(yes);
        return engines;
    }

    static function GroupName(vhc_id)
    {
        return AIGroup.GetName(AIVehicle.GetGroupID(vhc_id));
    }

    static function SortedEngines(engines)
    {
        local heap = FibonacciHeap();
        foreach (idx, val in engines) {
            AIController.Sleep(1);
            local score = AIEngine.GetPrice(idx) / (AIEngine.GetReliability(idx) + 2);
            score += AIEngine.GetRunningCost(idx) / (AIEngine.GetMaxSpeed(idx) + 2);
            score -=  AIEngine.GetCapacity(idx) * 50;
            score -= AIEngine.GetMaxAge (idx) + 1;
            score -= AIEngine.GetPower(idx) + 1;
            heap.Insert(idx, score);
        }
        return heap;
    }

    static function CountAtTile(tileID)
    {
        local vc = AIVehicleList();
        vc.Valuate(AIVehicle.GetLocation);
        vc.KeepValue(tileID);
        return vc.Count();
    }
}

/**
 * Try add vehicle
 */
class Task.AddVehicle extends DailyTask
{
	Info = null;
	_max_num = 0;
    constructor()
    {    	
        ::DailyTask.constructor("Vehicle Addition task");
        ::DailyTask.SetRemovable(false);
        ::DailyTask.SetKey(7);        
    }
    
    function Execute()
    {
    	if (TransAI.Info.Serviced_Route.len() == 0) return;
    	::DailyTask.Execute();    	
    	foreach (idx, tabel in TransAI.Info.Serviced_Route) {	        
	        AILog.Info("" + AIVehicle.GetName(tabel.MainVhcID));
	        local dist = Debug.ResultOf("Distance", max(tabel.A_Distance, tabel.R_Distance));
	        local vlen = Debug.ResultOf("Vehicle len", AIVehicle.GetLength(tabel.MainVhcID));
	        this._max_num = ( dist * 16 / vlen).tointeger();
	        local vhclst = AIVehicleList_Station(tabel.SourceStation);
	        tabel.VehicleNum = vhclst.Count();
	        tabel.MainVhcID = vhclst.Begin();
	        AILog.Info("Vehicle count:" + tabel.VehicleNum);
	        this.Info = tabel;
	        if (tabel.VehicleNum > Debug.ResultOf("Max", this._max_num)) {
				AILog.Warning("Maximum reached: Not adding");				
			} else {
				this.TryAdd();
	        }
	        TransAI.Info.Serviced_Route[idx] = this.Info;
    	}
    }

    function TryAdd()
    {		
		
		local min_capacity = 0;
		local vhc_count = 0;
		local name = AIVehicle.GetName(this.Info.MainVhcID);
		/* sometime not work */
		local ssta = AIStation.GetLocation(this.Info.SourceStation);		
		//local ssta = AIOrder.GetOrderDestination((this.Info.MainVhcID), AIOrder.ResolveOrderPosition(this.Info.MainVhcID, 0));
		local depot = this.Info.SourceDepot;
		switch (this.Info.VehicleType) {
			case AIVehicle.VT_ROAD :
				if (!Debug.ResultOf(name + " valid station order", AIRoad.IsRoadStationTile(ssta))  ||
					!Debug.ResultOf(name + " valid depot order", AIRoad.IsRoadDepotTile(depot))) {
						TransAI.Info.Lost_Vehicle.push(this.Info.MainVhcID);						
						return;
				}
				//vhc_count = Vehicles.CountAtTile(AIRoad.GetRoadStationFrontTile(ssta));
				break;
			case AIVehicle.VT_RAIL :
				if (!Debug.ResultOf(name + " valid station order", AIRail.IsRailStationTile(ssta))  ||
					!Debug.ResultOf(name + " valid depot order", AIRail.IsRailDepotTile(depot))) {
						TransAI.Info.Lost_Vehicle.push(this.Info.MainVhcID);						
						return;
				}
				//vhc_count = Vehicles.CountAtTile(AIRail.GetRailDepotFrontTile(depot));
				break;
			case AIVehicle.VT_AIR:
	        	AILog.Warning("Using Air");
	        	break;
            case AIVehicle.VT_WATER:
            	AILog.Warning("Using Water");
            	break;
			default : Debug.DontCallMe("Unsupported V_Type", this.Info.MainVhcID);
		}
		vhc_count += Vehicles.CountAtTile(ssta);
		//vhc_count += Vehicles.CountAtTile(depot);
		if (Debug.ResultOf("Vehicle waiting:", vhc_count) > 0) return;
		local ssta_ID = this.Info.SourceStation;
		if (AIStation.GetCargoRating(ssta_ID, this.Info.Cargo) > 60) return;
		min_capacity = Debug.ResultOf("Min. Cap", AIVehicle.GetCapacity(this.Info.MainVhcID, this.Info.Cargo));		
		local string_x = "cargo waiting at " + AIStation.GetName(ssta_ID);
		if  (Debug.ResultOf(string_x, AIStation.GetCargoWaiting(ssta_ID, this.Info.Cargo)) > min_capacity) {
			if (this.Info.VehicleType == AIVehicle.VT_RAIL) {
				if (!this.Info.RailDoubled) return;
			} else {
				//do other stuff for non rail veh
			}
			Bank.Get(0);
			Debug.ResultOf("Vehicle build", Vehicles.StartCloned(this.Info.MainVhcID, depot, 1));
		}		
	}
}
