/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that connect a route by rail.
 */
class RailFirstConnector extends DailyTask
{
	_SkipList = null;
	_Skip_Dst = null;
	_Skip_Src = null;
	_VhcManager = null;
	_Serv_Cost = null;
	_Line = null;
	_PF = null;
	_PT = null;
	_MaxStep = null;
	_CurStep = null;
	_RouteCost = null;
	_Route_Found = null;
	_Max_Distance = null;
	_Min_Distance = null;
	_Last_Year = null;
	_Blocked_Cargo = null;
	_Blocked_Track = null;
	_LastSuccess = null;
	_Mgr_A = null;
	_Mgr_B = null;
	_Possible_Sources = null;
	_Possible_Dests = null;
	_PlatformLength = null;
	_WagonNum = null;
	_Vhc_Price = null;
	_Vhc_Yearly_Cost = null;
	instance = [];
	_current = null;
	constructor() {
		DailyTask.constructor("Rail First Connector", 10);
		this._current = Service.NewRoute();
		if (Service.Data.Projects.rawin("Rail")) {
			this._current = Service.Data.Projects.rawget("Rail");
		} else {
			//set new route
			this._current.VhcType = AIVehicle.VT_RAIL;
		}
		this._VhcManager = VehicleMaker(this._current.VhcType);
		this._Max_Distance = 200;
		this._Min_Distance = 50;
		this._PF = Rail_PF();
		this._MaxStep = 7000;
		this._CurStep = 0;
		this._PlatformLength = 4;
		this._WagonNum = 7;
		this._Vhc_Price = 0;
		this._Vhc_Yearly_Cost = 0;
		this._Last_Year = AIDate.GetCurrentDate();
		this._LastSuccess = 0;
		this._SkipList = CLList();
		this._Blocked_Cargo = CLList();
		this._Blocked_Track = CLList();
		this._Skip_Dst = CLList();
		this._Skip_Src = CLList();

		this._Serv_Cost = 0;
		this._RouteCost = 0;

		this._Line = false;
		this._PT = null;
		this._Route_Found = false;

		this._Mgr_A = null;
		this._Mgr_B = null;

		this._Possible_Sources = {};
		this._Possible_Dests = {};
		RailFirstConnector.instance.push(this);
		assert(RailFirstConnector.instance.len() == 1);
	}
	
	function On_Save() {
		Service.Data.Projects.rawset("Rail", this._current);
	}
	
	static function get() { return RailFirstConnector.instance[0]; } 

