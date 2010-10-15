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
					Service.Register(My._Vehicles[idx]);
				} else {
					XVehicle.TryToSend(idx);
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
				if (XVehicle.IsRegistered(idx)) {
					XVehicle.GetReplacement(My._Vehicles.rawget(idx));
				}
			}

			//=============== un-profit vehicle
			if (My._No_Profit_Vhc.HasItem(idx)) {
				Warn(name, "is not profitable");
				XVehicle.TryToSend(idx);
			}

			//=============== stopped in depot
			if (!AIVehicle.IsStoppedInDepot(idx)) continue;
			Info(name, "is inside depot");

			if (XVehicle.IsRegistered(idx)) {
				local r_saved = My._Vehicles.rawget(idx);
				if (r_saved.GetFriends().Count() == 1 && r_saved.SourceIsProducing()) {
					local price = AIEngine.GetPrice(r_saved.GetEngine());
					if (!Money.Get(price)) {
						if (r_saved.GetFriends().IsEmpty() && My._Yearly_Profit > price) continue;
					}
					if (XVehicle.TryDuplicate(idx)) Info("duplicating succes");
				}
			} else if (AIOrder.GetOrderCount(idx) > 1) {
				Info(name, "waiting for verification team");
				continue;
			}
			Debug.Echo(XVehicle.Sell(idx), "would sell", name);
			Money.Pay();
		}

		//clean groups
		foreach(i, v in AIGroupList()) {
			if (AIVehicleList_Group(i).IsEmpty()) {
				AIGroup.DeleteGroup(i);
				break;
			}
		}

		//clean vehicles
		foreach(i, v in My._Vehicles) if (!AIVehicle.IsValidVehicle(i)) My._Vehicles.rawdelete(i);
		My._No_Profit_Vhc.Valuate(AIVehicle.IsValidVehicle);
		My._No_Profit_Vhc.KeepValue(1);

		//clean station
		local toclean = clone Service.Data.Station_2_Close;
		foreach(idx, data in toclean) {
			local id = data[0];
			if (!AIStation.IsValidStation(id)) {
				Service.Data.Station_2_Close.remove(idx);
				continue;
			}
			local stype = data[1];
			if (!AIStation.HasStationType(stype)) {
				Service.Data.Station_2_Close.remove(idx);
				continue;
			}
			XStation.RemovePart(id, stype);
		}
	}
}

