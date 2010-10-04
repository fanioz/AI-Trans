/*
 *      09.02.06
 *      building.nut
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
 */


/**
 * Class BuildingHandler
 * super class of all builder
 */
class BuildingHandler {

    _lastCost = null;               /// store the last cost of command
    _costHandler = null;            /// AIAccounting instance
    _test_flag = null;              /// flag indicator test mode
    _commander = null;            /// My Bos instance
    State = null;                 /// The state of this builder
    Road = null;                   /// RoadBuilder Class
    Rail = null;                 /// RailBuilder class
    ff_factor = null;              /// Cost ff_factor

    constructor(commander) {
        _lastCost = 0;
        _costHandler = AIAccounting();
        _test_flag = false;
        _commander = commander;
        State = BuildingHandler.state(this);
        Road = BuildingHandler.road(this);
        Rail = BuildingHandler.rail(this);
        ff_factor = _commander.ff_factor;
        AIRail.SetCurrentRailType(AIRailTypeList().Begin());
    }
}

/**
 * HeadQuarter builder.
 * Build my HQ on random suitable site if I haven't yet or
 * @return tile location
 */
function BuildingHandler::HeadQuarter()
{
    local hq = AICompany.GetCompanyHQ(AICompany.COMPANY_SELF);
    if (AIMap.IsValidTile(hq)) return hq;
    this._costHandler.ResetCosts();

    local loc = AITownList();
    loc.Valuate(AITown.GetPopulation);
    loc.KeepBottom(1);
    loc = Tiles.Flat(Tiles.OfTown(loc.Begin(), Tiles.Radius(AITown.GetLocation(loc.Begin()), 20)));
    loc.Valuate(AITile.IsBuildableRectangle,3,3);
    loc.RemoveValue(0);
    foreach (location, val in loc) {
        AIController.Sleep(2);
        if (!AITile.IsBuildableRectangle(location, 3, 3)) continue;
        if (AICompany.BuildCompanyHQ (location)) return location;
    }
    this._lastCost = this._costHandler.GetCosts();
}


/**
 * ClearSigns is AISign cleaner
 * Clear all sign that I have been built while servicing.
 */
function BuildingHandler::ClearSigns()
{
    AILog.Info("Clearing signs ...");
    local c = AISign.GetMaxSignID ();
  while (c > -1) {
    if (AISign.IsValidSign(c)) AISign.RemoveSign(c);
    c--;
  }
}

/**
 * Servicing a route defined before by Road Vehicle
 */
