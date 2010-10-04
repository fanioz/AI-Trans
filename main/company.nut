/**
 *		09.02.08
 *      company.nut
 *
 *      Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 *
 */

/**
 *
 * name: CompanyManager
 * @note Company management class
 */
class CompanyManager
{
	_name = null;              /// _name of my company
	Live= null;               /// Should I keep alive or retire ?
	Factor = null;            /// Factor of cost;
	_factor = null;           /// factor of fluctuation
	StartDate = null;         /// Company launching date
	Builder = null;           /// My Builder assistant
	service_table = null;   /// table of list of service todo
	serviced_route = null; /// table to save serviced service
	service_key = null;     /// the key to retreive a service from table
	_main = null;             /// The AIController main instance
_serv_gen = null;       /// service generator

/**
 *
 * name: CompanyManager::constructor
 * @param main main instance
 */
	constructor(main) {
		_name = "Fanioz";
		Live = 1;
		Factor = 10000;
		_factor = AICompany.GetMaxLoanAmount() / Factor;
		StartDate = 0;
		Builder = BuildingHandler(this);
		_main = main;
    service_table = {};
    service_key = Binary_Heap();
    serviced_route = {};
	}

/**
 *
 * name: Born
 * @note Initializing routine company startup
 */
	function Born();

/**
 *
 * name: Test
 * @note test whatever procedure do you want here
 */
	function Test();

/**
 *
 * name: Evaluate
 * @note Evaluate all vehicle, stations
 */
	function Evaluate();


/**
 *
 * name: Events
 * @note Check if there is even un handled
 */
	function Events();

/**
 *
 * name: Service
 * @note Transport Servicing (pick an ID from table)
 */
	function Service();
	
/**
 *
 * name: Sleep Time
 * @return The amount time to sleep
 */
	function SleepTime();	
}

function CompanyManager::Born()
{
	/* Wake up .. */
	AICompany.SetAutoRenewStatus (true);
	AICompany.SetAutoRenewMonths(-12);
	AICompany.SetAutoRenewMoney(0);
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	local rt = AIRailTypeList();
  AIRail.SetCurrentRailType(rt.Begin());
	/* Set my name and greeting you */
	if (!AICompany.SetPresidentName(_name)) {
		local i = 1;
		while (!AICompany.SetPresidentName(_name + " " + i + " (jr.)")) { i ++;}
	}
	_name = AICompany.GetPresidentName(AICompany.COMPANY_SELF);
	AICompany.SetName(_name + " Corp. Ltd");
	if (StartDate == 0)	StartDate = AIDate.GetCurrentDate();
	AILog.Info("Powered by " + _version_);
	AILog.Info("" + AICompany.GetName(AICompany.COMPANY_SELF) + " has been started since " + DateStr(this.StartDate)	+".");
	Builder.HeadQuarter();
	ErrMessage("Build HQ cost = " + Builder.State.LastCost);
	this.Live = 1;
}

function CompanyManager::Evaluate()
{
  AILog.Info("Evaluate");
	this._main.Sleep(1);

	GatherSubsidy();
	this.Factor = AICompany.GetMaxLoanAmount() / this._factor;
  AILog.Info("Factor=" + this.Factor);
  AILog.Info("service count=" + service_key.Count());
  if (service_key.Count() < 1) {
    /* init new service generator */
    if (_serv_gen == null) _serv_gen = Gen.Service(500);
    else resume _serv_gen;    
  }
  /* check to see if there are invalid vehicle order */
  local vhc_list = AIVehicleList();
  vhc_list.Valuate(AIOrder.GetOrderCount);
  vhc_list.KeepBelowValue(1);
  foreach (vhc, val in vhc_list) HandleVehicleLost(vhc);

  if (this.Live < 0) {
    if (Bank.Balance() > this.Factor) this.Live = 1;
    else return;
  }
    
  Bank.Get(null);
  if (Bank.Balance() < this.Factor) return;
  /* make additional vehicle */
  AILog.Info("Check My Stations...");
  local gl = AIGroupList();
  for(local ID_g = gl.Begin(); gl.HasNext() ; ID_g = gl.Next()) {
    local vhc_list = AIVehicleList();
    vhc_list.Valuate(AIVehicle.GetGroupID);
    vhc_list.KeepValue(ID_g);
    local vhcID = vhc_list.Begin();
    local ssta = AIOrder.GetOrderDestination(vhcID, 0);
    local depot = AIOrder.GetOrderDestination(vhcID, 3);    
    
    if (!AIRoad.IsRoadStationTile(ssta)  || !AIRoad.IsRoadDepotTile(depot)) {
      AILog.Warning("Vehicle has no station/depot order!");
      HandleUnprofitable(vhcID);
      continue;
    }
    local ssta_ID = AIStation.GetStationID(ssta);
    local cargo = AIEngine.GetCargoType(AIVehicle.GetEngineType(vhcID));
    //AILog.Info("Check cargo " + AICargo.GetCargoLabel(cargo));
    local staname = AIStation.GetName(ssta_ID);
    AILog.Info("Waiting at " + staname + "=" + AIStation.GetCargoWaiting(ssta_ID, cargo));
    if (AIStation.GetCargoWaiting(ssta_ID, cargo) > 50) {
      if (AIVehicleList_Station(ssta_ID).Count() > 60) continue;
      if (MsgResult("Extra vehicle =", StartClonedVehicle(vhcID, depot, 1)) > 0) {
        /* if it getting old */
        vhc_list.Valuate(AIVehicle.GetAge);
        vhc_list.KeepAboveValue(730);
        HandleUnprofitable(vhc_list.Begin());
      }
    }
  }  
}


