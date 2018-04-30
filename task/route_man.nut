/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Task to manage route
 */
class Task.RouteManager extends DailyTask
{
	_checked = CLList();
	_route_checked = {}; 
	constructor() {
		DailyTask.constructor("Route Manager", 10);
	}

	function On_Start() {
		local groups = CLList(AIGroupList());
		groups.Valuate(XVehicle.GroupCount);
		groups.SortValueAscending();
		Info("Service table count:", groups.Count());
		foreach(grp_id, num in groups) {
			local grp_name = AIGroup.GetName(grp_id);
			if (num == 0) {
				Warn(grp_name, "no longer has vehicle");
				continue;
			}
			local vhclst = CLList(AIVehicleList_Group(grp_id));
			if (!Service.Data.Routes.rawin(grp_name)) {
				Warn(grp_name, "couldn't process without table, kick'em out");
				XVehicle.Ungroup(vhclst.Begin());
				continue;
			}
			vhclst.Valuate(XVehicle.IsRegistered);
			vhclst.KeepValue(1);
			vhclst.RemoveList(_checked);
			if (vhclst.IsEmpty()) {
				continue;
			}
			_checked.AddList(vhclst);
			Warn("...");
			Info("processing", grp_name, "and friends");
			local t = Service.Data.Routes[grp_name];
			local src_name = (t.IsTown[0] ? AITown : AIIndustry)["GetName"](t.ServID[0]);
			local dst_name = (t.IsTown[1] ? AITown : AIIndustry)["GetName"](t.ServID[1]);
			local cargo = t.Cargo;
			local label = XCargo.Label[cargo];
			local producing = (t.IsTown[0] ? AITown : AIIndustry).GetLastMonthProduction(t.ServID[0], cargo);
			Info(grp_name, "has", num, "of", CLString.VehicleType(t.VhcType), "vehicle");
			Info(grp_name, "Vehicle capacity:", t.VhcCapacity);
			Info(grp_name, "is travelling from", src_name, "to", dst_name);
			Info(src_name, "is producing", producing, "of", label, "/ month");
			Info("Last build", Assist.DateStr(t.LastBuild));
			local sname = AIStation.GetName(t.StationsID[0]);
			local waiting = AIStation.GetCargoWaiting(t.StationsID[0], cargo);
			if (producing < 2) {
				Info(grp_name, "Closing route due to not producing");
				Service.Data.RouteToClose.push(grp_name);
			}
			if (t.VhcCapacity > Debug.Echo(waiting, "at", sname, label, "waiting:")) continue;
			if (Debug.Echo(AIStation.GetCargoRating(t.StationsID[0], cargo), "at", sname, label, "rating:") > 60) continue;
			
			if (!XStation.IsAccepting(t.StationsID[1], cargo)) {
				Info(grp_name, "Closing route due to not accepting");
				Service.Data.RouteToClose.push(grp_name);
				continue;
			}
			
			if (t.VhcType == AIVehicle.VT_AIR && Setting.Get(SetString.infrastructure_maintenance)) {
				Info("Closing air-route");
				Service.Data.RouteToClose.push(grp_name);
				continue;
			}
			
			if (t.VhcType == AIVehicle.VT_RAIL) continue; //

			local vhcs2 = CLList(AIVehicleList_Group(grp_id));
			local vhc = vhcs2.Begin();
			vhcs2.Valuate(AIVehicle.GetState);
			if (vhcs2.CountIfKeepValue(AIVehicle.VS_AT_STATION)) {
				Info(grp_name, "has vehicles in un/loading state");
				continue;
			}
			vhcs2.KeepValue(AIVehicle.VS_RUNNING);
			vhcs2.Valuate(XVehicle.IsLowSpeed);
			vhcs2.KeepValue(1);
			if (vhcs2.Count()) {
				Info(sname, "has vehicles in slow motion :D");
				continue;
			}
			local dstation = XStation.GetManager(t.StationsID[1], t.StationType);
			if (!dstation.CanAddNow(cargo)) {
				Info(dstation.GetName(), "is busy");
				continue;
			}
			if (dstation.GetOccupancy() > 99) {
				Info(dstation.GetName(), "is out of space");
				continue;
			}
			Info("Time to make clone");
			if (!AIMap.IsValidTile(t.Depots[0])) {
				Warn("TODO:Find a nearby depot");
				continue;
			}
			if (XVehicle.TryDuplicate(vhc)) Service.Data.Routes[grp_name].LastBuild = AIDate.GetCurrentDate() + 10;
			return Money.Pay();
		}
		_checked.Clear();
	}
}
