/**
 *      09.03.08
 *      generator.nut
 *
 *      Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */
class Gen{}
function Gen::Service(max_num)
{
  AILog.Info("Generate Service");
  AIController.Sleep(1);
	local counter = 10000;
	local serv = null;
	local cargos = HighPriceCargos();
	local last_type = null;
	for (local cargo_ID = cargos.Begin(); cargos.HasNext(); cargo_ID = cargos.Next()) {
	  AIController.Sleep(1);
	  local dstIndLst = NotOnWater(AIIndustryList_CargoAccepting (cargo_ID));
    dstIndLst.Valuate(AIIndustry.GetLocation);
    dstIndLst.Sort(AIAbstractList.SORT_BY_VALUE, true);    
	  for (local dst = dstIndLst.Begin(); dstIndLst.HasNext();dst = dstIndLst.Next()) {
	    AIController.Sleep(1);
	    if (AIIndustry.GetIndustryType(dst) == last_type) continue;
	    last_type = AIIndustry.GetIndustryType(dst);
	    local cargo2 = AIIndustryType.GetAcceptedCargo(last_type);
	    for (local cargo_2_ID = cargo2.Begin(); cargo2.HasNext(); cargo_2_ID = cargo2.Next()) {
	      AIController.Sleep(1);
	      local src_ind_lst = NotOnWater(AIIndustryList_CargoProducing(cargo_2_ID));
	      src_ind_lst.Valuate(AIIndustry.GetDistanceManhattanToTile, AIIndustry.GetLocation(dst));
	      src_ind_lst.Sort(AIAbstractList.SORT_BY_VALUE, true);
	      src_ind_lst.KeepAboveValue(10);
	      src_ind_lst.Valuate(AIIndustry.GetLastMonthProduction, cargo_2_ID);
	      src_ind_lst.KeepAboveValue(10);
	      for (local src = src_ind_lst.Begin(); src_ind_lst.HasNext(); src = src_ind_lst.Next()) {
	        AIController.Sleep(1);
	        serv = Services(src, dst, cargo_2_ID);
	        if (service_key.Exists(serv.Info.CurrentID)) continue;
	        service_key.Insert(serv.Info.CurrentID, counter + AIIndustry.GetDistanceManhattanToTile(src, AIIndustry.GetLocation(dst)));
	        serv.Info.SourceIsTown = false;
	        serv.Info.DestinationIsTown = false;
	        serv.Update();
	        service_table[serv.Info.CurrentID] <- serv;
	        if (service_key.Count() > max_num) yield true;
	      }
	    }      
	  }
	  local min_pop = 300;
	  local dst_town_lst = AITownList();
	  dst_town_lst.Valuate(AITown.GetPopulation);
	  dst_town_lst.KeepBelowValue(min_pop);
	  dst_town_lst.Valuate(AITown.GetLocation);
	  dst_town_lst.Sort(AIAbstractList.SORT_BY_VALUE, true);
    /*
	  for (local dst_town = dst_town_lst.Begin(); dst_town_lst.HasNext(); dst_town = dst_town_lst.Next()) {
	    
	  }
    */
  }
  AILog.Info("Service Generator Stopped");
	return false;
}

function Gen::Pos(rad, pos, is_town)
{
	local heads =  (is_town) ? Tile.Roads(Tile.Flat(Tile.Radius(pos, rad))) : Tile.Flat(Tile.Radius(pos, rad)); ;
	for(local head = heads.Begin(); heads.HasNext(); head = heads.Next()){
	  local bodies = Tile.BodiesOf(head);
	  for(local body = bodies.Begin(); bodies.HasNext(); body = bodies.Next()){
	    if (!is_town) head = FrontOf(body, pos);
	    local _pos =  PosClass();
      _pos.Body = body;
	    _pos.Head = head;
	    yield _pos;
    }
  }
  return false;
}

function Gen::Subsidy()
{
  local list = AISubsidyList();
	AILog.Info("Try to find one validated subsidy");
	list.Valuate(AISubsidy.IsValidSubsidy);
	list.RemoveValue(0);
	list.Valuate(AISubsidy.IsAwarded);
	list.RemoveValue(1);
	while (list.Count() > 0) {
	  yield list.Begin();
	  list.RemoveTop(1);
	}
	return false;
}
