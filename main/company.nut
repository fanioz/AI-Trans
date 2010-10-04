/*
 *  09.02.08
 *  company.nut
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA 02110-1301, USA.
 *
 */

/**
 *
 * CompanyManager
 * Company management class
 */
class CompanyManager
{
    my_name = null;              ///<  President name of my company
    live= null;               ///< Should I keep alive or retire ?
    ff_factor = null;            ///< factor of fluctuation on runtime
    _factor = null;           ///< factor of fluctuation on start
    start_date = null;         ///< Company launching date
    serviced_route = null; ///< The table to save serviced route
    expired_route = null; ///< The table to save expired route
    service_keys = null;     ///< The key storage to retreive a service from table
    service_tables = null;  ///< The table to store service
    _main = null;             ///< The Trans main instance
    new_engines = null;       ///< New Engines available
    drop_off_point = null; ///< Drop off table (saved)
    old_vehicle = null;      ///< Old vehicle table
    vehicle_sent = null;    ///< Vehicle table of ID that has been given cmd send to depot
    industry_will_close = null; ///< Array to store event on Industry close
    current_service = null;
    randomizer = null;      ///< Randomizer a bit  min.value = 1
    rail_backbones = null;

    Builder = null;           ///< My Builder assistant

    constructor(main) {
        this._main = main;
        this.my_name = "Fanioz";
        this.live = null;
        this.ff_factor = 10000;
        this._factor = 0;
        this.start_date = 0;
        this.Builder = BuildingHandler(this);
        this.service_keys = BinaryHeap();
        this.serviced_route = {};
        this.expired_route = {};
        this.service_tables = {};
        this.new_engines = [];
        this.drop_off_point = {};
        this.old_vehicle = BinaryHeap();
        this.industry_will_close = [];
        this.current_service = 0;
        this.randomizer = null;
        this.vehicle_sent = {};
        this.rail_backbones = [];
    }
}

/**
 * Initializing routine company startup
 */
function CompanyManager::Born()
{
    /* Wake up .. */
    AICompany.SetAutoRenewStatus (true);
    AICompany.SetAutoRenewMonths(-12);
    AICompany.SetAutoRenewMoney(10000);
    AIGroup.EnableWagonRemoval(true);

    /* Detect saved session */
    if (this.start_date == 0) this.start_date = AIDate.GetCurrentDate();
    if (this.live == null) this.live = 1;
    if (this.randomizer == null) this.randomizer = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
    if (AICompany.GetPresidentName(this.randomizer) != this.my_name) {
        /* Set my name */
        local i = 1;
        if (!AICompany.SetPresidentName(this.my_name)) {
            while (!AICompany.SetPresidentName(this.my_name + " " + i + " (jr.)")) i++;;
        }
        this.my_name = AICompany.GetPresidentName(this.randomizer);
        AICompany.SetName(this.my_name + " Trans Corp.");
    }
    /* greeting you */
    AILog.Info("" + AICompany.GetName(this.randomizer) + " has been started since " + Assist.DateStr(this.start_date));
    AILog.Info("Powered by " + _version_);
    Debug.ResultOf("Random factor", this.randomizer);
    //if (this.drop_off_point.len() == 0) this.drop_off_point = Gen.DropOffType(this.randomizer);
    if (this._factor == 0) this._factor = AICompany.GetMaxLoanAmount() / 10000;
    Builder.HeadQuarter();

}

/**
 * To test whatever procedure do you want here
 */
function CompanyManager::Test()
{
}

/**
 * Evaluate all vehicles, stations, connections
 */