function CompanyManager::Events()
{
	while (AIEventController.IsEventWaiting())
	{
		local e = AIEventController.GetNextEvent();
		local si = null;
		switch (e.GetEventType()) {
			case AIEvent.AI_ET_SUBSIDY_OFFER:
        this.GatherSubsidy();
			 	break;
			case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:
				local esoe = AIEventSubsidyOfferExpired.Convert(e);
				si = esoe.GetSubsidyID();
				AILog.Info("SubsidyID " + si + " offer expired" );
				local serv = Services(AISubsidy.GetSource(si), AISubsidy.GetDestination(si), AISubsidy.GetCargoType(si));
				si = serv.Info.CurrentID;
        if (this.service_key.Exists(si)  && this.service_table.rawin(si)) this.service_table.rawdelete(si);
			 	break ;
			case AIEvent.AI_ET_SUBSIDY_AWARDED:
				local esa = AIEventSubsidyAwarded.Convert(e);
				si = esa.GetSubsidyID();
				AILog.Info("SubsidyID " + si + " awarded");
				local serv = Services(AISubsidy.GetSource(si), AISubsidy.GetDestination(si), AISubsidy.GetCargoType(si));
				si = serv.Info.CurrentID;
        if (this.service_key.Exists(si)  && this.service_table.rawin(si)) this.service_table.rawdelete(si);
			 	break ;
			case AIEvent.AI_ET_SUBSIDY_EXPIRED:
				local ese = AIEventSubsidyExpired.Convert(e);
				si = ese.GetSubsidyID();
				AILog.Info("SubsidyID " + si + " expired");
				break;
			 case AIEvent.AI_ET_TEST:
			 	AILog.Info("Undocumented event!" );
			 	break;
			 case AIEvent.AI_ET_ENGINE_PREVIEW:
			 	local me = AIEventEnginePreview.Convert(e);
			 	AILog.Info("New Vehicle come : " + me.GetName());
			 	me.AcceptPreview();
			 	break;
			 /* case AIEvent.AI_ET_COMPANY_NEW:
			 	local me = .Convert(e);
			 	AILog.Info("");
			 	me.
			 	break;			 
			 case AIEvent.AI_ET_COMPANY_MERGER:
			 	local me = .Convert(e);
			 	AILog.Info("");
			 	me.
			 	break;*/
			 	case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
			 	local me = AIEventCompanyInTrouble.Convert(e);
			 	if (AICompany.IsMine(me.GetCompanyID())) {
			 		this.Live = -1;
			 		AILog.Info("Going to sleep");
				}
				break;
			  case AIEvent.AI_ET_COMPANY_BANKRUPT:
			 	local me = AIEventCompanyBankrupt.Convert(e);
			 	if (AICompany.IsMine(me.GetCompanyID())) {
			 		this.Live = 0;
			 		AILog.Info("Going to sleep");
				}
			 	break;
			 	/*
       case AIEvent.AI_ET_VEHICLE_CRASHED:
			 	local me = AIEventVehicleCrashed.Convert(e);
			 	AILog.Info("");
			 	me.
			 	break;
			 	*/
			 case AIEvent.AI_ET_VEHICLE_LOST:
			 	local me = AIEventVehicleLost.Convert(e);
        local vhc_ID = me.GetVehicleID();
			 	AILog.Info("Nothing todo except sell this " + vhc_ID);
        HandleVehicleLost(me.GetVehicleID());
        break;
        
			 case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
			 	local me = AIEventVehicleWaitingInDepot.Convert(e);
			 	/* sell the vehicle if it has no order */
        local vhc_ID = me.GetVehicleID();
			 	AILog.Info("Ready to sell Vehicle " + vhc_ID);
			 	if (AIOrder.GetOrderCount(vhc_ID) == 0)AIVehicle.SellVehicle(me.GetVehicleID());
        /* reserved for vehicle_refit feature in future */
			 	break;
        
			 case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
			 	local me = AIEventVehicleUnprofitable.Convert(e);
        HandleUnprofitable(me.GetVehicleID());
        break;
        
			 case AIEvent.AI_ET_INDUSTRY_OPEN:
				local me = AIEventIndustryOpen.Convert(e);
			 	AILog.Info("Congratulation on grand opening " + AIIndustry.GetName(me.GetIndustryID()));
			 	break;
        
			 case AIEvent.AI_ET_INDUSTRY_CLOSE:
			 	local me = AIEventIndustryClose.Convert(e);
			 	local id = me.GetIndustryID();
			 	AILog.Info("Sadly enough, Good bye "+ AIIndustry.GetName(id));
			 	HandleClosingIndustry(id);
			 	break;
        
			 case AIEvent.AI_ET_ENGINE_AVAILABLE:
			 	local me = AIEventEngineAvailable.Convert(e);
				local x = me.GetEngineID();
			 	AILog.Info(AIEngine.GetName(x) + " Available");
			 	UpgradeVehicleEngine(x);
			 	break;
			 /**
       case AIEvent.AI_ET_STATION_FIRST_VEHICLE:
			 	local me = .Convert(e);
			 	AILog.Info("");
			 	me.
			 	break;
			 case AIEvent.AI_ET_DISASTER_ZEPPELINER_CRASHED:
			 	local me = .Convert(e);
			 	AILog.Info("");
			 	me.
			 	break;
			 case AIEvent.AI_ET_DISASTER_ZEPPELINER_CLEARED:
			 	local me = .Convert(e);
			 	AILog.Info("");
			 	me.
			 	break; */
			 case AIEvent.AI_ET_INVALID:
				AILog.Info("What a hell of an invalid event!" );
				break;
		}
	}
}

