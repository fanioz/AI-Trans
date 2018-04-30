/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Task to manage all vehicle
 */
class Task.Vehicle_Mgr extends DailyTask
{
	_check_list = CLList();
	constructor() {
		DailyTask.constructor("Vehicle Manager", 3);
	}

	function On_Start() {
		local cur_date = AIDate.GetCurrentDate();
		local max_reg = 10;
		local lst = CLList(AIVehicleList());
		lst.RemoveList(_check_list);
		if (lst.IsEmpty()) _check_list.Clear();
		lst.Valuate(AIVehicle.GetAgeLeft);
		lst.SortValueAscending();
		foreach(idx, age in lst) {
			if (max_reg == 0) break;
			max_reg --;
			_check_list.AddItem(idx, age);
			local name = AIVehicle.GetName(idx);
			//=============== Unregistered vehicle
			if (!XVehicle.IsRegistered(idx)) {
				Info("Try to registering", name);
				if (AIVehicle.HasSharedOrders(idx)) AIOrder.UnshareOrders(idx);
				if (XVehicle.Register(idx)) {
					XVehicle.MakeGroup(idx, My._Vehicles[idx]);
				} else {
					XVehicle.TryToSend(idx);
					Service.Data.VhcToSell.rawset(idx, "Not registerable");
				}
			}
			//=============== un-grouped vehicle
			if (!AIGroup.IsValidGroup(AIVehicle.GetGroupID(idx))) {
				Info(name, "is not belong to any group");
				My._Vehicles.rawdelete(idx);
			}
			//=============== Aging vehicle
			if (age < 500) {
				Warn(name, "is getting old");
				XVehicle.TryToSend(idx);
				Service.Data.VhcToSell.rawset(idx, "Old enough");
			}

			//=============== un-profit vehicle
			if (My._No_Profit_Vhc.HasItem(idx)) {
				Warn(name, "is not profitable");
				XVehicle.TryToSend(idx);
				Service.Data.VhcToSell.rawset(idx, "Not profitable");
			}

			//=============== stopped in depot
			if (!AIVehicle.IsStoppedInDepot(idx)) continue;
			Info(name, "is inside depot");

			if (XVehicle.IsRegistered(idx)) {
				local key = My._Vehicles.rawget(idx);
				local r_saved = Service.Data.Routes[key];
				local friends = CLList(AIVehicleList_Group(r_saved.GroupID));
				if (friends.Count() == 1 && Service.SourceIsProducing(r_saved)) {
					local price = AIEngine.GetPrice(r_saved.Engine);
					if (!Money.Get(price)) {
						if (friends.IsEmpty() && My._Yearly_Profit > price) continue;
					}
					if (XVehicle.TryDuplicate(idx)) Info("duplicating succes");
				}
			}
			Debug.Echo(XVehicle.Sell(idx), "would sell", name);
			Money.Pay();
		}

		local copyclose = [];
		while (Service.Data.RouteToClose.len()>0) {
			local key = Service.Data.RouteToClose.pop();
			if (!Service.Data.Routes.rawin(key)) continue;
			local t = Service.Data.Routes[key];
			local vhcl = CLList(AIVehicleList_Group(t.GroupID));
			if (vhcl.Count() > 0) { 
				vhcl.DoValuate(XVehicle.IsSendToDepot);
				local stopped = CLList(vhcl);
				stopped.Valuate(AIVehicle.IsStoppedInDepot);
				stopped.KeepValue(1);
				stopped.DoValuate(XVehicle.Sell);
				stopped.KeepValue(1);
				vhcl.RemoveList(stopped);
				vhcl.Valuate(function(id){Service.Data.VhcToSell.rawset(id,"Closed Route");}); 
			 	copyclose.push(key);
			 	continue;
			}
			local closed = true;
			for (local c=0;c<t.StationsID.len();c++) {
				if (AIStation.IsValidStation(t.StationsID[c])) {
					if (AIStation.HasStationType(t.StationsID[c], t.StationType)) {
						Service.Data.StationToClose.rawset(t.StationsID[c], t.StationType);
						copyclose.push(key);
						closed = false;
						continue;
					}
				}
			}
			if (!closed) continue;
			if (Service.Data.Routes[key].rawin("GroupID")) AIGroup.DeleteGroup(Service.Data.Routes[key].GroupID);
			Service.Data.Routes.rawdelete(key);
		}
		Service.Data.RouteToClose.extend(copyclose);

		//clean vehicles
		foreach(i, v in Service.Data.VhcToSell) if (AIVehicle.IsStoppedInDepot(i)) XVehicle.Sell(i);
		foreach(i, v in My._Vehicles) if (!AIVehicle.IsValidVehicle(i)) My._Vehicles.rawdelete(i);
		My._No_Profit_Vhc.Valuate(AIVehicle.IsValidVehicle);
		My._No_Profit_Vhc.KeepValue(1);

		//clean station
		local toclean = clone Service.Data.StationToClose;
		foreach(idx, stype in toclean) {
			if (!AIStation.IsValidStation(idx)) {
				Service.Data.StationToClose.remove(idx);
				continue;
			}
			if (!AIStation.HasStationType(idx, stype)) {
				Service.Data.StationToClose.remove(idx);
				continue;
			}
			XStation.RemovePart(idx, stype);
		}
	}
}