function CompanyManager::Evaluate()
{
    AILog.Info("Evaluating...");
    Gen.Subsidy(this);
    this.ff_factor = Debug.ResultOf("factor", AICompany.GetMaxLoanAmount() / this._factor);
    if (Debug.ResultOf("scheduled service count", this.service_keys.Count()) < 1) {
        /* (re)run the service generator */
        this.drop_off_point = Gen.DropOffType(this.randomizer);
        Gen.Service(this);
    }

    /* check to see a will close industry */
    if (this.industry_will_close.len() > 0) HandleClosingIndustry.call(this, this.industry_will_close.pop());

    /* check to see if there are invalid vehicle order */
    local vhc_list = AIVehicleList();
    vhc_list.Valuate(AIOrder.GetOrderCount);
    vhc_list.KeepBelowValue(5);
    foreach (vhc, val in vhc_list) this.old_vehicle.Insert(vhc, 0);

    /* if it getting old register it*/
    vhc_list = AIVehicleList();
    vhc_list.Valuate(AIVehicle.GetAge);
    vhc_list.KeepAboveValue(730);
    foreach (vhc, val in vhc_list) this.old_vehicle.Insert(vhc, 1000 - AIVehicle.GetAge(vhc));

    /* check to see an old vhc */
    while (this.old_vehicle.Count() > 0) {
        AIController.Sleep(1);
        local vhc_ID = this.old_vehicle.Pop();
        /* skip an invalid ID */
        if (!AIVehicle.IsValidVehicle(vhc_ID)) continue;
        /* don't sell if the only one */
        if (AIVehicleList_Group(AIVehicle.GetGroupID(vhc_ID)).Count() == 1) continue;
        /* check if has been sent before */
        if ((vhc_ID in this.vehicle_sent) && this.vehicle_sent[vhc_ID]) {
            /* try to sell if sent */
            if (Vehicles.Sold(vhc_ID)) {
                this.vehicle_sent.rawdelete(vhc_ID);
                AILog.Info("Finally, we can sell");
                break;
            }
            /* else update the sent status */
        } else this.vehicle_sent[vhc_ID] <- Vehicles.TryToSend(vhc_ID);
        break;
    }

    /* check to see any new engine */
    if (this.new_engines.len() > 0) Vehicles.UpgradeEngine(this.new_engines.pop());

    /* check to see am I in trouble */
    if (this.live < 0) {
        if (Bank.Balance() > this.ff_factor) this.live = 1;
        else return;
    }

    Bank.Get(0);
    if (Bank.Balance() < this.ff_factor) return;
    /* make additional vehicle */
    AILog.Info("Check My Stations...");
    foreach (group_id, val in AIGroupList()) {
        local vhc_list = AIVehicleList();
        vhc_list.Valuate(AIVehicle.GetGroupID);
        vhc_list.KeepValue(group_id);
        if (vhc_list.IsEmpty()) continue;
        local vhcID = vhc_list.Begin();
        local ssta = AIOrder.GetOrderDestination(vhcID, AIOrder.ResolveOrderPosition(vhcID,0));
        local depot = AIOrder.GetOrderDestination(vhcID, AIOrder.ResolveOrderPosition(vhcID, 4));
        local cargo = -1;
        local vhc_count = -1;
        local min_capacity = 0;
        local name = AIVehicle.GetName(vhcID);
        local v_type = AIVehicle.GetVehicleType(vhcID);
        switch (v_type) {
            case AIVehicle.VT_ROAD :
                if (!Debug.ResultOf(name + " valid station order", AIRoad.IsRoadStationTile(ssta))  ||
                    !Debug.ResultOf(name + " valid depot order", AIRoad.IsRoadDepotTile(depot))) {
                    old_vehicle.Insert(vhcID, 0);
                    continue;
                }
                vhc_count = Vehicles.CountAtTile(AIRoad.GetRoadStationFrontTile(ssta));
                cargo = Vehicles.CargoType(vhcID);
                break;
            case AIVehicle.VT_RAIL :
                if (!Debug.ResultOf(name + " valid station order", AIRail.IsRailStationTile(ssta))  ||
                    !Debug.ResultOf(name + " valid depot order", AIRail.IsRailDepotTile(depot))) {
                    old_vehicle.Insert(vhcID, 0);
                    continue;
                }
                vhc_count = Vehicles.CountAtTile(AIRail.GetRailDepotFrontTile(depot));
                cargo = Vehicles.CargoType(vhcID, true);
                break;
            default : Debug.DontCallMe("Unsupported V_Type", vhcID);
        }
        vhc_count += Vehicles.CountAtTile(ssta);
        vhc_count = Vehicles.CountAtTile(depot);
        if (Debug.ResultOf("Vehicle waiting:", vhc_count) > 0) continue;
        min_capacity = AIVehicle.GetCapacity(vhcID, cargo);
        local ssta_ID = AIStation.GetStationID(ssta);
        local string_x = "cargo waiting at " + AIStation.GetName(ssta_ID);
        if  (Debug.ResultOf(string_x, AIStation.GetCargoWaiting(ssta_ID, cargo)) > min_capacity) {
            if (AIStation.GetCargoRating(ssta_ID, cargo) < 60) {
                if (v_type == AIVehicle.VT_RAIL) {
                    if (Assist.GetServiceID(Vehicles.GroupName(vhcID)) in this.rail_backbones) continue;
                } else {
                }
                Debug.ResultOf("Vehicle build", Vehicles.StartCloned(vhcID, depot, 1));
            }
        }
    }
    AILog.Info("Finished checking");
}

