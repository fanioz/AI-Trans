/*  09.02.06 - building.nut
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
 * Class BuildingHandler
 * super class of all builder
 */
class BuildingHandler {
	/// The state of this builder
	State = null;                 
	/// RoadBuilder Class
	Road = null;
	/// RailBuilder class
	Rail = null;                 
	/// class constructor
	constructor() {
		this.State = Memory("BuildingState");
		this.Road = this.road(this);
		this.Rail = this.rail(this);
	}

	function Service(serv){
    	assert(serv instanceof Services);
    	local src = TransAI.ServableMan.Item(serv.Info.Source);
    	if (src) {
    		Debug.Sign(serv.Info.Source, "src");
    	} else {
    		AILog.Warning("Not found location");
    		return;
    	}
    	
        local dst = TransAI.ServableMan.Item(serv.Info.Destination);
        if (dst) {
        	Debug.Sign(serv.Info.Destination, "dst");
        } else {
        	AILog.Warning("Not found location");
        	return;
        }
        AILog.Warning("servicing:" + src.GetName() + " to " + dst.GetName() + ":" + serv.Info.CargoLabel);
        if (Debug.ResultOf("Last month transported", src.GetLastMonthTransported(serv.Info.Cargo)) > 60) return;
        if (Debug.ResultOf("Last month production", src.GetLastMonthProduction(serv.Info.Cargo)) < 5) return;        
        local vehicle_type = [AIVehicle.VT_AIR, AIVehicle.VT_WATER, AIVehicle.VT_ROAD, AIVehicle.VT_RAIL];
        if (Cargo.ListOfClass(AICargo.CC_PASSENGERS).Begin() == serv.Info.Cargo) {
        	vehicle_type = [AIVehicle.VT_WATER, AIVehicle.VT_ROAD, AIVehicle.VT_RAIL, AIVehicle.VT_AIR];
        }
        serv.Source = src;
    	serv.Destination = dst;
    	Bank.Get(0);
    	while (vehicle_type.len()) {
    		serv.Info.VehicleType = vehicle_type.pop();
    		switch (serv.Info.VehicleType) {
    			case AIVehicle.VT_ROAD:
    				if (serv.Info.R_Distance > 100) break;
                	AILog.Warning("Using Road");
                	serv.Info.TrackType = AIRoad.ROADTYPE_ROAD;
					AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
    				//AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
                    if (this.RoadServicing(serv)) {
                    	return true;
                    } 
                    break;
                case AIVehicle.VT_RAIL:
                	if (serv.Info.R_Distance < 50) break;
                	AILog.Warning("Using Rail");
                	local rail_avail = AIRailTypeList();
                	serv.Info.TrackType = rail_avail.Begin();
                    AIRail.SetCurrentRailType(serv.Info.TrackType);
                    if (this.RailServicing(serv)) {
                    	return true;
                    }
                    if (rail_avail.HasNext()) serv.Info.TrackType = rail_avail.Next();
                    AIRail.SetCurrentRailType(serv.Info.TrackType);
                    if (this.RailServicing(serv)) {
                    	return true;
                    }
                    break;
                case AIVehicle.VT_AIR:
                	AILog.Warning("Using Air");
                	break;
                case AIVehicle.VT_WATER:
                	AILog.Warning("Using Water");
                	break;                
                default : AILog.Warning("Unsupported yet vehicle type"); break;
            }
    	}
    }
}

/**
 * ClearSigns is AISign cleaner
 * Clear all sign that I have been built while servicing.
 */
function BuildingHandler::ClearSigns()
{
    AILog.Info("Clearing signs ...");
    local s = AISignList();
  	while (s.Count()) {  		
    	AISign.RemoveSign(s.Begin());
    	s.RemoveTop(1);    	
  	}
}

/**
 * Grouping vehicle
 * @param serv Service tabel
 */
 function BuildingHandler::MakeGroup(serv)
 {
    local grp = AIGroup.CreateGroup(serv.Info.VehicleType);
    local g_name = serv.Info.Key.tostring();
    if (!AIGroup.SetName(grp, g_name)) {
        local grp_list = AIGroupList();
        grp_list.Valuate(AIGroup.GetVehicleType);
        grp_list.KeepValue(serv.Info.VehicleType);
        foreach (idx, val in grp_list) {
            if (AIGroup.GetName(idx) == g_name) {
                AIGroup.DeleteGroup(grp);
                grp = idx;
                break;
            }
        }
    }
    AIGroup.MoveVehicle(grp, serv.Info.MainVhcID);
 }

/**
 * Servicing a route defined before by Road Vehicle
 */
