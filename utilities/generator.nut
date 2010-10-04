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
 * Generator Class for Service, Subsidy and Position
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
                local _pos =  Platform();
                _pos.SetBody(body);
                _pos.SetHead(head);
                yield _pos;
            }
        }
        return false;
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
 * Yield Task to generate service
 */
class Task.GenerateService extends YieldTask
{
	constructor()
	{
		::YieldTask.constructor("Service Generator");
		::YieldTask.SetRepeat(true);
		::YieldTask.SetKey(5);
	}

	function _exec()
    {
    	::YieldTask._exec;        
        local min_priority = 10000000;
        local min_distance = 20;
        local min_production = 10;
        local mult_transported = 100;
        local serv = null;
        local last_type = null;
        local speed = 0;
        local estimated_time = 0;
		local src_lst = null;
		local src = null, dst = null;
		local dst_istown = null, src_istown = null; 
        foreach(cargo, val in  Cargo.Sorted()) {
            AIController.Sleep(1);
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
			src_lst.Valuate(Assist.ServiceCost, src_istown, cargo);
			src_lst.RemoveBelowValue(min_production);
			//AILog.Info("Count of src:" + src_lst.Count());
            local c = 0;
			local key = "";
			local id = 0;
            foreach (source, val in src_lst) {
                AIController.Sleep(1);
				key = Services.CreateID(source, dst.GetID(), cargo);
				id = TransAI.ServiceMan.FindKey(key);
				if (id) {
					AILog.Info("Found duplicate");
					//TODO: upgrade services
					
				/// service key not found
				} else {
					src = TransAI.ServableMan.Item(TransAI.ServableMan.FindID(source, src_istown));
					if (src == null) continue;
					// skip if source and destination is same
					if (src.GetKey() == dst.GetKey()) continue;
					//AILog.Info("src:" + src.GetName());
					//src.SetTown(src.IsTown());					
					serv = Services.New(src, dst, cargo);
					id = TransAI.ServiceMan.New(serv, AICargo.GetCargoIncome(cargo, 20, 200));					
					//AILog.Info("Source:" + src.GetName());
					//speed = AIEngine.GetMaxSpeed(serv.Engines.Begin());
					//estimated_time = (serv.Distance * 429 / speed / 24) ;
					//serv.info.Priority = ;
					//AICargo.GetCargoIncome(cargo, distance, estimated_time));
					c++;
					AILog.Info(AICargo.GetCargoLabel(cargo) +
					   " from " + src.GetName()+ " to " + dst.GetName());
					yield c;
				}
            }
			AILog.Info("Source count:" + c);
        }
        AILog.Info("Service Generator Stopped");
    }
}

/**
 * Task to generate drop off point.
 * Generate table of drop off point by industry types.
 */
class Task.GenerateDropOff extends TaskItem
{
	constructor()
	{
		::TaskItem.constructor("Drop Off Point Generator");
		::TaskItem.SetRemovable(true);
		::TaskItem.SetKey(3);
	}

	function Execute()
	{
		::TaskItem.Execute();
		local tick = Ticker();
		local random_factor = TransAI.Info.ID;
		local destiny = AIList();
		local number = 0;
		local dst_istown = null;
		foreach (cargo, val in AICargoList()) {
			AIController.Sleep(1);
			destiny = Assist.NotOnWater(AIIndustryList_CargoAccepting(cargo));
			number = destiny.Count();            
			if (number) {
				destiny.Valuate(Assist.CargoCount);
				destiny.Sort(AIAbstractList.SORT_BY_VALUE, false);
				dst_istown = false;
			} else {
				destiny = Cargo.TownList_Accepting(cargo);
				destiny.Valuate(AITown.GetPopulation);
				destiny.Sort(AIAbstractList.SORT_BY_VALUE, true);
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
					TransAI.Info.Drop_off_point.rawset(cargo, dst_id);
					break;
			    }
				counter++;
			}            
        }
        /*
		foreach (idx, val in TransAI.Info.Drop_off_point) {
			AILog.Info(TransAI.ServableMan.Item(val).GetName() + ":" + AICargo.GetCargoLabel(idx));
		}*/
		AILog.Info("Drop off point Finished in " + tick.Elapsed());
		TransAI.DropPointIsValid = true;
	}
}

class Task.GenerateServable extends DailyTask
{
	constructor()
	{
        ::DailyTask.constructor("Servable Object scanner");
        ::DailyTask.SetRemovable(false);
        ::DailyTask.SetKey(2);
    }
    
    function Execute()
    {
    	::DailyTask.Execute();
    	TransAI.ServableMan.ScanMap();
    	::DailyTask.SetKey(30);
    }	
}