	function On_Start() {
		if (Service.IsNotAllowed(this._current.VhcType)) return;
		if (this._current.Track == -1) {
			local availableRail = AIRailTypeList();
			availableRail.Valuate(function(id) {
				local speed = AIRail.GetMaxSpeed(id);
				return speed == 0 ? 100000 : speed;
			});
			availableRail.RemoveList(this._Blocked_Track);
			if (availableRail.Count() == 0) {
				Info("No rail type available");
				this._Blocked_Track.Clear();
				return;
			}
			this._current.Track = availableRail.Begin();
		}
		AIRail.SetCurrentRailType(this._current.Track);
		Info ("using", CLString.RailTrackType(this._current.Track));
		
		if (!AICargo.IsValidCargo (this._current.Cargo)) {
			Service.MatchCargo(this);
			return;
		}
		Info ("cargo selected:", XCargo.Label[this._current.Cargo]);
		
		if (!AIEngine.IsValidEngine (this._current.Engine)) {
			if (!Service.SelectEngine (this)) return;
			this._current.VhcCapacity = AIEngine.GetCapacity(this._current.Wagon) * this._WagonNum;
		}
		
		if (this._Vhc_Price < 1) {
			this._Vhc_Price = AIEngine.GetPrice(this._current.Wagon) * this._WagonNum + AIEngine.GetPrice(this._current.Engine);
			this._Vhc_Yearly_Cost = AIEngine.GetRunningCost(this._current.Wagon) * this._WagonNum + AIEngine.GetRunningCost(this._current.Engine);
		}
			
		Info ("Loco engine selected:", AIEngine.GetName (this._current.Engine));
		Info ("Wagon engine selected:", AIEngine.GetName (this._current.Wagon));
		Info ("Train price:", this._Vhc_Price);
		Info ("Train Capacity:", this._current.VhcCapacity);
		Info ("Train Yearly Cost:", this._Vhc_Yearly_Cost);
		
		if (this._current.RouteIsBuilt) {
			Info ("route built");
			if (!Money.Get(this._Vhc_Price)) return;
			if (Service.MakeVehicle (this)) {
				this._current.VhcID = this._VhcManager.GetVehicle();
				this._current.MaxSpeed = AIEngine.GetMaxSpeed(this._current.Engine);
			}
			this._current.Key = Service.CreateKey(this._current.StationsID[0], this._current.StationsID[1], this._current.Cargo, this._current.VhcType, this._current.Track);
			this._current.IsValid = true;
			Service.Data.Routes.rawset(this._current.Key, clone this._current);
			
			if (!Service.Data.Projects.rawin("RouteBack"))
				Service.Data.Projects.rawset("RouteBack", []);
			Service.Data.Projects["RouteBack"].push(this._current.Key);
			
			this._Possible_Sources.rawdelete(this._current.Cargo);
			this._Possible_Dests.rawdelete(this._current.Cargo);
			this._Mgr_A = null;
			this._Mgr_B = null;
			this._LastSuccess = AIDate.GetCurrentDate() + 90;
			this._current = Service.NewRoute();
			this._current.VhcType = AIVehicle.VT_RAIL;
		} else if (Service.IsWaitingPath(this)) {
			
		} else if (this._Route_Found) {
			Info ("route found");
			if (!Money.Get(Service.GetTotalCost(this))) return;
			this._current.RouteIsBuilt = BuildInfrastructure(); 
			Info("rail route building:",  this._current.RouteIsBuilt);
		} else {
			Info("Initialize service");
			this._Line = false;
			if (this._Mgr_A == null) {
				if (Service.ServableIsValid(this._current, 0)) {
					this._Mgr_A = (this._current.IsTown[0] ? XTown : XIndustry).GetManager(this._current.ServID[0]); 
				} else {
					return this.SelectSource();
				}
			}
			Info("selected source:", this._Mgr_A.GetName());
			if (this._Mgr_B == null) {
				if (Service.ServableIsValid(this._current, 1)) {
					this._Mgr_B = (this._current.IsTown[1] ? XTown : XIndustry).GetManager(this._current.ServID[1]); 
				} else {
					return this.SelectDest();
				}
			}
			Info("selected destination:", _Mgr_B.GetName());
			if (this._current.StartPoint.len() > 0 && this._current.EndPoint.len() > 0) {
				this._PF.InitializePath(this._current.StartPoint, this._current.EndPoint, []);
				this._CurStep = 0;
				return;
			}
			switch (InitService()) {
				case 1 : this._Mgr_A = null; this._current.ServID[0] = -1;
				case 2 : this._Mgr_B = null; this._current.ServID[1] = -1;
			}
		}
		this.UpdateDistance(this);
		return Money.Pay();
	}
	
	/**
	 * check if this connector just make a route several months ago
	 */
	function JustMake(self) {
		if (self._LastSuccess > AIDate.GetCurrentDate()) {
			Info("We've just made a route");
			return true;
		}
		Info("We've may build a route now");
		return false;
	}

	/**
	 * update maximum and minimum distance yearly
	 */
	function UpdateDistance(self) {
		local date = AIDate.GetCurrentDate() - 365;
		if (date < self._Last_Year) {
			self._Max_Distance += 3;
			self._Last_Year += 365;
		}
	}

	function SelectSource() {
		Info("finding source...");
		if (!this._Possible_Sources.rawin(this._current.Cargo) || this._Possible_Sources[this._current.Cargo].IsEmpty()) this.PopulateSource();
		if (!this._Possible_Sources[this._current.Cargo].IsEmpty()) {
			Info("source left", this._Possible_Sources[this._current.Cargo].Count());
			this._current.ServID[0] = this._Possible_Sources[this._current.Cargo].Pop();
			this._current.IsTown[0] = false;
			this._Mgr_A = XIndustry.GetManager(this._current.ServID[0]);
		}
		if (this._Mgr_A == null) {
			this._current.Cargo = -1;
			this._current.Engine = -1;
			Warn("Couldn't find source");
		} else {
			Info("selecting source:", this._Mgr_A.GetName());
			this._Skip_Src.AddItem(this._Mgr_A.GetID(), 0);
		}
	}
	
