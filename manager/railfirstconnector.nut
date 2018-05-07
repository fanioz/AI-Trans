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
class RailFirstConnector extends Connector
{
	_PlatformLength = null;
	_WagonNum = null;
	_Vhc_Price = null;
	_Vhc_Yearly_Cost = null;
	_Vhc_Capacity = null;
	instance = [];
	constructor() {
		this._V_Type = AIVehicle.VT_RAIL;
		Connector.constructor("Rail First Connector", 10);
		this._S_Type = 
		this._Max_Distance = 200;
		this._Min_Distance = 50;
		this._PF = Rail_PF();
		this._PlatformLength = 4;
		this._WagonNum = 7;
		this._Vhc_Price = 0;
		this._Vhc_Yearly_Cost = 0;
		this._Vhc_Capacity = 0;
		RailFirstConnector.instance.push(this);
		assert(RailFirstConnector.instance.len() == 1);
	}
	
	static function get() { return RailFirstConnector.instance[0]; } 

	function On_Start() {
		if (Service.IsNotAllowed(_V_Type)) return;
		if (_Track == -1) {
			local availableRail = AIRailTypeList();
			availableRail.RemoveList(this._Blocked_Track);
			if (availableRail.Count() == 0) {
				Info("No rail type available");
				this._Blocked_Track.Clear();
				return;
			}
			this._Track = availableRail.Begin();
			AIRail.SetCurrentRailType(this._Track);
		}
		Info ("using", CLString.RailTrackType(_Track));
		if (!AICargo.IsValidCargo (_Cargo_ID)) {
			MatchCargo(this);
			return;
		}
		Info ("cargo selected:", XCargo.Label[_Cargo_ID]);
		if (!AIEngine.IsValidEngine (this._Engine_A)) {
			SelectEngine (this);
			local c = this._VhcManager.MainEngine.Count();
			Info("Loco found for pulling ", XCargo.Label[this._Cargo_ID], "were", c);
			if (c < 1) {
				this._Cargo_ID = -1;
				this._Engine_A = -1;
				return;
			}
			this._Engine_A = this._VhcManager.GetFirstLoco();
			this._Engine_B = this._VhcManager.GetFirst();
			this._Vhc_Price = AIEngine.GetPrice(this._Engine_B) * this._WagonNum + AIEngine.GetPrice(this._Engine_A);
			this._Vhc_Yearly_Cost = AIEngine.GetRunningCost(this._Engine_B) * this._WagonNum + AIEngine.GetRunningCost(this._Engine_A);
			this._Vhc_Capacity = AIEngine.GetCapacity(this._Engine_B) * this._WagonNum;
		}
		Info ("Loco engine selected:", AIEngine.GetName (_Engine_A));
		Info ("Wagon engine selected:", AIEngine.GetName (_Engine_B));
		Info ("Train price:", this._Vhc_Price);
		Info ("Train Capacity:", this._Vhc_Capacity);
		Info ("Train Yearly Cost:", this._Vhc_Yearly_Cost);
		
		if (this._Route_Built) {
			Info ("route built");
			if (!Money.Get(this._Vhc_Price)) return;
			this.MakeVehicle (this);
			this._Route_Built = false;
			this._Engine_A = -1;
			this._Mgr_A = null;
			this._Cargo_ID = -1;
			this._LastSuccess = AIDate.GetCurrentDate() + 90;
		} else if (IsWaitingPath(this)) {
			
		} else if (_Route_Found) {
			Info ("route found");
			if (!Money.Get(GetTotalCost(this))) return;
			this._Start_Point = _Line.GetTile();
			this._End_Point = _Line.GetFirstTile();
			this._Route_Built = BuildInfrastructure();
			this._Route_Found = false;
			this._Line = null;
			this._Mgr_A = null;
			Info("rail route building:",  this._Route_Built);
		} else {
			Info("Initialize service");
			_Line = false;
			if (this._Mgr_A == null) return this.SelectSource();
			Info("selected source:", this._Mgr_A.GetName());
			if (_Mgr_B == null) return this.SelectDest();
			Info("selected destination:", _Mgr_B.GetName());
			switch (InitService()) {
				case 1 : _Mgr_A = null;
				case 2 : _Mgr_B = null; break;
			}
		}
		UpdateDistance(this);
		return Money.Pay();
	}
	
