/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
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
	lastTownAction = {};
	constructor() {
		DailyTask.constructor("Route Manager", 10);
	}

	function On_Start() {
		Info("Service table count:", Service.Data.Routes.len());
		foreach(grp_name, t in Service.Data.Routes) {
			local grp_id = t.GroupID;
			local vhclst = Service.GetVehicleList(t);
			local num = vhclst.Count();
			
			if (_checked.HasItem(grp_id)) continue;
			_checked.AddItem(grp_id, 1);
			Warn("...");
			Info("processing", grp_name, "and friends");
			local src_name = (t.IsTown[0] ? AITown : AIIndustry)["GetName"](t.ServID[0]);
			local dst_name = (t.IsTown[1] ? AITown : AIIndustry)["GetName"](t.ServID[1]);
			local cargo = t.Cargo;
			local label = XCargo.Label[cargo];
			local producing = (t.IsTown[0] ? AITown : AIIndustry).GetLastMonthProduction(t.ServID[0], cargo);
			local sname = AIStation.GetName(t.StationsID[0]);
			local dname =  AIStation.GetName(t.StationsID[1]);
			Info(grp_name, "has", num, "of", CLString.VehicleType(t.VhcType));
			Info(grp_name, "Vehicle capacity:", t.VhcCapacity);
			Info(grp_name, "is travelling from", src_name, "to", dst_name);
			Info(grp_name, "uses station from", sname, "to", dname);
			Info(src_name, "is producing", producing, "of", label, "/ month");
			Info("Last build", Assist.DateStr(t.LastBuild));
			
			if (!(AIStation.IsValidStation(t.StationsID[0]) && AIStation.IsValidStation(t.StationsID[1]))) {
				Info(grp_name, "Closing route due to station(s) no longer valid");
				Service.Data.RouteToClose.push(t);
				continue;
			}
			
			if (producing < 2) {
				Info(grp_name, "Closing route due to not producing");
				Service.Data.RouteToClose.push(t);
				continue;
			}
			
			if (t.VhcType == AIVehicle.VT_AIR && Setting.Get(SetString.infrastructure_maintenance)) {
				Info("Closing air-route");
				Service.Data.RouteToClose.push(t);
				continue;
			}
			
			if (!XStation.IsAccepting(t.StationsID[1], cargo)) {
				Info(grp_name, "Closing route due to not accepting");
				Service.Data.RouteToClose.push(t);
				continue;
			}
			
			if (num == 0) {
				if (AIMap.IsValidTile(t.Depots[0])) {
					XVehicle.GetReplacement(grp_name);
				} else {
					Warn("TODO:Find a nearby depot");
				}
				continue;
			}
			
			local target = -1;
			
			if (t.IsTown[0]) target = t.ServID[0]
			else {
				target = AITile.GetTownAuthority(t.Stations[0]);
			}
			
			if ((AIController.GetSetting("allow_town_action")>0) && AITown.IsValidTown(target)) {
				if (!this.lastTownAction.rawin(target)) this.lastTownAction.rawset(target, 0);
				if (!AITown.HasStatue(target))
					if (AITown.IsActionAvailable(target, AITown.TOWN_ACTION_BUILD_STATUE))
						if (Debug.ResultOf(AITown.PerformTownAction(target, AITown.TOWN_ACTION_BUILD_STATUE), "Build statue on", src_name))
							//do not act for the AITown.Actions below
							this.lastTownAction.rawset(target, AIDate.GetCurrentDate()); 
				
				
				local jeda = AIDate.GetCurrentDate()-this.lastTownAction.rawget(target);
				local rating = AITown.GetRating(target, My.ID);
				if ((jeda > 30) && rating != AITown.TOWN_RATING_OUTSTANDING) {
					foreach (action in [AITown.TOWN_ACTION_BRIBE, AITown.TOWN_ACTION_BUY_RIGHTS, AITown.TOWN_ACTION_FUND_BUILDINGS, 
						AITown.TOWN_ACTION_ADVERTISE_LARGE, AITown.TOWN_ACTION_ADVERTISE_MEDIUM,
						AITown.TOWN_ACTION_ADVERTISE_SMALL] ) {
						if (!AITown.IsActionAvailable(target, action)) continue;
						if (Debug.ResultOf(AITown.PerformTownAction(target, action), "Action:", action,"on", src_name)) {
							this.lastTownAction.rawset(target, AIDate.GetCurrentDate());
							break;
						}
					}
				}
			}
			
			local waiting = AIStation.GetCargoWaiting(t.StationsID[0], cargo);
			if (t.VhcCapacity > Debug.Echo(waiting, "at", sname, label, "waiting:")) continue;
			if (Debug.Echo(AIStation.GetCargoRating(t.StationsID[0], cargo), "at", sname, label, "rating:") > 70) continue;

			if (t.VhcType == AIVehicle.VT_RAIL) {
				if (!t.RouteBackIsBuilt && num > 2) {
					vhclst.Valuate(AIVehicle.GetAgeLeft);
					vhclst.SortValueAscending();
					local id = vhclst.Begin();
					XVehicle.TryToSend(id);
					continue;
				}
			}

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
			
			if (t.VhcType == AIVehicle.VT_AIR) {
				local dstation = XStation.GetManager(t.StationsID[1], t.StationType);
				
				if (!dstation.CanAddNow(cargo)) {
					Info(dstation.GetName(), "is busy");
					continue;
				}

				if (dstation.GetOccupancy() > 99) {
					Info(dstation.GetName(), "is out of space");
					continue;
				}
			}
			
			Info("Time to make clone");
			if (!AIMap.IsValidTile(t.Depots[0])) {
				Warn("TODO:Find a nearby depot");
				continue;
			}
			Money.Get(AIEngine.GetPrice(t.Engine) * 2);
			if (XVehicle.TryDuplicate(vhc)) Service.Data.Routes[grp_name].LastBuild = AIDate.GetCurrentDate() + 10;
			return Money.Pay();
		}
		_checked.Clear();
	}
}
