
/*  09.03.08 - generator.nut
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
 *
 * Generator Class for Subsidy and Position
 */
class Generate
{
    /**
     * Position Generator. Generate position for depot and station.
     * @param heads Area of tile list that become a head
     * @param center of area
     * @param centered center first or last
     * @return yield of position table (head, body, id)
     */
    static function Pos(heads, center, centered)
    {
        AIController.Sleep(1);
        heads.Valuate(AIMap.DistanceMax, center);
        heads.Sort(AIAbstractList.SORT_BY_VALUE, centered);
        for (local head = heads.Begin(); heads.HasNext(); head = heads.Next()) {
            AIController.Sleep(1);
            local bodies = Tiles.BodiesOf(head);
            foreach (body, val in bodies){
                AIController.Sleep(1);
                yield ::Depot(body, head);
            }
        }
    }

    /**
     * Subsidy Generator. Generate table of subsidy service.
     */
    static function Subsidy(main)
    {
        /* add randomizer, not all trans AI instance would handle subsidy */
        local skip_this = main.GetID() % 3;
        if (skip_this == 0) return;
        local random_factor =  (1 + skip_this) * 30;
        local list = AISubsidyList();
        local subs_service = null;
        AILog.Info("Try to generate services from subsidies");
        list.Valuate(AISubsidy.IsValidSubsidy);
        list.RemoveValue(0);
        list.Valuate(AISubsidy.IsAwarded);
        list.RemoveValue(1);
        foreach (i, val in list) {
            AIController.Sleep(1);
            local d = AISubsidy.GetExpireDate(i) - AIDate.GetCurrentDate();
            if (d < random_factor) continue;
            local source = AISubsidy.GetSource(i);
            local dest = AISubsidy.GetDestination(i);
            subs_service = Services.NewTable(source, dest, AISubsidy.GetCargoType(i));
            /* avoid double service */
            if (subs_service.ID in main.serviced_route) continue;
            if (subs_service.ID in main.expired_route) continue;
            if (main.service_keys.Exists(subs_service.ID)) continue;
            /* remove when supported */
            if ((!AISubsidy.SourceIsTown(i) && AIIndustry.IsBuiltOnWater(source)) ||
                (!AISubsidy.DestinationIsTown(i) && AIIndustry.IsBuiltOnWater(dest))) continue;
            subs_service = Services.RefreshTable(subs_service);
            if (AIMap.DistanceMax(subs_service.Source.Location, subs_service.Destination.Location) < 10) continue;
            subs_service.IsSubsidy = true;
            AILog.Info("Subsidy scheduled");
            AILog.Info(subs_service.Readable);
            main.service_keys.Insert(subs_service.ID, d - random_factor);
            if (subs_service.ID in main.service_tables) continue;
            main.service_tables[subs_service.ID] <- subs_service;
            return;
        }
        AILog.Info("No more Subsidy");
        subs_service = null;
    }
}

/**
 * Task to generate service
 */
class Task.GenerateService extends YieldTask 
{
	constructor()
	{
		::YieldTask.constructor("Service Finder");
		this.SetRepeat(false);
		this.SetKey(5);
	}

	function _exec()
    {
    	::YieldTask._exec();
		local serv = null;
		local src_lst = null;
		local src = null, dst = null;
		local dst_istown = null, src_istown = null;
		local c = 0;
		local priority = AICargoList().Count() + 100;
		foreach(cargo, val in  Cargo.Sorted()) {
			priority --;
			if (!(cargo in TransAI.Info.Drop_off_point)) continue;
			AILog.Info("Cargo type " + AICargo.GetCargoLabel(cargo));			
			dst = TransAI.ServableMan.Item(TransAI.Info.Drop_off_point.rawget(cargo));
			if (dst == null) continue;
			//AILog.Info("Target " + dst.GetName());
			src_istown = AIIndustryList_CargoProducing(cargo).IsEmpty();
			if (src_istown) {
				/* working with town */
				src_lst = Cargo.TownList_Producing(cargo);
			} else {
				/* let's assume working with industry */
				src_lst = Assist.NotOnWater(AIIndustryList_CargoProducing(cargo));
			}
			local key = "";
			local id = 0;
            foreach (source, val in src_lst) {
				key = Services.CreateID(source, dst.GetID(), cargo);
				id = TransAI.ServiceMan.FindKey(key);
				if (id) {
					//AILog.Info("Found duplicate");
					//TODO: refresh cost
					continue;
				} else {
					/// service key not found = New
					src = TransAI.ServableMan.Item(TransAI.ServableMan.FindID(source, src_istown));
					if (src == null) continue;
					// skip if source and destination is same
					if (src.GetKey() == dst.GetKey()) continue;
					//skip if not producing yet
					if (src.GetLastMonthProduction(cargo) < 5) continue;
					//AILog.Info("src:" + src.GetName());
					serv = Services.New(src, dst, cargo);
					priority -= Assist.ServiceCost(serv.Info.R_Distance);
					id = TransAI.ServiceMan.New(serv, priority);					
					//AILog.Info("Source:" + src.GetName());
					//speed = AIEngine.GetMaxSpeed(serv.Engines.Begin());
					//estimated_time = (serv.Distance * 429 / speed / 24) ;
					//serv.info.Priority = ;
					//AICargo.GetCargoIncome(cargo, distance, estimated_time));
					c++;
					AILog.Info(AICargo.GetCargoLabel(cargo) +
					   " from " + src.GetName()+ " to " + dst.GetName());
					if (c > 4) yield true;
				}
            }
			AILog.Info("Source count:" + c);
        }
    }
}