	function SelectSource() {
		Info("finding source...");
		if (!this._Possible_Sources.rawin(this._Cargo_ID) || this._Possible_Sources[this._Cargo_ID].IsEmpty()) this.PopulateSource();
		if (!this._Possible_Sources[this._Cargo_ID].IsEmpty()) {
			Info("source left", this._Possible_Sources[this._Cargo_ID].Count());
			this._Mgr_A = XIndustry.GetManager(this._Possible_Sources[this._Cargo_ID].Pop());
		}
		if (this._Mgr_A == null) {
			this._Cargo_ID = -1;
			this._Engine_A = -1;
			Warn("Couldn't find source");
		} else {
			Info("selecting source:", this._Mgr_A.GetName());
			this._Skip_Src.AddItem(this._Mgr_A.GetID(), 0);
		}
	}
	
	function PopulateSource() {
		local srcIndustries = AIIndustryList_CargoProducing(this._Cargo_ID);
		srcIndustries.RemoveList(this._Skip_Src);
		srcIndustries.Valuate(XIndustry.IsRaw);
		srcIndustries.KeepValue(1);
		//Info("raw source left", srcIndustries.Count());
		srcIndustries.Valuate(AIIndustry.IsBuiltOnWater);
		srcIndustries.KeepValue(0);
		//Info("non wtr source left", srcIndustries.Count());
		srcIndustries.Valuate(AIIndustry.GetLastMonthTransportedPercentage, this._Cargo_ID);
		srcIndustries.KeepBelowValue(Setting.Max_Transported);
		//Info("max transported source left", srcIndustries.Count());
		srcIndustries.Valuate(XIndustry.ProdValue, this._Cargo_ID);
		//srcIndustries.RemoveBelowValue(this._Vhc_Capacity);
		if (this._Possible_Sources.rawin(this._Cargo_ID)) {
			this._Possible_Sources[this._Cargo_ID].Clear();
		} else {
			this._Possible_Sources[this._Cargo_ID] <- CLList();
		}
		this._Possible_Sources[this._Cargo_ID].AddList(srcIndustries);
		//Info("source left", srcIndustries.Count());
	}

	function SelectDest() {
		Info("finding destination...");
		if (!this._Possible_Dests.rawin(this._Cargo_ID) || this._Possible_Dests[this._Cargo_ID].IsEmpty()) this.PopulateDestination();
		if (!this._Possible_Dests[this._Cargo_ID].IsEmpty()) {
			Info("destination left", this._Possible_Dests[this._Cargo_ID].Count());
			this._Mgr_B = XIndustry.GetManager(this._Possible_Dests[this._Cargo_ID].Pop());
		}
		if (this._Mgr_B == null) {
			this._Mgr_A = null;
			Warn("Couldn't find destination");
		} else {
			Info("selecting destination:", this._Mgr_B.GetName());
			this._Skip_Dst.AddItem(this._Mgr_B.GetID(), 0);
		}
	}
	
