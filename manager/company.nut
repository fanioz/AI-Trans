/*  09.02.08 - company.nut
 *
 *  This file is part of Trans AI
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
 */

 /**
 * CompanyManager
 * Company management class
 */
class CompanyManager
{
	constructor()
	{
		TransAI.Info.ID = null;	///< Used ID as randomizer
		TransAI.Info.Live = null;	///< Should I keep alive or retire ?
		TransAI.Info.Start_date = 0;	///< Company launching date
		TransAI.Info.Name = "Fanioz";	///<  President name of my company
		TransAI.Info.Factor = 0;	///< factor of fluctuation
		TransAI.Info.Drop_off_point = {}; ///< Drop off table
		TransAI.Info.Industry_Close = []; ///< Store will closing industry		
		TransAI.Info.New_Engines = []; ///< Store new available engines
		TransAI.Info.Lost_Vehicle = []; ///< Store Lost_Vehicle marked
		TransAI.Info.InTrouble = false; ///< Reminder if we are in trouble
		TransAI.Info.Current_Service = null;
	    TransAI.Info.Serviced_Route = {};
	    TransAI.Info.Expired_Route = {};
	    TransAI.Info.Vehicle_Sent = [];	    
	}

	/**
	 * Company Start-Up
	 */
	function Born()
	{
		/* Wake up .. */
		AICompany.SetAutoRenewStatus(true);
		AICompany.SetAutoRenewMonths(-12);
		AICompany.SetAutoRenewMoney(10000);
		AIGroup.EnableWagonRemoval(true);

		/* Detect saved session */
		if (TransAI.Info.Start_date == 0) TransAI.Info.Start_date = AIDate.GetCurrentDate();		
		if (TransAI.Info.Live == null) TransAI.Info.Live = 1;
		if (TransAI.Info.ID == null) TransAI.Info.ID = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
		if (AICompany.GetPresidentName(TransAI.Info.ID) != TransAI.Info.Name) {
			/* Set my name */
			local i = 1;
			if (!AICompany.SetPresidentName(TransAI.Info.Name)) {
				while (!AICompany.SetPresidentName(TransAI.Info.Name + " " + i + " (jr.)")) {
					i++;
					AIController.Sleep(1);
				}
			}
			TransAI.Info.Name = AICompany.GetPresidentName(TransAI.Info.ID);
			AICompany.SetName(TransAI.Info.Name + " Trans Corp.");
		}
		/* greeting you */
		AILog.Info("" + AICompany.GetName(TransAI.Info.ID) + " has been started since " + Assist.DateStr(TransAI.Info.Start_date));
		AILog.Info("Powered by " + _version_);
		Settings.Version();
		Debug.ResultOf("Random factor", TransAI.Info.ID);
		if (TransAI.Info.Factor == 0) TransAI.Info.Factor = AICompany.GetMaxLoanAmount() / 10000;
	}



	/**
	 * Place to test something(
	 * @return up to you
	 */
	function Test()
	{
		//AILog.Info("Testing...");
		//AILog.Info("done!");
	}
}

/**
 * Evaluate all vehicles, stations, connections
 */
function CompanyManager::Evaluate()
{
    AILog.Info("Evaluating...");

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

    
}


/**
 * Clearing events routine before save
 * @note Make sure, never use do command
 */
class Task.Events extends DailyTask
{
    constructor()
    {
        ::DailyTask.constructor("Events Check");
        ::DailyTask.SetRemovable(false);
        ::DailyTask.SetKey(1);
    }

