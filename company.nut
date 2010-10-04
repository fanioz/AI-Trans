/**
 *		09.02.08
 *      company.nut
 *
 *      Copyright 2009 fanio zilla <fanio@arx-ads>
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
	Name = null;              /// Name of my company
	Live= null;               /// Should I keep alive or retire ?
	Factor = null;            /// Factor of cost;
	StartDate = null;         /// Company launching date
	Builder = null;           /// My Builder assistant
	service_table = null;   /// table of list of service todo
	service_key = null;     /// the key to retreive a service from table
	_main = null;             /// The AIController callback
_serv_gen = null;
/**
 *
 * name: CompanyManager::constructor
 * @param main main instance
 */
	constructor(main) {
		Name = "Fanioz";
		Live = 1;
		Factor = 0;
		StartDate = 0;
		Builder = BuildingHandler(this);
		_main = main;
    service_table = {};
    service_key = Binary_Heap();
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
	/* Set my Name and greeting you */
	if (!AICompany.SetPresidentName(Name)) {
		local i = 1;
		while (!AICompany.SetPresidentName(Name + " " + i + " (jr.)")) { i ++;}
	}
	Name = AICompany.GetPresidentName(AICompany.COMPANY_SELF);
	AICompany.SetName(Name + " Corp. Ltd");
	if (StartDate == 0)	StartDate = AIDate.GetCurrentDate();
	AILog.Info("Powered by " + _version_);
	AILog.Info("" + AICompany.GetName(AICompany.COMPANY_SELF) + " has been started since " + DateStr(this.StartDate)	+".");
	Builder.HeadQuarter();
	this.Factor = Builder.State.LastCost;
	Builder.Factor = this.Factor;
	ErrMessage("Build HQ cost = " + this.Factor);
	Bank.PayLoan();
	this.Live = 1;
	_serv_gen = Gen.Service(5);
}