function CompanyManager::Service()
{
  AILog.Info("Do a service");
  local serv = null;
  Bank.Get(serv);
  while (this.service_key.Count() > 0 && serv == null) {
    if (Bank.Balance() < this.Factor) break;
    local id = this.service_key.Pop();
    serv = (this.service_table.rawin(id)) ? this.service_table.rawget(id) : null;
    if (serv != null && !serv.Info.Serviced) {
      /* TODO : please use VT_Rail if available */
      serv.Info.VehicleType = (serv.Info.SourceIsTown || serv.Info.DestinationIsTown) ? AIVehicle.VT_ROAD : AIVehicle.VT_ROAD ;
      AILog.Info(serv.Update());
      local executor = (serv.Info.VehicleType == AIVehicle.VT_ROAD) ? this.Builder.Road : this.Builder.Rail;
      AISign.BuildSign(serv.Info.SourcePos,"Source");
      AISign.BuildSign(serv.Info.DestinationPos,"Dest");
      local service_cost = 0;
      
      AILog.Warning("Test Mode");
      Builder.State.TestMode = true;
      if (executor.Vehicle(serv) == -1) break;
      service_cost += Builder.State.LastCost * 2;
      //Builder.State.TestMode = false;  
      if (!executor.Station(serv, true)) break;
      service_cost += Builder.State.LastCost;
      if (!executor.Station(serv, false)) break;
      service_cost += Builder.State.LastCost;
      if (!executor.Depot(serv, true)) break;
      service_cost += Builder.State.LastCost;
      if (!executor.Depot(serv, false)) break;
      service_cost += Builder.State.LastCost;
      executor.Path(serv, 1, true);
      if (!executor.Track(serv, 1)) break;
      service_cost += Builder.State.LastCost;
      executor.Path(serv, 2, true);
      if (!executor.Track(serv, 2)) break;
      service_cost += Builder.State.LastCost;
      executor.Path(serv, 3, true);
      if (!executor.Track(serv, 3)) break;
      service_cost += Builder.State.LastCost;
      
      /* don't continue if I've not enough money */
      if (!Bank.Get(service_cost * 1.3)) break;
      
      AILog.Warning("Real Mode");
      Builder.State.TestMode = false;     
      //if (!executor.Track(serv, 1)) break;
      if (!executor.Station(serv, true)) break;
      if (!executor.Station(serv, false)) break;
      if (!executor.Depot(serv, true)) break;
      if (!executor.Depot(serv, false)) break;
      
      if (!executor.Track(serv, 1)) {
        serv.Info.Path1 = false;
        executor.Path(serv, 1, true);
        if (!executor.Track(serv, 1)) break;
      }
      
      if (!executor.Track(serv, 2)) {
        serv.Info.Path2 = false;
        executor.Path(serv, 2, true);
        if (!executor.Track(serv, 2)) break;
      }
      
      if (!executor.Track(serv, 3)) {
        serv.Info.Path3 = false;
        executor.Path(serv, 3, true);
        if (!executor.Track(serv, 3)) break;
      }

      // I'm sad to break after going so far
      if (executor.Vehicle(serv) < 1) break;
      AIVehicle.StartStopVehicle(serv.Info.MainVhcID);
      local grp = AIVehicle.GetGroupID(serv.Info.MainVhcID);
      if (!AIGroup.IsValidGroup(grp)) {
        grp = AIGroup.CreateGroup(serv.Info.VehicleType);
        local g_name = serv.Info.CurrentID;
        AIGroup.SetName(grp, g_name);
      }
      AIGroup.MoveVehicle(grp, serv.Info.MainVhcID);
      executor.Vehicle(serv);
      serv.Info.Serviced = true;
      this.service_table[serv.Info.CurrentID] <- serv;
      Builder.ClearSigns();
      AILog.Info("End service");
      return true;
    }
    ErrMessage("Service Not Found");
    serv == false;
    Builder.ClearSigns();
  }
  ErrMessage("Service Test Not Passed");
  serv == false;
  Builder.ClearSigns();
}

