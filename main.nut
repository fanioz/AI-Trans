/*  09.02.01 - main.nut
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
 * Trans AI global storage
 */
TransAI <- {
	/** Root Table */
	Root = null,
	/** Informations */
	Info = null,
	/** Station Manager */
	StationMan = null,
	/** Vehicle Manager */
	VehicleMan = null,
	/** Service Manager */
	ServiceMan = null,
	/** Serv-able Manager */
	ServableMan = null,
	/** Company Manager */
	CompanyMan = null,
	/** Task Manager */
	TaskMan = null,
	/** Our Bank Balance */
	Balance = null,
	/** Builder Manager */
	Builder = null,
	/** Rail back boner */
	RailBackBones = null,
	/** Things cost */
	Cost = null,
	/** Settings used */
	Setting = null,
};

/**
 * extending AIController class
 */
class Trans extends AIController
{
    EventChecker = null;

    constructor()
    {
    	/* required to be known by AIController */
    	require("dependencies.nut");
    	
    	TransAI.Root = this;
		TransAI.Info = Memory("Root");
		TransAI.Setting = Settings();
		/*----------- Wake up managers ------------------------*/
		TransAI.StationMan = StationManager();
		TransAI.ServiceMan = ServiceManager();
		TransAI.ServableMan = ServableManager();
		TransAI.CompanyMan = CompanyManager();
		TransAI.TaskMan = TaskManager();		
		TransAI.Builder = BuildingHandler();
		TransAI.RailBackBones = [];
		TransAI.Cost = Const.Cost;
		
		this.EventChecker = Task.Events();
		
		/*------------Read setting ---------------------------------*/
		/* Don't forget to set debug sign as false on Release or remove comment*/
		AILog.Warning("*=====================================*");
		TransAI.Setting.CheckVersion();
		TransAI.Setting.DebugSign = Debug.ResultOf("Build sign", AIController.GetSetting("debug_signs"));
		TransAI.Setting.AllowBus = Debug.ResultOf("Allow build bus", AIController.GetSetting("allow_bus"));
		TransAI.Setting.AllowTruck = Debug.ResultOf("Allow build truck", AIController.GetSetting("allow_truck"));
		TransAI.Setting.AllowTrain = Debug.ResultOf("Allow build train", AIController.GetSetting("allow_train"));
		TransAI.Setting.LastMonth = Debug.ResultOf("Min. last month transported", AIController.GetSetting("last_transport"));
		TransAI.Setting.LoopTime = Debug.ResultOf("Speed", AIController.GetSetting("loop_time")); 
    }

	/**
	  * Start main AI class
	  */
	function Start()
	{
		Sleep(5);
		AILog.Warning("*=====================================*");
		TransAI.CompanyMan.Born();
		TransAI.CompanyMan.Test();
		AILog.Info("Init task schedule");		
		try {
			
			TransAI.TaskMan.New(EventChecker);
			TransAI.TaskMan.New(Task.HeadQuarter());
			TransAI.TaskMan.New(Task.Monitor());
			TransAI.TaskMan.New(Task.CurrentValue());
			TransAI.TaskMan.New(Task.Maintenance());
			TransAI.TaskMan.New(Task.Inflation());
			TransAI.TaskMan.New(Task.Service());
			TransAI.TaskMan.New(Task.GenerateServable());
			TransAI.TaskMan.New(Task.AddVehicle());
			TransAI.TaskMan.New(Task.PayLoan());
			TransAI.TaskMan.New(Task.SellVehicle());
			
			/* set loop time */
			TransAI.TaskMan.SetSleep(max(1, TransAI.Setting.LoopTime) * 5);
			
			/*
			* ============ Main Loop ================
			*/    
			while (TransAI.Info.Live){        
				Sleep(1);
				/* run the task manager */
				TransAI.TaskMan.Run();
			}
		} catch (msg) {
			TransAI.Builder.ClearSigns();
			AILog.Warning("Error catched:" + msg);
		}
		/*
		* ====================================
		* Out of loop mean something goes wrong. Destructor called
		*/
		Const = null;
		TransAI = null;
		AILog.Info("Visit TransAI thread on:");
		AILog.Info("http://www.tt-forums.net/viewtopic.php?f=65&t=42272");
		AILog.Warning("=========< OR >=========");
	}

	/**
	 * Handle save game of OpenTTD
	 */
	function Save()
	{
		try {
			local save_table = {};
			EventChecker.Execute();
			save_table.rawset(TransAI.Info.GetClassName(), TransAI.Info.GetStorage());
			save_table.rawset(TransAI.StationMan.GetClassName(), TransAI.StationMan.GetStorage());    
			AILog.Info("--- (partial) Save supported ---");
			return save_table;
		} catch (msg) {
			AILog.Error("Can't save");
			return {};
		}
	}

	/**
	 * Handle loading savegame by OpenTTD
	 */
	function Load(version, data)
	{
		AILog.Warning("--- (experimental) Load supported ---");
		try {
			TransAI.Info.SetStorage(data.rawget(TransAI.Info.GetClassName()));
			TransAI.StationMan.SetStorage(data.rawget(TransAI.StationMan.GetClassName()));
		}
		catch (x) AILog.Warning("Failed load: Memory "+ x);    
		Debug.ResultOf("Loading (partial) from version", version);
	}
}
