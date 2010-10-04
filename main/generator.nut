 /*
    *    09.03.08
    *    generator.nut
    *
    *    Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
    *
    *    This program is free software; you can redistribute it and/or modify
    *    it under the terms of the GNU General Public License as published by
    *    the Free Software Foundation; either version 2 of the License, or
    *    (at your option) any later version.
    *
    *    This program is distributed in the hope that it will be useful,
    *    but WITHOUT ANY WARRANTY; without even the implied warranty of
    *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    *    GNU General Public License for more details.
    *
    *    You should have received a copy of the GNU General Public License
    *    along with this program; if not, write to the Free Software
    *    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
    *    MA 02110-1301, USA.
    */

/**
    *
    * Generator Class for Service, Subsidy and Position
    */
class Gen
{
    /**
     * Service Generator. Generate table of service.
     * @param main Main instance that has the table.
     */
    static function Service(main)
    {
        AILog.Info("Generate Service");
        AIController.Sleep(1);
        local min_priority = 10000000;
        local min_distance = 20;
        local min_production = 10;
        local mult_transported = 1000;
        local serv = null;
        local last_type = null;
        local speed = 0;
        local estimated_time = 0;
        /* service by drop off point */
        foreach(cargo, dst in main.drop_off_point) {
            AIController.Sleep(1);
            local src_ind_lst = NotOnWater(AIIndustryList_CargoProducing(cargo));
            src_ind_lst.Valuate(AIIndustry.GetLastMonthProduction, cargo);
            src_ind_lst.KeepAboveValue(min_production);
            src_ind_lst.Valuate(AIIndustry.GetDistanceManhattanToTile, AIIndustry.GetLocation(dst));
            src_ind_lst.KeepAboveValue(min_distance);
            foreach (src, val in src_ind_lst) {
                AIController.Sleep(1);
                serv = Services.NewTable(src, dst, cargo);
                if (serv.ID in main.expired_route)  delete main.expired_route[serv.ID];
                if (serv.ID in main.serviced_route) continue;
                if (serv.ID in main.service_tables) continue;
                serv = Services.RefreshTable(serv);
                //speed = AIEngine.GetMaxSpeed(serv.Engines.Begin());
                //estimated_time = (serv.Distance * 429 / speed / 24) ;
                local be_nice_factor = AIIndustry.GetLastMonthTransported(src, cargo) * mult_transported;
                main.service_keys.Insert(serv.ID, min_priority - AICargo.GetCargoIncome(cargo, 20, 200) + dst + be_nice_factor);
                //AICargo.GetCargoIncome(cargo, distance, estimated_time));
                main.service_tables[serv.ID] <- serv;
            }
        }

        /* generate Industries -> Town cargo services*/
        foreach (idx, cargo_id in AICargoList()) {
            AIController.Sleep(1);
            local industries = NotOnWater(AIIndustryList());
            industries.Valuate(AIIndustry.GetLastMonthProduction, cargo_id);
            industries.RemoveBelowValue(min_production);
            local town_list = AITownList();
            town_list.Valuate(Assist.TownCanAccept, cargo_id);
            town_list.RemoveValue(0);
            local number = town_list.Count();
            if (number == 0) continue;
            town_list.Valuate(AITown.GetPopulation);
            /* determine the destination town */
            local dst = -1;
            local counter = 0;
            /* add a bit randomization support */
            foreach (town, val in town_list) {
                if ((main.randomizer % number) == counter) dst = town;
                counter++;
            }
            foreach (src, val in industries) {
                AIController.Sleep(1);
                serv = Services.NewTable(src, town, cargo_id);
                if (serv.ID in main.expired_route)  delete main.expired_route[serv.ID];
                if (serv.ID in main.service_tables) continue;
                if (serv.ID in main.serviced_route) continue;
                serv = Services.RefreshTable(serv);
                if (serv.Engines.IsEmpty()) continue;
                //speed = AIEngine.GetMaxSpeed(serv.Engines.Begin());
                //estimated_time = (serv.Distance * 429 / speed / 24) ;
                main.service_keys.Insert(serv.ID, min_priority - AICargo.GetCargoIncome(cargo_id, 20, 200) + town);
                main.service_tables[serv.ID] <- serv;
            }
        }
        AILog.Info("Service Generator Stopped");
        return false;
    }

    /**
     * Position Generator. Generate position for depot and station.
     * @param heads Area of tile list that become a head
     * @param center of area
     * @param centered center first or last
     * @return yield of position table (head, body, id)
     */
    static function Pos(heads, center, centered = true)
    {
        AIController.Sleep(1);
        heads.Valuate(AIMap.DistanceManhattan, center);
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
        if (main.randomizer % 2 != 0) return;
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
            if (d < 30) continue;
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
            if (subs_service.Distance < 10) continue;
            subs_service.IsSubsidy = true;
            AILog.Info("Subsidy scheduled");
            AILog.Info(subs_service.Readable);
            main.service_keys.Insert(subs_service.ID, d - 29);
            if (subs_service.ID in main.service_tables) continue;
            main.service_tables[subs_service.ID] <- subs_service;
            return;
        }
        AILog.Info("No more Subsidy");
    }

    /**
     * Drop off type Generator. Generate table of drop off point by industry types.
     */
    static function DropOffType(random_factor)
    {
        local temp_var = {};
        local type_industries = AIIndustryTypeList();
        foreach (ind_type, val in type_industries) {
            AIController.Sleep(1);
            local cargoes = AIIndustryType.GetAcceptedCargo(ind_type);
            if (cargoes == null || cargoes.Count() == 0) continue;
            local industries = NotOnWater(AIIndustryList());
            industries.Valuate(AIIndustry.GetIndustryType);
            industries.KeepValue(ind_type);
            local number = industries.Count()
            if (number == 0) continue;
            industries.Valuate(AIIndustry.GetDistanceManhattanToTile, AIMap.GetTileIndex(1, 1));
            industries.Sort(AIAbstractList.SORT_BY_VALUE, true);
            local destiny = -1;
            local counter = 0;
            /* add a bit randomization support */
            for (local dst = industries.Begin(); industries.HasNext(); dst = industries.Next()) {
                AIController.Sleep(1);
                if ((random_factor % number) == counter) destiny = dst;
                /*AILog.Info("c:" + counter + ":dest " + dest + ":number:" + number);*/
                counter++ ;
            }
            if (!AIIndustry.IsValidIndustry(destiny)) continue;
            foreach(cargo, val in cargoes) {
                AIController.Sleep(1);
                if (!AIIndustry.IsCargoAccepted(destiny, cargo)) continue;
                if (cargoes.Count() > 1) {
                    temp_var[cargo] <- destiny;
                } else if (!temp_var.rawin(cargo)) temp_var[cargo] <- destiny;
            }
        }
        /*
        foreach (idx, val in temp_var) {
          AILog.Info(AIIndustry.GetName(val) + ":" + AICargo.GetCargoLabel(idx));
        } */
        return temp_var;
    }
}