	function PopulateDestination() {
		local dstIndustries = AIIndustryList_CargoAccepting(this._Cargo_ID);
		dstIndustries.RemoveList(this._Skip_Dst);
		local dataBind = {
			srcLoc = this._Mgr_A.GetLocation(),//
			maxDistance = this._Max_Distance,//
			minDistance = this._Min_Distance,//
			cargo = this._Cargo_ID,//
			locoSpeed = AIEngine.GetMaxSpeed(this._Engine_A),//
			wagonCapacity = this._Vhc_Capacity,//
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
		if (this._Possible_Dests.rawin(this._Cargo_ID)) {
			this._Possible_Dests[this._Cargo_ID].Clear();
		} else {
			this._Possible_Dests[this._Cargo_ID] <- CLList();
		}
		this._Possible_Dests[this._Cargo_ID].AddList(dstIndustries);	
	}
	
	function InitService() {
		local stID = this._Mgr_A.GetExistingRailStop(this._Track, this._Cargo_ID, true);
		if (AIStation.IsValidStation(stID)) {
			//right now not handling existing station
			return 1;
		}
		stID = this._Mgr_B.GetExistingRailStop(this._Track, this._Cargo_ID, false);
		if (AIStation.IsValidStation(stID)) {
			//right now not handling existing station
			return 2;
		}
		if (!this._Mgr_A.AllowTryStation(this._S_Type)) return 1;
		if (!this._Mgr_B.AllowTryStation(this._S_Type)) return 2;
		local spoint = this._Mgr_A.GetAreaForRailStation(this._Cargo_ID, true);
		if (spoint.IsEmpty()) return 1;
		local dpoint = this._Mgr_B.GetAreaForRailStation(this._Cargo_ID, false);
		if (dpoint.IsEmpty()) return 2;
		this._Start_Point = [];
		this._End_Point = [];
		foreach (idx, val in spoint) {
			local sb = StationBuilder(idx, this._Cargo_ID, this._Mgr_A.GetID(), this._Mgr_B.GetID(), true);
			if (sb.Build()) {
				this._Start_Point.push([XTile.NW_Of(idx,1), idx]);
				this._S_Station = idx;
				break;
			}
		}
		if (this._Start_Point.len() == 0) return 1;
		foreach (idx, val in dpoint) {
			local sb = StationBuilder(idx, this._Cargo_ID, this._Mgr_A.GetID(), this._Mgr_B.GetID(), false);
			if (sb.Build()) {
				this._End_Point.push([XTile.NW_Of(idx,1), idx]);
				this._D_Station = idx;
				break;
			}
		}
		if (this._End_Point.len() == 0) return 2;
		
		_PF.InitializePath(this._Start_Point, this._End_Point, []);
		return 0;
	}

	function BuildInfrastructure() {
		local path = Service.PathToArray(this._Line);
		{
			local mode = AITestMode();
			local cost = AIAccounting();
			if (XRail.BuildRail(this._Line)) {
				this._RouteCost = cost.GetCosts();
				if (!Money.Get(GetTotalCost(this))) return;
			} else {
				_PF.InitializePath(this._Start_Point, this._End_Point, []);
				Info("Path building failed. Re-find");
				return;
			}
		}
		XRail.BuildRail(this._Line);
		local depot = XRail.BuildDepotOnRail(path);
		if (AIRail.IsRailDepotTile(depot)) this._S_Depot = depot;
		path.reverse();
		depot = XRail.BuildDepotOnRail(path);
		if (AIRail.IsRailDepotTile(depot)) this._D_Depot = depot;
		AIRail.BuildSignal(path[2], path[1], AIRail.SIGNALTYPE_PBS);
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
	}
	
	function Build() {
		local station_id = XStation.FindIDNear(this.GetLocation(), 8);
		local distance = AIIndustry.GetDistanceManhattanToTile(this._industries[0], AIIndustry.GetLocation(this._industries[1]));
		AIRail.BuildNewGRFRailStation(this.GetLocation(), this._orientation, this._num_platforms,
			this._platformLength, station_id, this.GetCargo(), this._industryTypes[0],
			this._industryTypes[1], distance, this._isSourceStation);
		this.SetID(AIStation.GetStationID(this.GetLocation()));
		return AIRail.IsRailStationTile(this.GetLocation()) && XTile.IsMyTile(this.GetLocation());
	}
}
