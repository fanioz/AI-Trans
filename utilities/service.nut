/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

class Service
{
	/* for save/load */
	static Data = {
		RouteToClose = []
		StationToClose = {}
		VhcToSell = {}
		Events = []
		Routes = {}
		RailStations = {}
		Projects = {}
	};

	function Init(self) {
		self._Subsidies.AddList(AISubsidyList());
		self._Subsidies.Valuate(AISubsidy.IsAwarded);
		self._Subsidies.KeepValue(0);
		self._Subsidies.Valuate(AISubsidy.GetExpireDate);
		self._Subsidies.KeepAboveValue(AIDate.GetCurrentDate() + 60);
		if (self._Load) {
			foreach(idx, val in self._Load) {
				if (!Service.Data.rawin(idx)) {
					Warn("index", idx, "not found. Have value:", val);
					Service.Data.rawset(idx, val);
				}

				Service.Data[idx] = val;
			}
		}

		TaskManager.New(RoadConnector());
		TaskManager.New(AirConnector());
		TaskManager.New(WaterConnector());
		TaskManager.New(RailFirstConnector());
	}

	function CreateKey(id1, id2, cargo, vt, tt) {

		return CLString.Join([vt, tt, id1, id2, XCargo.Label[cargo]], ":");
	}

	function IsServed(id1, cargo) {
		foreach(idx, tbl in Service.Data.Routes) {
			if (tbl.ServID[0] != id1) continue;
			if (tbl.Cargo != cargo) continue;
			return true;
		}
		return false;
	}

	function IsSubsidyLocationWas(id, loc, is_source) {
		local fn = XIndustry;
		if (AISubsidy[(is_source ? "GetSourceType" : "GetDestinationType")](id) == AISubsidy.SPT_TOWN) fn = XTown;
		return fn.IsOnLocation(AISubsidy[(is_source ? "GetSourceIndex" : "GetDestinationIndex")](id), loc);
	}

	function GetSubsidyPrice(loc1, loc2, cargo) {
		foreach(s_id, v in My._Subsidies) {
			if (!AISubsidy.GetCargoType(s_id) == cargo) continue;
			if (!Service.IsSubsidyLocationWas(s_id, loc1, true)) continue;
			if (!Service.IsSubsidyLocationWas(s_id, loc2, false)) continue;
			Info("found a subsidy service for", XCargo.Label[cargo]);
			return min(1.5, Setting.Get(SetString.subsidy_multiply) + 1);
		}
		return 1;
	}