/**
 * Check if there are events un handled
 */
function CompanyManager::Events()
{
    while (AIEventController.IsEventWaiting()) {
        AILog.Info("Clearing Events...");
        local e = AIEventController.GetNextEvent();
        local si = null;

        switch (e.GetEventType()) {

            case AIEvent.AI_ET_SUBSIDY_OFFER:
                AILog.Info("New Subsidy offered" );
                break;

            case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:
                local esoe = AIEventSubsidyOfferExpired.Convert(e);
                si = esoe.GetSubsidyID();
                AILog.Info("SubsidyID " + si + " offer expired" );
                si = Services.CreateID(AISubsidy.GetSource(si), AISubsidy.GetDestination(si), AISubsidy.GetCargoType(si));
                if (si in this.serviced_route) break;
                if (si in this.service_tables) this.service_tables.rawdelete(si);
                this.expired_route[si] <- si;
                break ;

            case AIEvent.AI_ET_SUBSIDY_AWARDED:
                local esa = AIEventSubsidyAwarded.Convert(e);
                si = esa.GetSubsidyID();
                AILog.Info("SubsidyID " + si + " awarded");
                if (AICompany.IsMine(AISubsidy.GetAwardedTo(si))) break;
                si = Services.CreateID(AISubsidy.GetSource(si), AISubsidy.GetDestination(si), AISubsidy.GetCargoType(si));
                if (si in this.serviced_route) break;
                if (si in this.service_tables) this.service_tables.rawdelete(si);
                this.expired_route[si] <- si;
                break;

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
                /* unsupported - need a Do command
                me.AcceptPreview();
                */
                break;

            case AIEvent.AI_ET_COMPANY_NEW:
                local me = AIEventCompanyNew.Convert(e);
                si = me.GetCompanyID();
                AILog.Warning("Welcome " + AICompany.GetName(si));
                break;

            case AIEvent.AI_ET_COMPANY_MERGER:
                local me = AIEventCompanyMerger.Convert(e);
                si = AICompany.GetName(me.GetOldCompanyID()) + AICompany.GetName(me.GetNewCompanyID());
                AILog.Info("And now come, the merger between " + si);
                break;

            case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
                local me = AIEventCompanyInTrouble.Convert(e);
                if (AICompany.IsMine(me.GetCompanyID())) {
                    this.live = -1;
                    AILog.Info("Going to sleep");
                }
                break;

            case AIEvent.AI_ET_COMPANY_BANKRUPT:
                local me = AIEventCompanyBankrupt.Convert(e);
                si = me.GetCompanyID();
                if (AICompany.IsMine(si)) {
                    this.live = 0;
                    AILog.Info("Going to sleep");
                } else AILog.Info("Good bye " + AICompany.GetName(si));
                break;

            case AIEvent.AI_ET_VEHICLE_CRASHED:
                /*
                * local me = AIEventVehicleCrashed.Convert(e);
                AILog.Info("");
                me.
                */
                break;
                /*
                future version will redo pathfinding to avoid this
                */

            case AIEvent.AI_ET_VEHICLE_LOST:
                local me = AIEventVehicleLost.Convert(e);
                local vhc_ID = me.GetVehicleID();
                AILog.Info("Vehicle lost " + AIVehicle.GetName(vhc_ID));
                this.old_vehicle.Insert(vhc_ID, 0);
                break;

            case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
                local me = AIEventVehicleWaitingInDepot.Convert(e);
                /* sell the vehicle if it is old -- handled */
                local vhc_ID = me.GetVehicleID();
                AILog.Info(AIVehicle.GetName(vhc_ID) + " is waiting");
                /* reserved for vehicle_refit feature in future */
                break;

            case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
                local me = AIEventVehicleUnprofitable.Convert(e);
                this.old_vehicle.Insert(me.GetVehicleID(), 0);
                break;

            case AIEvent.AI_ET_INDUSTRY_OPEN:
                local me = AIEventIndustryOpen.Convert(e);
                si = me.GetIndustryID();
                AILog.Info("Congratulation on grand opening " + AIIndustry.GetName(si));
                if (AIIndustry.IsBuiltOnWater(si)) break;
                if (!AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(si))) break;
                /* clear keys */
                while (this.service_keys.Count() > 0) this.service_keys.Pop();
                break;

            case AIEvent.AI_ET_INDUSTRY_CLOSE:
                local me = AIEventIndustryClose.Convert(e);
                si = me.GetIndustryID();
                AILog.Info("Sadly enough, Good bye "+ AIIndustry.GetName(si));
                if (AIIndustry.IsBuiltOnWater(si)) break;
                if (!AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(si))) break;
                /* clear keys */
                industry_will_close.push(si);
                while (this.service_keys.Count() > 0) this.service_keys.Pop();
                break;

            case AIEvent.AI_ET_ENGINE_AVAILABLE:
                local me = AIEventEngineAvailable.Convert(e);
                si = me.GetEngineID();
                AILog.Info(AIEngine.GetName(si) + " Available");
                this.new_engines.push(si);
                break;

            case AIEvent.AI_ET_STATION_FIRST_VEHICLE:
                /*
                 * local me = .Convert(e);
                 * AILog.Info("");
                 * me.
                 */
                break;

            case AIEvent.AI_ET_DISASTER_ZEPPELINER_CRASHED:
                /*
                 * local me = .Convert(e);
                 * AILog.Info("");
                 * me.
                 */
                break;

            case AIEvent.AI_ET_DISASTER_ZEPPELINER_CLEARED:
                /*
                * local me = .Convert(e);
                * AILog.Info("");
                * me.
                */
                break;

            case AIEvent.AI_ET_INVALID:
                AILog.Info("Dunno why it is there" );
                break;

            default : Debug.DontCallMe("Events");
        }
        e = null;
        si = null;
    }
}