function BuildingHandler::RoadServicing(serv)
{
    
    serv.SourceDepot = Platform();
    serv.DestinationDepot = Platform();
    serv.SourceStation = Stations();
    serv.DestinationStation = Stations();
    local service_cost = 0;

    AILog.Warning("Test Mode");
    this.State.TestMode = true;
    if (!this.Road.Vehicle(serv)) return false;
    service_cost += this.State.LastCost * 2;
    if (!Bank.Get(service_cost)) return false;
    //this.State.TestMode = false;

    if (!this.Road.Path(serv, 0 false)) if (!this.Road.Path(serv, 0, true)) return false;
    if (!this.Road.Track(serv, 0)) return false;
    service_cost += this.State.LastCost * 1.5;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Station(serv, true)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Station(serv, false)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Depot(serv, true)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Depot(serv, false)) return false;
    service_cost += this.State.LastCost;

    /* don't continue if I've not enough money */
    if (!Bank.Get(service_cost)) return false;

    AILog.Warning("Real Mode");
    this.State.TestMode = false;

    if (!this.Road.Station(serv, true)) return false;
    if (!this.Road.Station(serv, false)) return false;

    if (!this.Road.Depot(serv, true)) return false;
    if (!this.Road.Depot(serv, false)) return false;

    if (!this.Road.Path(serv, 1, false)) {
        this.Road.Path(serv, 1, true);
        if (!this.Road.Track(serv, 1)) {
        this.Road.Path(serv, 1, true);
        if (!this.Road.Track(serv, 1)) return false;
        }
    }

    if (!this.Road.Path(serv, 2, false)) {
        this.Road.Path(serv, 2, true);
        if (!this.Road.Track(serv, 2)) {
        this.Road.Path(serv, 2, true);
        if (!this.Road.Track(serv, 2)) return false;
        }
    }

    if (!this.Road.Path(serv, 3, false)) {
        this.Road.Path(serv, 3, true);
        if (!this.Road.Track(serv, 3)) {
        this.Road.Path(serv, 3, true);
        if (!this.Road.Track(serv, 3)) return false;
        }
    }

    // I'm sad to return false after going so far
    if (!this.Road.Vehicle(serv)) return false;
	
    AIVehicle.StartStopVehicle(serv.Info.MainVhcID);
    this.MakeGroup(serv);
    if (!serv.Info.IsSubsidy) Assist.RenameStation(serv.DestinationStation.GetID(), serv.Info.CargoLabel);

    this.Road.Vehicle(serv);
    return true;
}

/**
 * Servicing a route defined before by Rail Vehicle
 */
function BuildingHandler::RailServicing(serv)
{
    serv.SourceDepot = Platform();
    serv.DestinationDepot = Platform();
    serv.SourceStation = Stations();
    serv.DestinationStation = Stations();

    local service_cost = 0;

    AILog.Warning("Test Mode");
    this.State.TestMode = true;

    if (!this.Rail.Vehicle(serv)) return false;
    service_cost += this.State.LastCost * 3;
    if (!Bank.Get(service_cost)) return false;
    //this.State.TestMode = false;

    if (!this.Rail.Station(serv, true)) return false;
    service_cost += this.State.LastCost * 1.5;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Rail.Station(serv, false)) return false;
    service_cost += this.State.LastCost * 1.5;
    if (!Bank.Get(service_cost)) return false;

    this.Rail.Path(serv, 0, true);
    this.Rail.Track(serv, 0);
    service_cost += this.State.LastCost * 1.5 ;
    if (!Bank.Get(service_cost)) return false;
    this.Rail.Signal(serv, 0);
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;
    if (!this.Rail.Depot(serv, true)) return false;
    service_cost += this.State.LastCost * 1.5;


    /* don't continue if I've not enough money */
    if (!Bank.Get(service_cost)) return false;

    AILog.Warning("Real Mode");
    this.State.TestMode = false;
    
    if (!this.Rail.Station(serv, false)) return false;
    if (!this.Rail.Station(serv, true)) return false;

    this.Rail.Path(serv, 1, true);
    //this.State.TestMode = true;
    //if (!this.Rail.Track(serv, 1)) {
        //this.Rail.Path(serv, 1, true);
        //if (!this.Rail.Track(serv, 1)) return false;
    //}
    //this.State.TestMode = false;
    if (!this.Rail.Track(serv, 1)) return false;

    if (!this.Rail.Depot(serv, true)) return false;
    if (!this.Rail.Depot(serv, false)) return false;

    // I'm sad to return false after going so far
    if (!this.Rail.Vehicle(serv)) return false;
    AIVehicle.StartStopVehicle(serv.Info.MainVhcID);

    this.MakeGroup(serv);
    if (!serv.Info.IsSubsidy) Assist.RenameStation(serv.DestinationStation.GetID(), serv.Info.CargoLabel);
    
    //TransAI.RailBackBones.rawset(serv.Info.Key, serv);
    AILog.Info("Try to connect backbone for id " + serv.Info.Key);
	this.Rail.Path(serv, 2, true);
	this.State.TestMode = true;

	if (!this.Rail.Track(serv, 2)) {
	    this.Rail.Path(serv, 2, true);
	    if (!this.Rail.Track(serv, 2)) return false;
	}
	service_cost = this.State.LastCost;
	this.Rail.Vehicle(serv);
	service_cost += this.State.LastCost;
	this.Rail.Signal(serv, 1);
	service_cost += this.State.LastCost;
	this.Rail.Signal(serv, 2);
	service_cost += this.State.LastCost;
	//if (!Bank.Get(service_cost)) return false;

	this.State.TestMode = false;
	if (!this.Rail.Track(serv, 2)) {
	    this.Rail.Path(serv, 2, true);
	    if (!this.Rail.Track(serv, 2)) return false;
	}
	if (this.Rail.Signal(serv, 1)) {
		if (this.Rail.Signal(serv, 2)) {
			this.Rail.Vehicle(serv);
			serv.Info.RailDoubled = true;			
			return true;
		}
	}
}