/**
 * Task to generate drop off point.
 * Generate table of drop off point by industry types.
 */
class Task.GenerateDropOff extends DailyTask
{
	constructor()
	{
		::DailyTask.constructor("Drop Off Point Finder");
		this.SetRemovable(true);
		this.SetKey(2);
	}

	function Execute()
	{
		::DailyTask.Execute();
		local tick = Ticker();
		local random_factor = TransAI.Info.ID;
		local destiny = AIList();
		local number = 0;
		local dst_istown = null;
		foreach (cargo, val in AICargoList()) {
			AIController.Sleep(1);
			if (TransAI.Info.Drop_off_point.rawin(cargo)) {
				local dst = TransAI.Info.Drop_off_point[cargo];
				local dstclass = TransAI.ServableMan.Item(dst);
				if (dstclass) {
					if (dstclass.IsValid()) continue;
					TransAI.ServableMan.RemoveItem(dst);
				}
				TransAI.Info.Drop_off_point.rawdelete(cargo);
			}
			destiny = Assist.NotOnWater(AIIndustryList_CargoAccepting(cargo));
			number = destiny.Count();            
			if (number) {
				destiny.Valuate(Assist.CargoCount);
				destiny.Sort(AIAbstractList.SORT_BY_VALUE, false);
				dst_istown = false;
			} else {
				destiny = Cargo.TownList_Accepting(cargo);
				destiny.Valuate(AITown.GetMaxProduction, cargo);
				destiny.Sort(AIAbstractList.SORT_BY_VALUE, false);
				dst_istown = true;
				number = destiny.Count();
			}
			
			if (number == 0) continue;
			local counter = 0;
			/* add a bit randomization support */
			for (local dst = destiny.Begin(); destiny.HasNext(); dst = destiny.Next()) {
				AIController.Sleep(1);
				if ((random_factor % number) == counter) {
					local dst_id = TransAI.ServableMan.FindID(dst, dst_istown);
					if (dst_id) {
						/* there are servable class of dst */
					} else {
						local dst_serv = Servable.New(dst, dst_istown);
						dst_id = dst_serv.GetLocation();
					}
					if (dst_id in TransAI.Info.Dont_Drop_off) continue;                	
					TransAI.Info.Drop_off_point.rawset(cargo, dst_id);
					break;
			    }
				counter++;
			}            
        }
        /*
		foreach (;
			TransAI.TaskMan.New(Task.GenerateService());idx, val in TransAI.Info.Drop_off_point) {
			AILog.Info(TransAI.ServableMan.Item(val).GetName() + ":" + AICargo.GetCargoLabel(idx));
		}*/
		Debug.ResultOf("Drop off point length", TransAI.Info.Drop_off_point.len()) > 0;
		AILog.Info(" Finished in " + tick.Elapsed());
		::TransAI.TaskMan.New(Task.GenerateService());
		this.SetKey(31);
	}
}

/**
 * Scan servable object in map
 */
class Task.GenerateServable extends DailyTask
{
	constructor()
	{
        ::DailyTask.constructor("Servable Finder");
        this.SetKey(1);
    }
    
    function Execute()
    {
    	::DailyTask.Execute();
    	TransAI.ServableMan.ScanMap();
    	TransAI.TaskMan.New(Task.GenerateDropOff());
    	this.SetKey(30);
    }	
}
