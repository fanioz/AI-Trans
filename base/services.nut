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
	/** Servable source */
	Source = null;
	/** Servable destination */
	Destination = null;
	/** Source Station */
	SourceStation = null;
	/** Destination Station */
	DestinationStation = null;
	/** Caching area */
	SourceCacheArea = AIList();
	DestCacheArea = AIList();
	/**
	 * constructor class
	 */ 
	constructor()
	{
		Info = Memory("Services");
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
		local serv = Services();
		
		serv.Info.ID = 0;		
		serv.Info.Key = Services.CreateID(src.GetID(), dst.GetID(), cargoid);
		serv.Info.Source = src.GetLocation();
		serv.Info.Destination = dst.GetLocation();
		serv.Info.Cargo = cargoid;		
        serv.Info.CargoLabel = AICargo.GetCargoLabel(cargoid);
		serv.Info.R_Distance = src.GetDistanceManhattanToTile(dst.GetLocation());
		serv.Info.A_Distance = 0;
		serv.Info.IsSubsidy = false;
		serv.Info.MainVhcID = -1;
		serv.Info.RailDoubled = false;
		/* station ID */
		serv.Info.SourceStation = -1;
		/* tile index of body */
		serv.Info.SourceDepot = -1;
		serv.Info.DstDepot = -1;
		serv.Info.VehicleType = -1;
		serv.Info.TrackType = -1;
		serv.Info.RoadStationType = AIRoad.GetRoadVehicleTypeForCargo(cargoid);
		serv.Info.VehicleNum = 0;
		serv.Info.VehicleMaxNum = 0;
		/* engines selected */
		serv.Info.LocoEngine = -1;
		serv.Info.WagonEngine = -1;
		serv.Info.RoadEngine = -1;
		serv.Info.StartPath = [];
        serv.Info.DepotStart = [];
        serv.Info.EndPath = [];
        serv.Info.DepotEnd = [];
		return serv;
	}

    /**
     * Make service ID
     * @param source Source ID
     * @param dest Destination ID
     * @param cargo Cargo ID
     * @return string ID of service table
     */
    static function CreateID(source, dest, cargo)
    {
        return Assist.LeadZero(TransAI.Info.ID) + Assist.LeadZero(source) + Assist.LeadZero(dest) + Assist.LeadZero(cargo);
    }
}

/**
 * Try to do transport service
 */
class Task.Service extends DailyTask
{
	constructor()
    {
        ::DailyTask.constructor("Service Builder");
        this.SetKey(30);
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
			
			local result = TransAI.Builder.Service(serv);
			switch (result) {
				case "success" :
					TransAI.Info.Serviced_Route[servkey] <- serv.Info.GetStorage();
					this.SetKey(90);
					break;
				case "no_money" :
					TransAI.Info.Expired_Route[servkey] <- servkey;
					AILog.Info("Have not enough money right now");
					this.SetKey(10);
					break;
				default :
					TransAI.Info.Expired_Route[servkey] <- servkey;
					AILog.Info("Can't afford a service right now");
					TransAI.Builder.ClearSigns();
					continue;
			}
			TransAI.Builder.ClearSigns();
			TransAI.ServiceMan.ChangeItem(idx, serv);
			// do one service each call
            return;
        }
        // Reset what we 've skipped in the past
        TransAI.Info.Expired_Route = {};
        this.SetKey(30);
    }
}