function BuildingHandler::RoadServicing(serv)
{
    AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
    //AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
    Debug.Sign(serv.Source.Location,"Src");
    Debug.Sign(serv.Destination.Location,"Dst");
    serv.Source.Refresh();
    serv.Destination.Refresh();
    serv.SourceDepot <- Platform();
    serv.DestinationDepot <- Platform();
    serv.SourceStation <- Stations();
    serv.DestinationStation <- Stations();
    local service_cost = 0;

    AILog.Warning("Test Mode");
    this.State.TestMode = true;
    if (!this.Road.Vehicle(serv)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;
    //this.State.TestMode = false;

    if (!this.Road.Path(serv, 0 false)) this.Road.Path(serv, 0, true);
    if (!this.Road.Track(serv, 0)) return false;
    service_cost += this.State.LastCost * 1.5;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Station(serv, true)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Station(serv, false)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Depot(serv, true)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Road.Depot(serv, false)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    //this.Road.Path(serv, 1, true);
    //if (!this.Road.Track(serv, 1)) return false;
    //service_cost += this.State.LastCost;
    //if (!Bank.Get(service_cost * 1.2)) return false;

    //this.Road.Path(serv, 2, true);
    //if (!this.Road.Track(serv, 2)) return false;
    //service_cost += this.State.LastCost;
    //if (!Bank.Get(service_cost * 1.2)) return false;

    //this.Road.Path(serv, 3, true);
    //if (!this.Road.Track(serv, 3)) return false;
    //service_cost += this.State.LastCost;

    /* don't continue if I've not enough money */
    if (!Bank.Get(service_cost)) return false;

    AILog.Warning("Real Mode");
    this.State.TestMode = false;
    //if (!this.Road.Track(serv, 1)) return false;
    if (!this.Road.Depot(serv, true)) return false;
    if (!this.Road.Depot(serv, false)) return false;

    if (!this.Road.Station(serv, true)) return false;
    if (!this.Road.Station(serv, false)) return false;

    //if (!this.Road.Track(serv, 0)) {
    //serv.Path0 = false;
    //this.Road.Path(serv, 0, true);
    //if (!this.Road.Track(serv, 0)) return false;
    //}

    if (!this.Road.Path(serv, 1, false)) {
        this.Road.Path(serv, 1, true);
        if (!this.Road.Track(serv, 1)) {
        this.Road.Path(serv, 1, true);
        if (!this.Road.Track(serv, 1)) return false;
        }
    }

    if (!this.Road.Path(serv, 2, false)) {
        this.Road.Path(serv, 2, true);
        if (!this.Road.Track(serv, 2)) {
        this.Road.Path(serv, 2, true);
        if (!this.Road.Track(serv, 2)) return false;
        }
    }

    if (!this.Road.Path(serv, 3, false)) {
        this.Road.Path(serv, 3, true);
        if (!this.Road.Track(serv, 3)) {
        this.Road.Path(serv, 3, true);
        if (!this.Road.Track(serv, 3)) return false;
        }
    }

    // I'm sad to return false after going so far
    if (!this.Road.Vehicle(serv)) return false;

    AIVehicle.StartStopVehicle(serv.MainVhcID);
    local grp = AIGroup.CreateGroup(serv.VehicleType);
    local g_name = this._commander.randomizer +":" + serv.ID;
    if (!AIGroup.SetName(grp, g_name)) {
        local grp_list = AIGroupList();
        grp_list.Valuate(AIGroup.GetVehicleType);
        grp_list.KeepValue(serv.VehicleType);
        foreach (idx, val in grp_list) {
            if (AIGroup.GetName(idx) == g_name) {
                AIGroup.DeleteGroup(grp);
                grp = idx;
                break;
            }
        }
    }
    AIGroup.MoveVehicle(grp, serv.MainVhcID);
    if (!serv.IsSubsidy) {
        /*name that station */
        local counter = 1;
        local name = AIIndustryType.GetName(AIIndustry.GetIndustryType(serv.Destination.ID)) + " " + this._commander.randomizer;
        while (!AIStation.SetName(serv.DestinationStation.GetID(), name + " Drop Off " + counter) && counter < 100) counter++;
    }

    this.Road.Vehicle(serv);
    /*update table of service*/
    this._commander.service_tables[serv.ID] <- serv;
    this._commander.serviced_route[serv.ID] <- true;
    return true;
}

/**
 * Servicing a route defined before by Rail Vehicle
 */
function BuildingHandler::RailServicing(serv)
{
    AIRail.SetCurrentRailType(AIRailTypeList().Begin());
    Debug.Sign(serv.Source.Location,"Src");
    Debug.Sign(serv.Destination.Location,"Dst");
    serv.Source.Refresh();
    serv.Destination.Refresh();
    serv.SourceDepot <- Platform();
    serv.DestinationDepot <- Platform();
    serv.SourceStation <- Stations();
    serv.DestinationStation <- Stations();

    local service_cost = 0;

    AILog.Warning("Test Mode");
    this.State.TestMode = true;

    if (!this.Rail.Vehicle(serv)) return false;
    service_cost += this.State.LastCost * 2;
    if (!Bank.Get(service_cost)) return false;
    //this.State.TestMode = false;

    this.Rail.Path(serv, 2, true);
    if (!this.Rail.Track(serv, 2)) {
        this.Rail.Path(serv, 2, true);
        if (!this.Rail.Track(serv, 2)) return false;
        this.Rail.Signal(serv, 2);
    }
    service_cost += this.State.LastCost * 2;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Rail.Station(serv, true)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Rail.Station(serv, false)) return false;
    service_cost += this.State.LastCost;
    if (!Bank.Get(service_cost)) return false;

    if (!this.Rail.Depot(serv, true)) return false;
    service_cost += this.State.LastCost * 2;
    if (!Bank.Get(service_cost)) return false;

    /* don't continue if I've not enough money */
    if (!Bank.Get(service_cost)) return false;

    AILog.Warning("Real Mode");
    this.State.TestMode = false;
    //if (!this.Rail.Track(serv, 1)) return false;

    if (!this.Rail.Station(serv, true)) return false;
    if (!this.Rail.Station(serv, false)) return false;

    this.Rail.Path(serv, 0, true);
    this.State.TestMode = true;
    if (!this.Rail.Track(serv, 0)) {
        this.Rail.Path(serv, 0, true);
        if (!this.Rail.Track(serv, 0)) return false;
    }
    this.State.TestMode = false;
    if (!this.Rail.Track(serv, 0)) return false;

    if (!this.Rail.Depot(serv, true)) return false;
    if (!this.Rail.Depot(serv, false)) return false;

    // I'm sad to return false after going so far
    if (!this.Rail.Vehicle(serv)) return false;
    AIVehicle.StartStopVehicle(serv.MainVhcID);

    local grp = AIGroup.CreateGroup(serv.VehicleType);
    local g_name = this._commander.randomizer +":" + serv.ID;
    if (!AIGroup.SetName(grp, g_name)) {
        local vhc_list = AIGroupList();
        vhc_list.Valuate(AIGroup.GetVehicleType);
        vhc_list.KeepValue(serv.VehicleType);
        foreach (idx, val in vhc_list) {
            if (AIGroup.GetName(idx) == g_name) {
                AIGroup.DeleteGroup(grp);
                grp = idx;
                break;
            }
        }
    }
    AIGroup.MoveVehicle(grp, serv.MainVhcID);

    if (!serv.IsSubsidy) {
        /*name that station */
        local counter = 1;
        local name = AIIndustryType.GetName(AIIndustry.GetIndustryType(serv.Destination.ID)) + " " + this._commander.randomizer;
        while (!AIStation.SetName(serv.DestinationStation.GetID(), name + " Drop Off " + counter) && counter < 100) counter++;
    }

    if (!Assist.Connect_BackBone(this, serv)) this._commander.rail_backbones.push(serv);

    /*update table of service*/
    this._commander.service_tables[serv.ID] <- serv;
    this._commander.serviced_route[serv.ID] <- true;
    return true;
}

/**
 *
 * The State of current builder
 */
class BuildingHandler.state {
    _main = null;
    constructor(main)
    {
      this._main = main;
    }

    function _set(idx, val)
    {
        switch (idx) {
            case "LastCost" :
                this._main._lastCost = val;
                break;
            case "TestMode" :
                this._main._test_flag = val;
                break;
          default : throw("the index '" + idx + "' does not exist");
        }
    }

    function _get(idx)
    {
        switch (idx) {
            case "LastCost" : return this._main._lastCost;
            case "TestMode" : return this._main._test_flag;
            default : throw("the index '" + idx + "' does not exist");
        }
    }
}