	function FindDest(cargo, vt, skip_loc) {
		local destiny = CLList();
		local manager = null;
		if (XCargo.TownStd.HasItem(cargo) || XCargo.TownEffect.HasItem(cargo)) {
			destiny.AddList(AITownList());
			destiny.Valuate(AITown.GetPopulation);
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
		foreach(dst_id, dloc in destiny) {
			if (skip_loc.HasItem(dloc)) continue;
			if (vt == AIVehicle.VT_WATER) {
				if (!manager(dst_id).HasCoast()) {
					skip_loc.AddItem(dloc, dst_id);
					continue;
				}
			}
			if (number % (My.ID + 1) == counter) {
				Info("destination found");
				return dloc;
			}
			counter ++;
		}
		//commit : Warn instead of Info
		Warn("destination not found");
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
			destiny.Valuate(AITown.GetPopulation);
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
		destiny.Valuate(fn_src[0].GetLastMonthTransportedPercentage, cargoid);
		destiny.KeepBelowValue(Setting.Max_Transported);
		destiny.Valuate(fn_src[0].GetLocation);
		local ret = CLList();
		foreach(idx, loc in destiny) {
			if (ignored.HasItem(loc)) continue;
			if (dst_loc == loc) continue;
			if (Service.IsServed(idx, cargoid)) continue;
			if (conn._V_Type == AIVehicle.VT_WATER) {
				if (!manager(idx).HasCoast()) {
					conn._Skip_Src.AddItem(loc, idx);
					continue;
				}
			}
			local product = fn_src[1].ProdValue(idx, cargoid);
			if (product < AIEngine.GetCapacity(engineid)) continue;
			local distance = AIMap.DistanceManhattan(loc, dst_loc);
			if (!Assist.IsBetween(distance, 49, max_dist)) continue;
			local mult = Service.GetSubsidyPrice(loc, dst_loc, cargoid);
			local rr = Assist.Estimate(product, distance, cargoid, engineid, mult).tointeger();
			if (rr < Money.Inflated(1000)) continue;
			ret.AddItem(loc, rr);
		}
		//commit : Warn instead of Info
		Debug.Echo(ret.Count(), "source found");
		return ret;
	}

	/**
	 * Return the two nodes at a start of a path.
	 */
	static function GetStartTiles(path) {
		assert(path instanceof AyPath);
		assert(path.Count() > 1);
		local p = Service.PathToArray(path);
		return [p.pop(), p.pop()];
	}

	/**
	 * Return the two nodes at a end of a path.
	 */
	static function GetEndTiles(path) {
		assert(path instanceof AyPath);
		assert(path.Count() > 1);
		return [path.GetTile(), path.GetParent().GetTile()];
	}

	/**
	 * Convert path class to array
	 * this would also make the end tile on index 0
	 */
	static function PathToArray(path) {
		assert(path instanceof AyPath);
		local ar = [path.GetTile()];
		local prev = path.GetParent();
		while (prev) {
			ar.push(prev.GetTile());
			prev = prev.GetParent();
		}
		return ar;
	}
	
	/**
	 * check if this vehicle type was allowed to do something
	 */
	static function IsNotAllowed(cur_vt) {
		local v = CLString.VehicleType(cur_vt);

		if (AIGameSettings.IsDisabledVehicleType(cur_vt) || AIController.GetSetting(v) == 0) {
			Warn(v, "was disabled in game");
			return true;
		}

		Info("building", v, "is allowed");
		local veh_list = AIVehicleList();
		veh_list.Valuate(AIVehicle.GetVehicleType);
		veh_list.KeepValue(cur_vt);

		if (veh_list.IsEmpty()) return false;

		local vhcc = (veh_list.Count() * 1.1).tointeger();
		local maxvhc = Setting.GetMaxVehicle(cur_vt);
		Info("max.:", maxvhc);
		Info("we have", maxvhc - vhcc, "left to build", v);
		return vhcc > maxvhc;
	}
	
	function SourceIsProducing(route) {
		return (route.IsTown[0] ? AITown : AIIndustry).GetLastMonthProduction(route.ServID[0], route.Cargo) > 10;
	}
	
	function NewRoute() {
		local tabel = {
	 		IsValid = false
	 		Stations = []
			Depots = []
			Waypoints = [] ///might not needed
			StationsID = []
			Cargo = -1
			VhcType = -1
			StationType = AIStation.STATION_ANY
			IsTown = [true, true]
			ServID = [-1, -1]
			Key = ""
			VhcCapacity = 0
			VhcID = -1
	 		Orders = []
	 		Engine = -1
	 		Wagon = -1
			MaxSpeed = 0
			Track = -1
			GroupID = -1
			StartPoint = []
			EndPoint = []
			Step = 0
			RouteIsBuilt = false
			RouteBackIsBuilt = false
			LastBuild = 0
		}
		return tabel;
	}
	
	function ServableIsValid(route, i) {
		return (route.IsTown[i] ? AITown.IsValidTown : AIIndustry.IsValidIndustry)(route.ServID[i]);
	}
	
	/**
	 * selecting current cargo id for further process
	 */
	function MatchCargo(conn) {
		local cargoes = AICargoList();
		cargoes.RemoveList(conn._Blocked_Cargo);
		if (cargoes.IsEmpty()) {
			conn._Blocked_Cargo.Clear();
			Warn("cargo selection empty");
			conn._current.Track = -1;
			return;
		}
		cargoes.Valuate(XCargo.MatchSetting);
		cargoes.KeepValue(1);
		if (cargoes.IsEmpty()) {
			Warn("could not select any cargo");
			return;
		}
		cargoes.Valuate(XCargo.GetCargoIncome, 20, 200);
		conn._current.Cargo = cargoes.Begin();
		conn._current.StationType = XStation.GetTipe(conn._current.VhcType, conn._current.Cargo);
		conn._Blocked_Cargo.AddItem(conn._current.Cargo, 0);
		conn._current.Engine = -1;
	}
	
	/**
	 * selecting current engine id for further process
	 */
	function SelectEngine(conn) {
		conn._VhcManager.Reset();
		if (conn._VhcManager.HaveEngineFor(conn._current.Track)) {
			conn._VhcManager.SetCargo(conn._current.Cargo);
			local c = conn._VhcManager.CargoEngine.Count();
			Info("cargo engines found for", XCargo.Label[conn._current.Cargo], "were", c);
			if (c < 1) {
				conn._current.Cargo = -1;
				return false;
			}
			conn._VhcManager.SortEngine();
			if (conn._current.VhcType == AIVehicle.VT_RAIL) {
				c = conn._VhcManager.MainEngine.Count();
				Info("Loco found for pulling ", XCargo.Label[conn._current.Cargo], "were", c);
				if (c < 1) {
					conn._current.Cargo = -1;
					return false;
				}
				conn._current.Engine = conn._VhcManager.GetFirstLoco();
				conn._current.Wagon = conn._VhcManager.GetFirst();
			} else {
				conn._current.Engine = conn._VhcManager.GetFirst();
			}
		} else {
			Info("Could not find engine. current money:", Money.Maximum());
			conn._Blocked_Track.AddItem(conn._current.Track, 0);
			conn._current.Track = -1;
			return false;
		}
		return true;
	}
	
	/**
	 * common vehicle managers action on building vehicles
	 */
	function MakeVehicle(conn) {
		conn._VhcManager.SetCargo(conn._current.Cargo);
		conn._VhcManager.SetStationA(conn._current.Stations[0]);
		conn._VhcManager.SetStationB(conn._current.Stations[1]);
		conn._VhcManager.SetDepotA(conn._current.Depots[0]);
		conn._VhcManager.SetDepotB((conn._current.Depots.len() > 1) ? conn._current.Depots[1] : -1);
		if (conn._current.VhcType == AIVehicle.VT_RAIL) {
			conn._VhcManager.TryBuildRail();
		} else {
			conn._VhcManager.TryBuild();
		}
		if (!conn._VhcManager.IsBuilt()) {
			Warn("failed on build vehicle");
			return false;
		}
		Money.Pay();
		return conn._VhcManager.StartCloned();
	}
	
	/**
	 * estimating cost for build service
	 */
	function GetTotalCost(conn) {
		Info("engine cost", conn._Vhc_Price);
		Info("infrastructure cost", conn._Serv_Cost);
		Info("route cost", conn._RouteCost);
		local cost = 3 * conn._Vhc_Price + conn._Serv_Cost + conn._RouteCost;
		Info("total cost", cost);
		return  cost;
	}
	
	function IsWaitingPath(conn) {
		if (conn._Mgr_A == null) return false;
		if (conn._Mgr_B == null) return false;		
		if (conn._PF.IsRunning()) {
			Info(conn._MaxStep - conn._CurStep," step left for finding", conn._Mgr_A.GetName(), "=>", conn._Mgr_B.GetName());
			conn._Line = conn._PF.FindPath(200);
			conn._CurStep += 200;
			if (conn._CurStep > conn._MaxStep) {
				conn._Line = null;
				conn._CurStep = 0;
			} else 
			return true;
		}
		if (typeof conn._Line == "instance") {
			conn._RouteCost = conn._Line.GetBuildCost();
			conn._Route_Found = true;
			Assist.RemoveAllSigns();
		} else if (conn._Line == null) {
			conn._RouteCost = 0;
			conn._Route_Found = false;
			conn._Mgr_B = null;
			conn._current.ServID[1] = -1;
			this._current.StartPoint.clear();
			this._current.EndPoint.clear();
			conn._PF.Reset();
			Assist.RemoveAllSigns();
		}
		//not removing sign if line = false
		Info("route found", conn._Route_Found);
		return false;
	}
	
	function GetVehicleList(t) {
		local list1 = AIVehicleList_Station(t.StationsID[0]);
		local vhclist = AIVehicleList_Station(t.StationsID[1]);
		list1.KeepList(vhclist);
		vhclist.KeepList(list1);
		vhclist.Valuate(AIVehicle.GetVehicleType);
		vhclist.KeepValue(t.VhcType);
		return CLList(vhclist);
	}
}