	function Execute()
    {
    	::DailyTask.Execute();
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
                    local _func = function(val) { return val ? AITown : AIIndustry; };
                    local src = _func(AISubsidy.SourceIsTown(si)).GetLocation(AISubsidy.GetSource(si));
                    local dst = _func(AISubsidy.DestinationIsTown(si)).GetLocation(AISubsidy.GetDestination(si));
                    si = Services.CreateID(src, dst, AISubsidy.GetCargoType(si));                    
                    if (!TransAI.Info.Serviced_Route.rawin(si)) TransAI.Info.Expired_Route[si] <- {};                    
                break ;

                case AIEvent.AI_ET_SUBSIDY_AWARDED:
                    local esa = AIEventSubsidyAwarded.Convert(e);
                    si = esa.GetSubsidyID();
                    AILog.Info("SubsidyID " + si + " awarded");
                    if (AICompany.IsMine(AISubsidy.GetAwardedTo(si))) break;
                    local _func = function(val) { return val ? AITown : AIIndustry; };
                    local src = _func(AISubsidy.SourceIsTown(si)).GetLocation(AISubsidy.GetSource(si));
                    local dst = _func(AISubsidy.DestinationIsTown(si)).GetLocation(AISubsidy.GetDestination(si));
                    si = Services.CreateID(src, dst, AISubsidy.GetCargoType(si));
                    if (!TransAI.Info.Serviced_Route.rawin(si)) TransAI.Info.Expired_Route[si] <- {};
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
                    TransAI.TaskMan.New(Task.AcceptPreview(me));
                break;

                case AIEvent.AI_ET_COMPANY_NEW:
                    local me = AIEventCompanyNew.Convert(e);
                    si = me.GetCompanyID();
                    AILog.Warning("Welcome " + AICompany.GetName(si));
                break;

                case AIEvent.AI_ET_COMPANY_MERGER:
                    local me = AIEventCompanyMerger.Convert(e);
                    si = AICompany.GetName(me.GetOldCompanyID()) + "<->" + AICompany.GetName(me.GetNewCompanyID());
                    AILog.Info("And now come, the merger between " + si);
                break;

                case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
                    local me = AIEventCompanyInTrouble.Convert(e);
                    if (AICompany.IsMine(me.GetCompanyID())) {
                        TransAI.Info.InTrouble = true;
                        AILog.Warning("Going to sleep");
                    }
                break;

                case AIEvent.AI_ET_COMPANY_BANKRUPT:
                    local me = AIEventCompanyBankrupt.Convert(e);
                    si = me.GetCompanyID();
                    if (AICompany.IsMine(si)) {
                        TransAI.Info.Live = 0;
                        AILog.Info("Going to sleep");
                    } else AILog.Info("Good bye " + AICompany.GetName(si));
                break;

                /*
                future version will redo pathfinding to avoid this
                */
                case AIEvent.AI_ET_VEHICLE_CRASHED:
                    /*
                    * local me = AIEventVehicleCrashed.Convert(e);
                    AILog.Info("");
                    me.
                    */
                break;

                case AIEvent.AI_ET_VEHICLE_LOST:
                    local me = AIEventVehicleLost.Convert(e);
                    local vhc_ID = me.GetVehicleID();
                    AILog.Info("Vehicle lost " + AIVehicle.GetName(vhc_ID));
                    TransAI.Info.Lost_Vehicle.push(vhc_ID);
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
                    local vhc_ID = me.GetVehicleID();
                    AILog.Info(AIVehicle.GetName(vhc_ID) + " is unprofitable");
                break;

                case AIEvent.AI_ET_INDUSTRY_OPEN:
                    local me = AIEventIndustryOpen.Convert(e);
                    si = me.GetIndustryID();
                    AILog.Info("Congratulation on grand opening " + AIIndustry.GetName(si));
                break;

                case AIEvent.AI_ET_INDUSTRY_CLOSE:
                    local me = AIEventIndustryClose.Convert(e);
                    si = me.GetIndustryID();
                    AILog.Info("Sadly enough, Good bye "+ AIIndustry.GetName(si));
                    TransAI.Info.Industry_Close.push(si);
                break;

                case AIEvent.AI_ET_ENGINE_AVAILABLE:
                    local me = AIEventEngineAvailable.Convert(e);
                    si = me.GetEngineID();
                    AILog.Info(AIEngine.GetName(si) + " Available");
                    TransAI.Info.New_Engines.push(si);
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
        AILog.Info("No more events");
    }
}

/**
 * Evaluate current company value
 */
