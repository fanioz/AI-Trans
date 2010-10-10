/*  10.02.27 - service.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

class Service
{
	function Init(self) {
		self._Subsidies.AddList(AISubsidyList());
	self._Subsidies.Valuate (AISubsidy.IsAwarded);
		self._Subsidies.KeepValue (0);
		self._Subsidies.Valuate (AISubsidy.GetExpireDate);
		self._Subsidies.KeepAboveValue (AIDate.GetCurrentDate() + 60);
		TaskManager.New(RoadConnector());
		TaskManager.New(AirConnector());
		TaskManager.New(WaterConnector());
	}

	function CreateKey (id1, id2, cargo, vt) {

		return CLString.Join ([vt, id1, id2, XCargo.Label[cargo]], ":");
	}

	function IsServed (id1, cargo) {
		foreach (idx, tbl in My._Service_Table) {
			if (tbl.GetSourceID() != id1) continue;
			if (tbl.GetCargo() != cargo) continue;
			return true;
		}
	return false;
	}
	function Register (tbl) {
		local key = tbl.GetKey();
		if (My._Service_Table.rawin (key)) {
			My._Service_Table[key].Merge(tbl);
			return;
		}
		My._Service_Table.rawset (key, tbl);
	}
	function IsSubsidyLocationWas(id, loc, is_source) {
		local fn = XIndustry;
		if (AISubsidy[(is_source ? "GetSourceType" : "GetDestinationType")] (id) == AISubsidy.SPT_TOWN) fn = XTown;
		return fn.IsOnLocation(AISubsidy[(is_source ? "GetSourceIndex" : "GetDestinationIndex")](id), loc);
	}
    function GetSubsidyPrice(loc1, loc2, cargo) {
		foreach (s_id, v in My._Subsidies) {
			if (!AISubsidy.GetCargoType(s_id) == cargo) continue;
			if (!Service.IsSubsidyLocationWas(s_id, loc1, true)) continue;
			if (!Service.IsSubsidyLocationWas(s_id, loc2, false)) continue;
			Info ("found a subsidy service for", XCargo.Label[cargo]);
			return min(1.5, Setting.Get(Const.Settings.subsidy_multiply) + 1);
		}
		return 1;
	}

	function FindDest(cargo, vt, skip_loc) {
		local destiny = CLList();
		local manager = null;
		if (XCargo.TownStd.HasItem(cargo) || XCargo.TownEffect.HasItem(cargo)) {
			destiny.AddList(AITownList());
			destiny.Valuate (AITown.GetPopulation);
			destiny.KeepAboveValue(Setting.Min_Town_Population);
			destiny.Valuate(AITown.GetLocation);
			manager = XTown.GetManager;
		} else {
			destiny.AddList(AIIndustryList_CargoAccepting(cargo));
			if (vt == AIVehicle.VT_ROAD) {
				destiny.Valuate(AIIndustry.IsBuiltOnWater);
				destiny.KeepValue(0);
			}
			destiny.Valuate(AIIndustry.GetLocation);
			manager = XIndustry.GetManager;
		}
		local number = destiny.Count();
		local counter = 0;
		foreach (dst_id, dloc in destiny) {
			if (skip_loc.HasItem(dloc)) continue;
			if (vt == AIVehicle.VT_WATER) {
				if (!manager(dst_id).HasCoast()) {
					skip_loc.AddItem(dloc, dst_id);
					continue;
				}
			}
			if ((number % My.ID) == counter) {
				Info("destination found");
				return dloc;
			}
			counter ++;
		}
		//commit : Warn instead of Info
		Warn ("destination not found");
		return -1;
	}

	function FindSource(conn) {
		local dst_loc = conn._Mgr_B.GetLocation();
		local cargoid = conn._Cargo_ID;
		local engineid = conn._Engine_A;
		local max_dist = conn._Max_Distance;
		local ignored = conn._Skip_Src;

		local destiny = CLList();
		local fn_src = null;
		local manager = null;
		if (XCargo.TownStd.HasItem(cargoid)) {
			destiny.AddList(AITownList());
			destiny.Valuate (AITown.GetPopulation);
			destiny.KeepAboveValue(Setting.Min_Town_Population);
			fn_src = [AITown, XTown];
			manager = XTown.GetManager;
		} else {
			destiny.AddList(AIIndustryList_CargoProducing(cargoid));
			if (conn._V_Type == AIVehicle.VT_ROAD) {
				destiny.Valuate(AIIndustry.IsBuiltOnWater);
				destiny.KeepValue(0);
			}
			manager = XIndustry.GetManager;
			fn_src = [AIIndustry, XIndustry];
		}
		destiny.Valuate(Service.IsServed, cargoid);
		destiny.RemoveValue(1);
		destiny.Valuate(fn_src[0].GetLastMonthTransportedPercentage, cargoid);
		destiny.KeepBelowValue(Setting.Max_Transported);
		destiny.Valuate(fn_src[0].GetLocation);
		local ret = CLList();
		foreach (idx, loc in destiny) {
			if (ignored.HasItem(loc)) continue;
			if (dst_loc == loc) continue;
			if (conn._V_Type == AIVehicle.VT_WATER) {
				if (!manager(idx).HasCoast()) {
					conn._Skip_Src.AddItem(loc, idx);
					continue;
				}
			}
			local product = fn_src[1].ProdValue (idx, cargoid);
			if (product < AIEngine.GetCapacity(engineid)) continue;
			local distance = AIMap.DistanceManhattan (loc, dst_loc);
			if (!Assist.IsBetween(distance, 49, max_dist)) continue;
			local mult = Service.GetSubsidyPrice(loc, dst_loc, cargoid);
			local rr = Assist.Estimate (product, distance, cargoid, engineid, mult).tointeger();
			if (rr < Money.Inflated(1000)) continue;
			ret.AddItem(loc, rr);
		}
		//commit : Warn instead of Info
		Debug.Echo(ret.Count(), "source found");
		return ret;
	}
}
