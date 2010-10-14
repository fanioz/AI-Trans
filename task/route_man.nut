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
	constructor() {
		DailyTask.constructor("Route Manager", 10);
		_silent = true;
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
			if (!My._Service_Table.rawin(grp_name)) {
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
			Info("processing", grp_name, "and friends");
			local tbl = My._Service_Table[grp_name];
			local st_id = tbl.GetSStationID();
			local src_name = (tbl.SourceIsTown() ? AITown : AIIndustry)["GetName"](tbl.GetSourceID());
			local dst_name = (tbl.DestinationIsTown() ? AITown : AIIndustry)["GetName"](tbl.GetDestinationID());
			local cargo = tbl.GetCargo();
			Info(grp_name, "has", num, "of", CLString.VehicleType(tbl.GetVType()), "vehicle");
			Info(grp_name, "is travelling from", src_name, "to", dst_name);
			Info(src_name, "is producing", tbl.GetProduction(), "of", XCargo.Label[cargo], "/ month");
			vhclst.Valuate(AIVehicle.GetReliability);
			if (tbl.AllowAdd() && Money.Get(AIEngine.GetPrice(tbl.GetEngine()))) {
				foreach(vhc, real in vhclst) {
					XVehicle.TryDuplicate(vhc);
					break;
				}
			}
			return Money.Pay();
		}
		_checked.Clear();
	}
}