class Task.CurrentValue extends DailyTask
{
	constructor()
	{
		::DailyTask.constructor("Current Value");
		::DailyTask.SetRemovable(false);
		::DailyTask.SetKey(30);
	}

	function Execute()
	{
		::DailyTask.Execute();
		this.SetResult(AICompany.GetCompanyValue(TransAI.Info.ID));
		AILog.Info("===" + Assist.DateStr(AIDate.GetCurrentDate()) +"===>" + this.GetResult());
	}
}

/**
 * Update factor of inflation
 */
class Task.Inflation extends DailyTask
{
	constructor()
	{
		::DailyTask.constructor("Inflation Check");
		::DailyTask.SetRemovable(false);
		::DailyTask.SetKey(365);
	}

	function Execute()
	{
		::DailyTask.Execute();
		TransAI.Factor10 <- (AICompany.GetMaxLoanAmount() / TransAI.Info.Factor).tointeger();
		AILog.Info("10000 => " + TransAI.Factor10);
	}
}

/**
 * Maintenace Infrastructure
 * @note possibly upgrade too
 */
class Task.Maintenance extends DailyTask
{
	constructor()
	{
		::DailyTask.constructor("Maintenance Task");
		::DailyTask.SetRemovable(false);
		::DailyTask.SetKey(30);
	}

	function Execute()
	{
		::DailyTask.Execute();
		AILog.Info("done!");
		// TODO :: Maintenance
	}
}

/**
 * Monitor state changes
 */
class Task.Monitor extends DailyTask
{
	_addserv = null;
    constructor()
    {
        ::DailyTask.constructor("Monitor Task");
        ::DailyTask.SetRemovable(false);
        ::DailyTask.SetKey(2);        
    }

    function Execute()
    {
    	::DailyTask.Execute();
    	if (Debug.ResultOf("Drop point invalid", !TransAI.DropPointIsValid)) TransAI.TaskMan.New(Task.GenerateDropOff());
    	
    	/// see we are in trouble ?
    	if (TransAI.Info.InTrouble) Bank.Get(AICompany.GetLoanInterval());
    	
    	/// see are we have pending backbone
    	if (TransAI.RailBackBones.len()) {
    		foreach (idx, serv in TransAI.RailBackBones) {
    			if (Assist.Connect_BackBone(serv)) {
    				TransAI.RailBackBones.rawdelete(idx);
    			}
    		} 
    	}
    	/* check to see a will close industry */
    	if (TransAI.Info.Industry_Close.len()) Assist.HandleClosingIndustry(TransAI.Info.Industry_Close.pop());
    	
    	if (TransAI.Info.Lost_Vehicle.len()) {
    	}
    	
    	/* check to see any new engine */
    	if (TransAI.Info.New_Engines.len() > 0) Vehicles.UpgradeEngine(TransAI.Info.New_Engines.pop());
    	
    	/* check vehicle in depot */
    	foreach(vhc_id, val in AIVehicleList()) {
    		if (!AIVehicle.IsStoppedInDepot(vhc_id)) continue;
    		AILog.Info("" + AIVehicle.GetName(vhc_id) + " is inside depot");
    		local g = AIVehicle.GetGroupID(vhc_id);
    		if (AIGroup.GetNumEngines(g, AIVehicle.GetEngineType(vhc_id)) == 1) Vehicles.Sold(vhc_id)
    		else AIVehicle.SellVehicle(vhc_id);
    	}
    }
}

/**
 * Accept Preview
 */
class Task.AcceptPreview extends TaskItem
{
	/** Parent class of Preview event */
	par_class = null;

	/**
	 * class contructor
	 * @param pc Parent class of Preview event
	 */
    constructor(pc)
    {
        ::TaskItem.constructor("Accept Preview Task");
        ::TaskItem.SetRemovable(true);
        ::TaskItem.SetKey(10); 
        par_class = pc;
    }

    function Execute()
    {
    	::TaskItem.Execute();
    	par_class.AcceptPreview();
    	AILog.Info("Preview Vehicle:" + par_class.GetName());
    	par_class = null;    	
    }
}
