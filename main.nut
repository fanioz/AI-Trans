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
	/** Accountant */
	Accountant = null,
	/** Invalidate drop off point */
	DropPointIsValid = null,
	/** Builder Manager */
	Builder = null,
	/** Rail back boner */
	RailBackBones = null,
	/** Whole Map Tiles */
	WholeMapTiles = null,
};

require("dependencies.nut");

/**
 * extending AIController class
 */
class Trans extends AIController
{
    EventChecker = null;

    constructor()
    {
    	TransAI.Root = this;
		TransAI.Info = Memory("Root");
		//TransAI.StationMan = StationManager();
		//TransAI.VehicleMan = VehicleManager();
		TransAI.ServiceMan = ServiceManager();
		TransAI.ServableMan = ServableManager();
		TransAI.CompanyMan = CompanyManager();
		TransAI.TaskMan = TaskManager();
		TransAI.Accountant = AIAccounting();
		TransAI.DropPointIsValid = false;
		TransAI.Builder = BuildingHandler();
		TransAI.RailBackBones = {};
		EventChecker = Task.Events();

		/* order is important */
		Const.VType <- [AIVehicle.VT_RAIL, AIVehicle.VT_ROAD, AIVehicle.VT_WATER, AIVehicle.VT_AIR];
		/* Corner tile */
		Const.Corner <-[AITile.CORNER_W, 	//West corner.
						AITile.CORNER_S,	//South corner.
						AITile.CORNER_E,	//East corner.
						AITile.CORNER_N,	//North corner.
		];
    }


	/**
	  * Start main AI class
	  */
	function Start()
	{
		Sleep(5);
		TransAI.WholeMapTiles = Tiles.WholeMap();
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
			TransAI.TaskMan.New(Task.GenerateService());
			TransAI.TaskMan.New(Task.AddVehicle());
			TransAI.TaskMan.New(Task.PayLoan());
			
			/*
			* ============ Main Loop ================
			*/    
			while (TransAI.Info.Live){        
				Sleep(1);
				/* run the task manager */
				TransAI.TaskMan.Run();
			}
		} catch (msg) {
			AILog.Warning("Error catched:" + msg);
		}
		/*
		* ====================================
		* Out of loop mean something goes wrong. Destructor called
		*/
		Const = null;
		TransAI = null;
		AILog.Info("Please make a bug report on OpenTTD-NoAI forum:");
		AILog.Info("http://www.tt-forums.net/viewtopic.php?f=65&t=42272");
		AILog.Warning("or");
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
		try TransAI.Info.SetStorage(data.rawget(TransAI.Info.GetClassName()))
		catch (x) AILog.Warning("Failed load: Memory "+ x);    
		Debug.ResultOf("Loading (partial) from version", version);
	}
}