	function PopulateSource() {
		local srcIndustries = AIIndustryList_CargoProducing(this._current.Cargo);
		srcIndustries.RemoveList(this._Skip_Src);
		srcIndustries.Valuate(XIndustry.IsRaw);
		srcIndustries.KeepValue(1);
		//Info("raw source left", srcIndustries.Count());
		srcIndustries.Valuate(AIIndustry.IsBuiltOnWater);
		srcIndustries.KeepValue(0);
		//Info("non wtr source left", srcIndustries.Count());
		srcIndustries.Valuate(AIIndustry.GetLastMonthTransportedPercentage, this._current.Cargo);
		srcIndustries.KeepBelowValue(Setting.Max_Transported);
		//Info("max transported source left", srcIndustries.Count());
		srcIndustries.Valuate(XIndustry.ProdValue, this._current.Cargo);
		//srcIndustries.RemoveBelowValue(this._current.VhcCapacity);
		if (this._Possible_Sources.rawin(this._current.Cargo)) {
			this._Possible_Sources[this._current.Cargo].Clear();
		} else {
			this._Possible_Sources[this._current.Cargo] <- CLList();
		}
		this._Possible_Sources[this._current.Cargo].AddList(srcIndustries);
		//Info("source left", srcIndustries.Count());
	}

	function SelectDest() {
		Info("finding destination...");
		if (!this._Possible_Dests.rawin(this._current.Cargo) || this._Possible_Dests[this._current.Cargo].IsEmpty()) this.PopulateDestination();
		if (!this._Possible_Dests[this._current.Cargo].IsEmpty()) {
			Info("destination left", this._Possible_Dests[this._current.Cargo].Count());
			this._current.ServID[1] = this._Possible_Dests[this._current.Cargo].Pop();
			this._current.IsTown[1] = false;
			this._Mgr_B = XIndustry.GetManager(this._current.ServID[1]);
		}
		if (this._Mgr_B == null) {
			this._Mgr_A = null;
			this._current.ServID[0] = -1;
			Warn("Couldn't find destination");
		} else {
			Info("selecting destination:", this._Mgr_B.GetName());
			this._Skip_Dst.AddItem(this._Mgr_B.GetID(), 0);
		}
	}
	
	function PopulateDestination() {
		local dstIndustries = AIIndustryList_CargoAccepting(this._current.Cargo);
		dstIndustries.RemoveList(this._Skip_Dst);
		local dataBind = {
			srcLoc = this._Mgr_A.GetLocation(),//
			maxDistance = this._Max_Distance,//
			minDistance = this._Min_Distance,//
			cargo = this._current.Cargo,//
			locoSpeed = AIEngine.GetMaxSpeed(this._current.Engine),//
			wagonCapacity = this._current.VhcCapacity,//
		}
		dataBind.vhcCount <- Money.Maximum() / this._Vhc_Price * 10; 
		dataBind.expense <- this._Vhc_Yearly_Cost * dataBind.vhcCount / 10;

		dstIndustries.Valuate(function(idx, db) {
		if (AIIndustry.IsBuiltOnWater(idx)) return 0;
		local dstLoc = AIIndustry.GetLocation(idx);
		local distance = AIMap.DistanceManhattan(db.srcLoc, dstLoc);
		if (!Assist.IsBetween(distance, db.minDistance, db.maxDistance)) return 0;
		local mult = Service.GetSubsidyPrice(db.srcLoc, dstLoc, db.cargo);
		local days = Assist.TileToDays(distance, db.locoSpeed) + 4;
		local income = AICargo.GetCargoIncome(db.cargo, distance, days) * mult;
		//local profit = 12 * income * product - cost;
		local profit = 365 / days * income * db.wagonCapacity * db.vhcCount / 10 - db.expense;
		//local rrate = (profit * 100 / price).tointeger();
		//print("=> :Vehicle needed: " + vhcneed + " :Cost: " + cost);
		//print("=> at distance: " + distance);
		//print("=> at speed: " + spd);
		//print("=> days: " + days);
		//print("=> base:: :income: " + income + " :Prod: " + product);
		//My.Info("=> :Profit estimated: ", profit);
		//print("=> :profit: " + profit);
		//return rrate ;
		return profit;
		}, dataBind);
		
		dstIndustries.KeepAboveValue(Money.Inflated(1000).tointeger());
		if (this._Possible_Dests.rawin(this._current.Cargo)) {
			this._Possible_Dests[this._current.Cargo].Clear();
		} else {
			this._Possible_Dests[this._current.Cargo] <- CLList();
		}
		this._Possible_Dests[this._current.Cargo].AddList(dstIndustries);	
	}
	