function CompanyManager::Evaluate()
{
  AILog.Info("Evaluate");
	this._main.Sleep(1);

	GatherSubsidy();
  AILog.Info("service count=" + service_key.Count());
  if (service_key.Count() < 1) {
    if (_serv_gen.getstatus() == "dead") _serv_gen = Gen.Service(10);
    resume _serv_gen;
  }
  if (Bank.Balance() > 50000) this.Live = 1;
  if (this.Live < 0) return;
  
  /* make additional vehicle */
  AILog.Info("Check My Stations...");
  Bank.Get(null);
  if (Bank.Balance() < 10000);
  local gl = AIGroupList();
  for(local ID_g = gl.Begin(); gl.HasNext() ; ID_g = gl.Next()) {
    local vl = AIVehicleList();
    vl.Valuate(AIVehicle.GetGroupID);
    vl.KeepValue(ID_g);
    local vhcID = vl.Begin();
    local ssta = null, depot = null, order_count = AIOrder.GetOrderCount(vhcID);
    for (local cx = 0; (cx != order_count); cx++) {
      local tile = AIOrder.GetOrderDestination(vhcID, cx);
      local flag = AIOrder.GetOrderFlags(vhcID, cx) & AIOrder.AIOF_FULL_LOAD;
      //AILog.Info("flag:" + cx + ":" + flag);
      if (AIRoad.IsRoadStationTile(tile) &&  flag > 0) ssta = tile;
      if (AIRoad.IsRoadDepotTile(tile)) depot = tile;
    }
    if (ssta == null || depot == null) {
      AILog.Warning("Vehicle has no station/depot order!");
      AIEventController.InsertEvent(AIEventVehicleLost(vhcID));
      continue;
    }
    local cargo = AIEngine.GetCargoType(AIVehicle.GetEngineType(vhcID));
    //AILog.Info("Check cargo " + AICargo.GetCargoLabel(cargo));
    local staname = AIStation.GetName(AIStation.GetStationID(ssta));
    AILog.Info("Waiting at " + staname + "=" + AIStation.GetCargoWaiting(AIStation.GetStationID(ssta), cargo));
    if (AIStation.GetCargoWaiting(AIStation.GetStationID(ssta), cargo) > 100) {
      if (AIVehicleList_Station(AIStation.GetStationID(ssta)).Count() > 30) continue;
      StartClonedVehicle(vhcID, depot, 1);
      ErrMessage("Extending vehicle");
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
			 	AILog.Info("Nothing todo except sell");
			 	/*AIOrder.RemoveOrder(me.GetVehicleID(), 0);
			 	AIOrder.RemoveOrder(me.GetVehicleID(), 1);*/
			 	AIVehicle.SendVehicleToDepot(me.GetVehicleID());
			 	break;
			 case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
			 	local me = AIEventVehicleWaitingInDepot.Convert(e);
			 	// let assume that the
			 	AILog.Info("Vehicle Ready to sell");
			 	AIVehicle.SellVehicle(me.GetVehicleID());
			 	break;
			 case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
			 	local me = AIEventVehicleUnprofitable.Convert(e);
			 	AILog.Info("Hey, let me sell you anyway");
			 	/*AIOrder.RemoveOrder(me.GetVehicleID(), 0);
			 	AIOrder.RemoveOrder(me.GetVehicleID(), 1);*/
			 	AIVehicle.SendVehicleToDepot(me.GetVehicleID());
			 	break;
			 case AIEvent.AI_ET_INDUSTRY_OPEN:
				local me = AIEventIndustryOpen.Convert(e);
			 	AILog.Info("Congratulation on grand opening " + AIIndustry.GetName(me.GetIndustryID()));
			 	break;
			 case AIEvent.AI_ET_INDUSTRY_CLOSE:
			 	local me = AIEventIndustryClose.Convert(e);
			 	local id = me.GetIndustryID();
			 	AILog.Info("Sadly enough"+ AIIndustry.GetName(id));
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
  while (this.service_key.Count() > 0) {
    if (Bank.Balance() < 10000) break;
    local id = this.service_key.Pop();
    serv = (this.service_table.rawin(id)) ? this.service_table.rawget(id) : null;
    if (serv != null && !serv.Info.Serviced) {
      /* TODO : please use VT_Rail if available */
      serv.Info.VehicleType = (serv.Info.SourceIsTown || serv.Info.DestinationIsTown) ? AIVehicle.VT_ROAD : AIVehicle.VT_ROAD ;
      AILog.Info(serv.Update());
      local executor = (serv.Info.VehicleType == AIVehicle.VT_ROAD) ? this.Builder.Road : this.Builder.Rail;
      AISign.BuildSign(serv.Info.SourcePos,"Source");
      AISign.BuildSign(serv.Info.DestinationPos,"Dest");
      local trial = AITestMode();
      AILog.Warning("Test Mode");
      if (executor.Vehicle(serv) == -1) break;
      //if (!executor.Station(serv, true)) break;
      //if (!executor.Station(serv, false)) break;

      local really = AIExecMode();
      AILog.Warning("Real Mode");
      executor.Path(serv, 1);
      local cost = AIAccounting();
      if (!executor.Track(serv, 1, false)) break;
      if (!Bank.Get((cost.GetCosts() * 1.2).tointeger())) break;
      if (!executor.Track(serv, 1)) break;
      if (!executor.Station(serv, true)) break;
      if (!executor.Station(serv, false)) break;
      if (!executor.Depot(serv)) break;
      executor.Path(serv, 2);
      if (!executor.Track(serv, 2)) break;
      executor.Path(serv, 3);
      if (!executor.Track(serv, 3)) break;

      // I'm sad to break after going so far
      if (executor.Vehicle(serv) < 1) break;
      AIVehicle.StartStopVehicle(serv.Info.MainVhcID);
      local grp = AIVehicle.GetGroupID(serv.Info.MainVhcID);
      if (!AIGroup.IsValidGroup(grp)) {
        grp = AIGroup.CreateGroup(serv.Info.VehicleType);
        local g_name = serv.Info.CargoStr + ":::" + serv.Info.CurrentID;
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
		local service = Services(AISubsidy.GetSource(i), AISubsidy.GetDestination(i), AISubsidy.GetCargoType(i));
		//AILog.Info("Gathering servis id " + service.Info.CurrentID);
		//if (service_key.Exists(service.Info.CurrentID)) continue;
		if (this.service_table.rawin(service.Info.CurrentID)) continue;
		if ((!AISubsidy.SourceIsTown(i) && AIIndustry.IsBuiltOnWater(AISubsidy.GetSource(i))) ||
		  (!AISubsidy.DestinationIsTown(i) && AIIndustry.IsBuiltOnWater(AISubsidy.GetDestination(i)))) continue;
    service.Info.SourceIsTown = AISubsidy.SourceIsTown(i);
		service.Info.DestinationIsTown = AISubsidy.DestinationIsTown(i);
		AILog.Info(service.Update());
		if ((AIMap.DistanceManhattan(service.Info.SourcePos, service.Info.DestinationPos)) < 5) continue;
		this.service_key.Insert(service.Info.CurrentID, d - 29);
		this.service_table[service.Info.CurrentID] <- service;
	}
	AILog.Info("Finished");
}

function CompanyManager::Test() 
{
	//do some test stuff here;
}

function CompanyManager::SleepTime() 
{
	return (100000 / Bank.Balance()).tointeger() + 10;
}

