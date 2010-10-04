/*
 *   09.02.01
 *   main.nut
 *
 *   Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *   MA 02110-1301, USA.
 */

require("libraries.nut");

/**
 * extending AIController class
 */
class Trans extends AIController
{
    manager = null;         /// the manager of Company
    save_table = {};          /// Table Auto Save

    constructor()
    {
        manager = CompanyManager(this);
        save_table = {};
    }
}

/**
  * Start main AI class
  */
function Trans::Start()
{
    Sleep(5);
    this.manager.Born();
    this.manager.Test();
    Bank.PayLoan();
    /*
    * ============ Main Loop ================
    */
    local wait_time = 0;
    while (this.manager.live != 0){
        wait_time += 10;
        Sleep(this.manager.SleepTime());
        this.manager.Events();
        if (wait_time % 40 == 0) {
            AILog.Info("============" + Assist.DateStr(AIDate.GetCurrentDate()) + "============");
            AILog.Info("Company Value ::" + AICompany.GetCompanyValue(AICompany.COMPANY_SELF));
            this.manager.Evaluate();
        }
        if (wait_time % 80 == 0) {
            if (AISubsidyList().Count() > 1 ||
                AIBase.Chance(1, 4) ||
                (this.manager.serviced_route.len() == 0)) {
                    this.manager.Service();
            }
        }

        if (this.manager.live == 1) Bank.PayLoan();
    }
    /*
    * ====================================
    */
    Debug.DontCallMe("main.loop");
}

/**
 * Handle save game of OpenTTD
 */
function Trans::Save()
{
    this.manager.Events();
    save_table.Trans_ID <- this.manager.my_name;
    save_table.Start_Date <- this.manager.start_date;
    save_table.My_Live <- this.manager.live;
    save_table.Randomizer <- this.manager.randomizer;
    save_table.Current_Service <- this.manager.current_service;
    save_table.Serviced_Route <- this.manager.serviced_route;
    save_table.Drop_Off_Point <- this.manager.drop_off_point;
    //save_table.Old_Vehicle <- this.manager.old_vehicle;
    save_table.Factor <- this.manager._factor;
    save_table.Expired_Route <- this.manager.expired_route;
    save_table.New_Engines <- this.manager.new_engines;
    save_table.Industry_Close <- this.manager.industry_will_close;
    save_table.Vehicle_Sent <- this.manager.vehicle_sent;
    //save_table.Rail_BackBones <- this.manager.rail_backbones;
    AILog.Info("--- (partial) Save supported ---");
    return save_table;
}

/**
 * Handle loading savegame by OpenTTD
 */
function Trans::Load(version, data)
{
    AILog.Warning("--- (experimental) Load supported ---");
    this.manager.my_name = Debug.ResultOf("Name ID", ("Trans_ID" in data) ? data["Trans_ID"] : "Fanioz");
    this.manager.start_date = Debug.ResultOf("Start Date", ("Start_Date" in data) ? data["Start_Date"] : 0);
    this.manager.live = Debug.ResultOf("Live state", ("My_Live" in data) ? data["My_Live"] : null);
    this.manager.randomizer = Debug.ResultOf("Randomizer", ("Randomizer" in data) ? data["Randomizer"] : null);
    this.manager.current_service = Debug.ResultOf("Current service", ("Current_Service" in data) ? data["Current_Service"] : 0);
    this.manager.serviced_route = Debug.ResultOf("Serviced route", ("Serviced_Route" in data) ? data["Serviced_Route"] : {});
    this.manager.drop_off_point = Debug.ResultOf("Drop Off Point", ("Drop_Off_Point" in data) ? data["Drop_Off_Point"] : {});
    //this.manager.old_vehicle = Debug.ResultOf("Old Vehicle", ("Old_Vehicle" in data) ? data["Old_Vehicle"] : []);
    this.manager._factor = Debug.ResultOf("Factor", ("Factor" in data) ? data["Factor"] : 0);
    this.manager.expired_route = Debug.ResultOf("Expired Route", ("Expired_Route" in data) ? data["Expired_Route"] : {});
    this.manager.new_engines = Debug.ResultOf("New Engines", ("New_Engines" in data) ? data["New_Engines"] : []);
    this.manager.industry_will_close = Debug.ResultOf("Industry closed", ("Industry_Close" in data) ? data["Industry_Close"] : []);
    this.manager.vehicle_sent = Debug.ResultOf("Vehicle sent", ("Vehicle_Sent" in data) ? data ["Vehicle_Sent"] : {});
    //this.manager.rail_backbones = Debug.ResultOf("Rail_BackBones", ("Rail_BackBones" in data) ? data["Rail_BackBones"] : []);
    Debug.ResultOf("Loading (partial) done from", version);
}