/**
 * Transport Servicing (pick an ID from table)
 */
function CompanyManager::Service()
{
    AILog.Info("Try servicing");
    local to_do = null;
    Bank.Get(0);

    if (rail_backbones.len() > 0) {
        if (Assist.Connect_BackBone(this.Builder, this.rail_backbones.top())) this.rail_backbones.pop();
    }

    while (this.service_keys.Count() > 0) {
        AILog.Info("Current Serv "+ this.current_service);
        if (this.current_service == 0) this.current_service = this.service_keys.Pop();
        if (this.current_service in this.serviced_route) this.current_service = 0;
        if (this.current_service in this.expired_route) this.current_service = 0;
        if (this.current_service in this.service_tables) {
            to_do = this.service_tables[this.current_service];
            if (to_do.Source.LastMonthTransported(to_do.Source.ID, to_do.Cargo) > 70) to_do = null;
        }
        if (Debug.ResultOf("Service Validity", to_do != null && to_do.Source.IsValid() && to_do.Destination.IsValid())) {
            AILog.Info(to_do.Readable);
            Debug.Sign(to_do.Source.Location,"Src");
            Debug.Sign(to_do.Destination.Location,"Dst");
            switch (to_do.VehicleType) {
                case AIVehicle.VT_RAIL:
                    if (this.Builder.RailServicing(to_do)) break;
                    to_do = Services.RefreshTable(to_do);
                    to_do.TrackType = AIRoad.ROADTYPE_ROAD;
                    to_do.VehicleType = AIVehicle.VT_ROAD;
                case AIVehicle.VT_ROAD:
                    if (!this.Builder.RoadServicing(to_do)) this.expired_route[to_do.ID] <- to_do.ID;
                    break;
                default : Debug.DontCallMe("Unsupported");
            }
            this.current_service = 0;
            break;
        }
        this.current_service = 0;
    }
    Builder.ClearSigns();
}

/**
 * Sleep Time
 * @return The amount time for manager to sleep :-)
 */
function CompanyManager::SleepTime()
{
  local utang = max(AICompany.GetLoanAmount(), 10000);
  return (utang / 1000).tointeger();
}
