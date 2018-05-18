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
	_Source_ID = null;
	_Dest_ID = null;
	_Serv_Cost = null;
	_Line = null;
	_PF = null;
	_PT = null;
	_RouteCost = null;
	_Route_Found = null;
	_Station_Built = null;
	_Max_Distance = null;
	_Min_Distance = null;
	_Last_Year = null;
	_Blocked_Cargo = null;
	_Blocked_Track = null;
	_Production = null;
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
		this._PlatformLength = 4;
		this._WagonNum = 7;
		this._Vhc_Price = 0;
		this._Vhc_Yearly_Cost = 0;
		_Last_Year = AIDate.GetCurrentDate();
		_LastSuccess = 0;
		_SkipList = CLList();
		_Blocked_Cargo = CLList();
		_Blocked_Track = CLList();
		_Skip_Dst = CLList();
		_Skip_Src = CLList();

		_Source_ID = -1;
		_Dest_ID = -1;

		_Serv_Cost = 0;
		_RouteCost = 0;
		_Production = 0;

		_Line = false;
		_PT = null;

		_Route_Found = false;
		_Station_Built = false;

		_Mgr_A = null;
		_Mgr_B = null;

		_Possible_Sources = {};
		_Possible_Dests = {};
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
			if (!Service.MakeVehicle (this)) return;
			this._current.VhcID = this._VhcManager.GetVehicle();
			this._current.Key = Service.CreateKey(this._current.StationsID[0], this._current.StationsID[1], this._current.Cargo, this._current.VhcType);
			this._current.MaxSpeed = AIEngine.GetMaxSpeed(this._current.Engine);
			this._current.IsValid = true;
			Service.Data.Routes.rawset(this._current.Key, clone this._current);
			this._Mgr_A = null;
			this._Mgr_B = null;
			this._LastSuccess = AIDate.GetCurrentDate() + 90;
			this._current = Service.NewRoute();
			this._current.VhcType = AIVehicle.VT_RAIL;
		} else if (Service.IsWaitingPath(this)) {
			
		} else if (_Route_Found) {
			Info ("route found");
			if (!Money.Get(Service.GetTotalCost(this))) return;
			this._current.RouteIsBuilt = BuildInfrastructure(); 
			this._Route_Found = false;
			this._Line = null;
			Info("rail route building:",  this._current.RouteIsBuilt);
		} else {
			Info("Initialize service");
			_Line = false;
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
				return;
			}
			switch (InitService()) {
				case 1 : this._Mgr_A = null; this._current.ServID[0] = -1;
				case 2 : this._Mgr_B = null; this._current.ServID[1] = -1;
			}
		}
		UpdateDistance(this);
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
		local stationDir = XRail.StationDirection(this._Mgr_A.GetLocation(), this._Mgr_B.GetLocation());
		local built = false;
		foreach (dir in stationDir) {
			foreach (idx, val in spoint) {
				local sb = StationBuilder(idx, this._current.Cargo, this._Mgr_A.GetID(), this._Mgr_B.GetID(), true);
				sb._orientation = dir;
				if (sb.IsBuildable() == 0) continue;
				if (sb.Build()) {
					this._current.StartPoint.extend(sb.GetStartPath());
					this._current.Stations.push(idx);
					this._current.StationsID.push(AIStation.GetStationID(idx));
					built = true;
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
				sb._orientation = dir;
				if (sb.IsBuildable() == 0) continue;
				if (sb.Build()) {
					this._current.EndPoint.extend(sb.GetStartPath());
					this._current.Stations.push(idx);
					this._current.StationsID.push(AIStation.GetStationID(idx));
					built = true;
					break;
				}
			}
			if (built) break;
		}
		if (this._current.EndPoint.len() == 0) return 2;
		
		_PF.InitializePath(this._current.StartPoint, this._current.EndPoint, []);
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
				return;
			}
		}
		XRail.BuildRail(this._Line);
		this._current.Depots.clear();
		local depot = XRail.BuildDepotOnRail(path);
		if (AIRail.IsRailDepotTile(depot)) this._current.Depots.push(depot);
		path.reverse();
		depot = XRail.BuildDepotOnRail(path);
		if (AIRail.IsRailDepotTile(depot)) this._current.Depots.push(depot);
		XRail.BuildSignal(this._current.Depots[0], this._current.Depots[1], 2);
		return true;
	}
	
	function BuildTerminusSE(base) {
		this._buildRailTrack(base, [8,9,10,11], 2, AIRail.RAILTRACK_NW_SE);
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_NW_SW);
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NW_NE);
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusNW(base) {
		this._buildRailTrack(base, [2,3,4,5], -2, AIRail.RAILTRACK_NW_SE);
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_NW_SW);
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NW_NE);
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusSW(base) {
		this._buildRailTrack(base, [4,5,12,13], 8, AIRail.RAILTRACK_NE_SW);
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_NE_SE);
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_SW);
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_NE);
	}
	
	function BuildTerminusNE(base) {
		this._buildRailTrack(base, [-1,-2,-9,-10], -8, AIRail.RAILTRACK_NE_SW);
		this._buildRailTrack(base, [-1], -8, AIRail.RAILTRACK_NE_SE);
		this._buildRailTrack(base, [-1], -8, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [-9], -8, AIRail.RAILTRACK_NW_NE);
		this._buildRailTrack(base, [-9], -8, AIRail.RAILTRACK_NW_SW);
	}
	
	function _buildRailTrack(base, coord, divisor, dir) {
		while (coord.len() > 0) {
            local c = coord.pop();
            local tile = this._getTileIndex(base, c, divisor);
            Debug.Sign(tile, "" + c);
            if (!AIRail.BuildRailTrack(tile, dir) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
	}
	
	function _getTileIndex(base, coord, divisor) {
		local x = coord % divisor;
        local y = (coord - x) / divisor;
		return base + AIMap.GetTileIndex(x, y);
	}
};

class StationBuilder extends Infrastructure 
{	
	_platformLength = null;
	_num_platforms = null;
	_stationIsTerminus = null;
	_orientation = null;
	_industryTypes = null;
	_industries = null;
	_isSourceStation = null;
	_stationType = null;
	
	static TYPE_SIMPLE = 1;
	
	constructor(base, cargo, srcIndustry, dstIndustry, isSource) {
		Infrastructure.constructor(-1, base);
		this.SetVType(AIVehicle.VT_RAIL);
		this.SetCargo(cargo);
		this._platformLength =4;
		this._num_platforms = 1;
		this._stationIsTerminus = true;
		this._orientation = AIRail.RAILTRACK_NW_SE;
		this._industries = [srcIndustry, dstIndustry];
		this._industryTypes = [AIIndustry.GetIndustryType(srcIndustry), AIIndustry.GetIndustryType(dstIndustry)];
		this._isSourceStation = isSource;
		this._stationType = StationBuilder.TYPE_SIMPLE;
	}
	
	function IsBuildable() {
		//X = NESW; Y = NWSE
		local t = XTile.NW_Of(this.GetLocation(),1);
		local x = this._num_platforms;
		local y = this._platformLength + 2;
		if (this._orientation == AIRail.RAILTRACK_NE_SW) {
			y = this._num_platforms;
			x = this._platformLength + 2;
			t = XTile.NE_Of(this.GetLocation(), 1);
		}
		//Debug.Pause(t,"base x:"+x+"-y:"+y);
		return XTile.IsBuildableRange(t, x, y);
	}
	
	function Build() {
		local station_id = XStation.FindIDNear(this.GetLocation(), 8);
		local distance = AIIndustry.GetDistanceManhattanToTile(this._industries[0], AIIndustry.GetLocation(this._industries[1]));
		if (this._stationType == StationBuilder.TYPE_SIMPLE) {
			AIRail.BuildNewGRFRailStation(this.GetLocation(), this._orientation, this._num_platforms,
				this._platformLength, station_id, this.GetCargo(), this._industryTypes[0],
				this._industryTypes[1], distance, this._isSourceStation);
		}
		this.SetID(AIStation.GetStationID(this.GetLocation()));
		return AIRail.IsRailStationTile(this.GetLocation()) && XTile.IsMyTile(this.GetLocation());
	}
	
	function GetStartPath() {
		local ret = []; //[Start, Before] [End, After]
		if (this._stationType == StationBuilder.TYPE_SIMPLE) {
			if (this._orientation == AIRail.RAILTRACK_NW_SE) {
				ret.push([XTile.NW_Of(this.GetLocation(),1), this.GetLocation()]);
				ret.push([XTile.SE_Of(this.GetLocation(),this._platformLength), XTile.SE_Of(this.GetLocation(),this._platformLength-1)]);
			}
			if (this._orientation == AIRail.RAILTRACK_NE_SW) {
				ret.push([XTile.NE_Of(this.GetLocation(),1), this.GetLocation()]);
				ret.push([XTile.SW_Of(this.GetLocation(),this._platformLength), XTile.SW_Of(this.GetLocation(),this._platformLength-1)]);
			}
		}
		return ret;
	}
}
