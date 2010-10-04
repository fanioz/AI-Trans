/*  09.02.23 services.nut
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
 * Services container
 */
class Services
{
	/** Memory - the storage of class */
	Info = null;
	/** Ignored pathfindng AITileList(); */
	IgnoreTileList = null;
	/** Servable source */
	Source = null;
	/** Servable destination */
	Destination = null;
	/** Source Station */
	SourceStation = null;
	/** Destination Station */
	DestinationStation = null;
	/** Source Depot */
	SourceDepot = null;
	/** Destination Depot */
	DestinationDepot = null;
	/** Path finder */
	PathFinder = null;
	/**
	 * constructor class
	 */ 
	constructor()
	{
		Info = Memory("Services");
		this.IgnoreTileList = AITileList();
	}

	/**
	 * Make a new service class
	 * @param src Instance of servable class as source
	 * @param dst Instance of servable class as destination
	 * @param cargoid ID of cargo
	 * @return instance of Services class
	 */
	static function New (src, dst, cargoid)
	{

		assert(src instanceof Servable);
		assert(dst instanceof Servable);
		local ptabel = {
			Depart = [],
			Arrive = [],
			PM = [],
			Test = [],
			Reserved = [],
		};
		local serv = Services();
		serv.Info.ID = 0;
		serv.Info.Path = [];		
		serv.Info.Key = Services.CreateID(src.GetLocation(), dst.GetLocation(), cargoid);
		serv.Info.Source = src.GetLocation();
		serv.Info.Destination = dst.GetLocation();
		serv.Info.Cargo = cargoid;		
        serv.Info.CargoLabel = AICargo.GetCargoLabel(cargoid);
		serv.Info.R_Distance = src.GetDistanceManhattanToTile(dst.GetLocation());
		serv.Info.A_Distance = 0;
		serv.Info.IsSubsidy = false;
		serv.Info.PastCost = 0;
		serv.Info.Priority = 0;
		serv.Info.MainVhcID = -1;
		serv.Info.RailDoubled = false;
		serv.Info.SourceStation = -1;
		serv.Info.SourceDepot = -1;
		serv.Info.VehicleType = -1;
		serv.Info.TrackType = -1;
		serv.Info.VehicleNum = 0;
		return serv;
	}

    /**
     * Make service ID
     * @param source Source ID
     * @param dest Destination ID
     * @param cargo Cargo ID
     * @return ID of service table
     */
    static function CreateID(source, dest, cargo)
    {
        local n = Assist.LeadZero(TransAI.Info.ID) + Assist.LeadZero(source) + Assist.LeadZero(dest) + Assist.LeadZero(cargo);
        return n;
    }
}

/**
 * Try to do transport service
 */
class Task.Service extends DailyTask
{
	constructor()
    {
        ::DailyTask.constructor("Service Task");
        ::DailyTask.SetRemovable(false);
        ::DailyTask.SetKey(10);
    }
    
    function Execute()
    {
        ::DailyTask.Execute();
        TransAI.ServiceMan.SortValueDescending();
		local serv_list = TransAI.ServiceMan.list;
		local serv = null, servkey = null;
        for (local idx = serv_list.Begin(); serv_list.HasNext(); idx = serv_list.Next()) {        	
			AIController.Sleep(1);
			serv = TransAI.ServiceMan.Item(idx);
			servkey = serv.Info.Key;
			if (servkey in TransAI.Info.Expired_Route) continue;			
			if (servkey in TransAI.Info.Serviced_Route) continue;			            

			if (TransAI.Builder.Service(serv)) {
				TransAI.Info.Serviced_Route[servkey] <- serv.Info.GetStorage();
				::DailyTask.SetKey(60);
			} else {
				TransAI.Info.Expired_Route[servkey] <- servkey;
				AILog.Info("Can't afford a service right now");
				::DailyTask.SetKey(5);
			}
			TransAI.Builder.ClearSigns();
			// do one service each call
            return;
        }
        // Reset what we 've skipped in the past
        TransAI.Info.Expired_Route = {};
    }
}

/**
 * class to analyze the cost needed
 */
class Services.Cost
{	constructor(s)
	{
	}

	function SetInfrastructure(infra)
	{
	}

	function Route()
	{
	}

	function Depot()
	{
	}

	function Station()
	{
	}

	function Vehicle()
	{
	}
}
