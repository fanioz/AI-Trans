/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

class Connector extends DailyTask
{
	_SkipList = null;
	_Skip_Dst = null;
	_Skip_Src = null;
	_VhcManager = null;
	_Source_ID = null;
	_Dest_ID = null;
	_S_Station = null;
	_D_Station = null;
	_S_Depot = null;
	_D_Depot = null;
	_Serv_Cost = null;
	_Cargo_ID = null;
	_Line = null;
	_PF = null;
	_PT = null;
	_RouteCost = null;
	_Route_Found = null;
	_Route_Built = null;
	_Station_Built = null;
	_Max_Distance = null;
	_Min_Distance = null;
	_Last_Year = null;
	_Blocked_Cargo = null;
	_Blocked_Track = null;
	_Engine_A = null;
	_Engine_B = null;
	_Track = null;
	_V_Type = null;
	_End_Point = null;
	_Start_Point = null;
	_Production = null;
	_LastSuccess = null;
	_Mgr_A = null;
	_Mgr_B = null;
	_S_Type = null;
	_Possible_Sources = null;

	constructor(name, key) {
		::DailyTask.constructor(name, key);
		_VhcManager = VehicleMaker(_V_Type);
		_Last_Year = AIDate.GetCurrentDate();
		_LastSuccess = 0;
		_SkipList = CLList();
		_Blocked_Cargo = CLList();
		_Blocked_Track = CLList();
		_Skip_Dst = CLList();
		_Skip_Src = CLList();

		_Source_ID = -1;
		_Dest_ID = -1;
		_S_Station = -1;
		_D_Station = -1;
		_S_Depot = -1;
		_D_Depot = -1;
		_Cargo_ID = -1;
		_Engine_A = -1;
		_Engine_B = -1;
		_Track = -1;
		_S_Type = -1;

		_Serv_Cost = 0;
		_RouteCost = 0;
		_Production = 0;

		_Line = false;
		_PF = null;
		_PT = null;

		_End_Point = -1;
		_Start_Point = -1;
		_Route_Found = false;
		_Route_Built = false;
		_Station_Built = false;

		_Max_Distance = 0;
		_Min_Distance = 0;

		_Mgr_A = null;
		_Mgr_B = null;

		_Possible_Sources = {};
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

	/**
	 * selecting current cargo id for further process
	 */
	function MatchCargo(self) {
		local cargoes = AICargoList();
		cargoes.RemoveList(self._Blocked_Cargo);
		if (cargoes.IsEmpty()) {
			self._Blocked_Cargo.Clear();
			self.Warn("cargo selection empty");
			self._Track = -1;
			return;
		}
		cargoes.Valuate(XCargo.MatchSetting);
		cargoes.KeepValue(1);
		if (cargoes.IsEmpty()) {
			self.Warn("could not select any cargo");
			return;
		}
		cargoes.Valuate(XCargo.GetCargoIncome, 20, 200);
		self._Cargo_ID = cargoes.Begin();
		self._S_Type = XStation.GetTipe(self._V_Type, self._Cargo_ID);
		self._Blocked_Cargo.AddItem(self._Cargo_ID, 0);
		self._Possible_Sources[self._Cargo_ID] <- CLList();
		self._Engine_A = -1;
	}

	/**
	 * selecting current engine id for further process
	 */
	function SelectEngine(self) {
		self._VhcManager.Reset();
		if (self._VhcManager.HaveEngineFor(self._Track)) {
			self._VhcManager.SetCargo(self._Cargo_ID);
			local c = self._VhcManager.CargoEngine.Count();
			self.Info("engines found for", XCargo.Label[self._Cargo_ID], "were", c);
			if (c < 1) {
				self._Cargo_ID = -1;
				return;
			}
			self._VhcManager.SortEngine();
			self._Engine_A = self._VhcManager.GetFirst();
		} else {
			Info("Could not find engine. current money:", Money.Maximum());
			self._Blocked_Track.AddItem(self._Track, 0);
			self._Track = -1;
		}
		return;
	}

	/**
	 * common vehicle managers action on building vehicles
	 */
	function MakeVehicle(self) {
		self._VhcManager.SetCargo(self._Cargo_ID);
		self._VhcManager.SetStationA(self._S_Station);
		self._VhcManager.SetStationB(self._D_Station);
		self._VhcManager.SetDepotA(self._S_Depot);
		self._VhcManager.SetDepotB(self._D_Depot);
		self._VhcManager.TryBuild();
		if (self._VhcManager.IsBuilt()) {
			self._VhcManager.SetNextOrder();
			self._VhcManager.StartCloned();
		} else {
			self.Warn("failed on build vehicle");
		}
		Money.Pay();
		return self._VhcManager.IsBuilt();
	}

	/**
	 * estimating cost for service
	 */
	function GetTotalCost(self) {
		local cost = AIEngine.GetPrice(self._Engine_A);
		if (self._V_Type == AIVehicle.VT_RAIL) {
			/* TODO : number '4' should be changeable */
			cost *= 4;
			cost += AIEngine.GetPrice(self._Engine_B);
		}
		self.Info("engine cost", cost);
		self.Info("infrastructure cost", self._Serv_Cost);
		self.Info("route cost", self._RouteCost);
		cost += self._Serv_Cost + self._RouteCost;
		self.Info("total cost", cost);
		return  cost;
	}

	function IsWaitingPath(self) {
		if (self._Mgr_A == null) return false;
		if (self._PF.IsRunning()) {
			self.Info("still finding", self._Mgr_A.GetName(), "=>", self._Mgr_B.GetName());
			self._Line = _PF.FindPath(200);
			return true;
		}
		if (typeof self._Line == "instance") {
			self._RouteCost = _Line.GetBuildCost();
			self._Route_Found = true;
			Assist.RemoveAllSigns();
		} else if (self._Line == null) {
			self._RouteCost = 0;
			self._Route_Found = false;
			self._Mgr_A = null;
			Assist.RemoveAllSigns();
		}
		//not removing sign if line = false
		Info("route found", self._Route_Found);
		return false;
	}

	function UpdateSource(self) {
		if (self._Possible_Sources.rawin(self._Cargo_ID)) {
			self._Possible_Sources[self._Cargo_ID].Clear();
		} else {
			self._Possible_Sources[self._Cargo_ID] <- CLList();
		}
		self._Possible_Sources[self._Cargo_ID].AddList(Service.FindSource(self));
		self._Possible_Sources[self._Cargo_ID].RemoveItem(self._Mgr_B.GetLocation());
	}

	function SelectDest(self) {
		self._Mgr_B = Assist.GetManager(Service.FindDest(self._Cargo_ID, self._V_Type , self._Skip_Dst));
		if (self._Mgr_B == null) {
			self._Cargo_ID = -1;
			self._Skip_Dst.Clear();
			return;
		} else {
			UpdateSource(self);
			self._Skip_Dst.AddItem(_Mgr_B.GetLocation(), 0);
		}
	}

	function SelectSource(self) {
		if (self._Mgr_B == null) return;
		Info("finding source from selected destination:", _Mgr_B.GetName());
		if (!self._Possible_Sources[self._Cargo_ID].IsEmpty()) {
			Info("pair left", self._Possible_Sources[self._Cargo_ID].Count());
			self._Mgr_A = Assist.GetManager(self._Possible_Sources[self._Cargo_ID].Pop());
		}
		if (self._Mgr_A == null) {
			self._Mgr_B = null;
			Warn("Couldn't find it pair");
		} else {
			Info("selecting source:", _Mgr_A.GetName());
			self._Skip_Src.AddItem(self._Mgr_A.GetLocation(), 0);
		}
	}
}