	function InitService() {
		local stID = this._Mgr_A.GetExistingRailStop(this._current.Track, this._current.Cargo, true);
		if (AIStation.IsValidStation(stID)) {
			//right now not handling existing station
			return 1;
		}
		stID = this._Mgr_B.GetExistingRailStop(this._current.Track, this._current.Cargo, false);
		if (AIStation.IsValidStation(stID)) {
			//right now not handling existing station
			return 2;
		}
		if (!this._Mgr_A.AllowTryStation(this._current.StationType)) return 1;
		if (!this._Mgr_B.AllowTryStation(this._current.StationType)) return 2;
		local spoint = this._Mgr_A.GetAreaForRailStation(this._current.Cargo, true);
		if (spoint.IsEmpty()) return 1;
		local dpoint = this._Mgr_B.GetAreaForRailStation(this._current.Cargo, false);
		if (dpoint.IsEmpty()) return 2;
		this._current.StartPoint = [];
		this._current.EndPoint = [];
		this._current.Stations.clear();
		this._current.StationsID.clear();
		this._current.Depots.clear();
		local stationDir = XRail.StationDirection(this._Mgr_A.GetLocation(), this._Mgr_B.GetLocation());
		local built = false;
		local ignored = [];
		foreach (dir in stationDir) {
			foreach (idx, val in spoint) {
				local sb = StationBuilder(idx, this._current.Cargo, this._Mgr_A.GetID(), this._Mgr_B.GetID(), true);
				//sb._orientation = dir;
				sb.SetTerminus(dir);
				if (sb.IsBuildable() == 0) continue;
				if (sb.Build()) {
					this._current.StartPoint.extend(sb.GetStartPath());
					this._current.Stations.push(idx);
					this._current.StationsID.push(AIStation.GetStationID(idx));
					if (AIRail.IsRailDepotTile(sb._depot)) this._current.Depots.push(sb._depot);
					built = true;
					ignored.extend(sb.GetIgnoredTiles());
					break;
				}
			}
			if (built) break;
		}
		if (this._current.StartPoint.len() == 0) return 1;
		built = false;
		foreach (dir in stationDir) {
			foreach (idx, val in dpoint) {
				local sb = StationBuilder(idx, this._current.Cargo, this._Mgr_A.GetID(), this._Mgr_B.GetID(), false);
				sb.SetTerminus(dir);
				if (sb.IsBuildable() == 0) continue;
				if (sb.Build()) {
					this._current.EndPoint.extend(sb.GetStartPath());
					this._current.Stations.push(idx);
					this._current.StationsID.push(AIStation.GetStationID(idx));
					if (AIRail.IsRailDepotTile(sb._depot)) this._current.Depots.push(sb._depot);
					built = true;
					ignored.extend(sb.GetIgnoredTiles());
					break;
				}
			}
			if (built) break;
		}
		if (this._current.EndPoint.len() == 0) return 2;
		
		_PF.InitializePath(this._current.StartPoint, this._current.EndPoint, ignored);
		this._CurStep = 0;
		return 0;
	}

	function BuildInfrastructure() {
		local path = Service.PathToArray(this._Line);
		{
			local mode = AITestMode();
			local cost = AIAccounting();
			if (XRail.BuildRail(this._Line)) {
				this._RouteCost = cost.GetCosts();
				if (!Money.Get(Service.GetTotalCost(this))) return;
			} else {
				_PF.InitializePath(this._current.StartPoint, this._current.EndPoint, []);
				Info("Path building failed. Re-find");
				this._Route_Found = false;
				return;
			}
		}
		XRail.BuildRail(this._Line);
		if (this._current.Depots.len() < 1) {
			local depot = XRail.BuildDepotOnRail(path);
			if (AIRail.IsRailDepotTile(depot)) this._current.Depots.push(depot);
			path.reverse();
			depot = XRail.BuildDepotOnRail(path);
			if (AIRail.IsRailDepotTile(depot)) this._current.Depots.push(depot);
		}
		
		if (this._current.Depots.len() > 1) {
			XRail.BuildSignal([[AIRail.GetRailDepotFrontTile(this._current.Depots[0]), this._current.Depots[0]]], 
				[[AIRail.GetRailDepotFrontTile(this._current.Depots[1]), this._current.Depots[1]]], 10);
		} else {
			XRail.BuildSignal(this._current.StartPoint, this._current.EndPoint, 10);
		}
		
		this._Line = null;
		this._Route_Found = false;
		return true;
	}
};