function CompanyManager::GatherSubsidy()
{
	local i = null, s = Gen.Subsidy();
  while(i = resume s){
		AIController.Sleep(1);
		local d = AISubsidy.GetExpireDate(i) - AIDate.GetCurrentDate();
		if (d < 30) continue;
		//AILog.Info("Gathering subsidyID " + i);
    local source = AISubsidy.GetSource(i);
    local dest = AISubsidy.GetDestination(i);
		local subs_service = Services(source, dest, AISubsidy.GetCargoType(i));
		//AILog.Info("Gathering servis id " + service.Info.CurrentID);    
    if ((!AISubsidy.SourceIsTown(i) && AIIndustry.IsBuiltOnWater(source)) ||
       (!AISubsidy.DestinationIsTown(i) && AIIndustry.IsBuiltOnWater(dest))) continue;
    /* update the table of service to avoid double service */
    /* not found better than this yet */
    if (this.service_table.rawin(subs_service.Info.CurrentID)) {
       /*
      subs_service = this.service_table[subs_service.Info.CurrentID];
      if (subs_service.Info.Serviced) */
      continue;
    } else {
      subs_service.Info.SourceIsTown = AISubsidy.SourceIsTown(i);
      subs_service.Info.DestinationIsTown = AISubsidy.DestinationIsTown(i);
      AILog.Info(subs_service.Update());
      if ((AIMap.DistanceManhattan(subs_service.Info.SourcePos, subs_service.Info.DestinationPos)) < 5) continue;
      subs_service.Info.Is_Subsidy = true;
      this.service_key.Insert(subs_service.Info.CurrentID, d - 29);
      this.service_table[subs_service.Info.CurrentID] <- subs_service;
    }
	}
	AILog.Info("Subsidy Gathered");
}

function CompanyManager::Test() 
{
	//do some test stuff here;
	
}

function CompanyManager::SleepTime() 
{
  return 100;
}
