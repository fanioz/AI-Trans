/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/* required to be known by OpenTTD */
require("dependencies.nut");

/**
 * extending Base class
 */
class Trans extends Base
{
	ID = -1;
	_Yearly_Profit = 0;
	_Load = null;
	_Service_Table = {};
	_Vehicles = {};
	_No_Profit_Vhc = CLList();
	_Subsidies = CLList();
	dataIntegrity = null;

	constructor() {
		::Base.constructor("Trans");
		::My = this;
		::My.ID = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		dataIntegrity = false;
	}

	/**
	  * Start main AI class
	  */
	function Start() {
		AIController.Sleep(5);
		local line = CLString.Repeat("~", 50);
		try {
			/* Wake up .. */
			Info("Init AI's module");
			AILog.Warning(line);
			Setting.Init();
			AILog.Warning(line);
			XCargo.Init(XCargo);
			Service.Init(this);
			AILog.Warning(line);
			AIGroup.EnableWagonRemoval(true);

			/* greeting you */
			local date = AIDate.GetCurrentDate();
			SetRandName(date);
			Info("(re)started as", AICompany.GetName(::My.ID), "at", Assist.DateStr(date));
			Info("is powered by ", _version_);

			Money.Pay();
			Assist.RemoveAllSigns();

			Info("Init task items");
			TaskManager.New(Task.Events());
			TaskManager.New(Task.BuildHQ());
			TaskManager.New(Task.CurrentValue());
			TaskManager.New(Task.RouteManager());
			TaskManager.New(Task.CleanUp());
			TaskManager.New(Task.TrackDoubler());

			/*
			* ============ Main Loop ================
			*/
			while (true) {
				AIController.Sleep(2);
				/* run the task manager */
				TaskManager.Run();
			}
		} catch (msg) {
			::print("Error catched at:" + Assist.DateStr(AIDate.GetCurrentDate()));
		}
		/*
		* ====================================
		* Out of loop mean something goes wrong. Destructor called
		*/
		Const = null;
		::My = null;
		AIController.Sleep(10);
		Assist.RemoveAllSigns();
		AILog.Warning("=====> I would thank you very much if you would please to :");
		::print("1. Scroll up until the beginning of red line");
		::print("2. Make sure that the window wide enough to show all text");
		::print("3. Press ctrl-S to take a screenshoot");
		::print("4. Make a report (with the screenshoot) at Trans-AI thread on:");
		::print("http://www.tt-forums.net/viewtopic.php?f=65&t=42272");
		AILog.Warning("=========< OR >=========");
	}

	/**
	 * Handle save game of OpenTTD
	 */
	function Save() {
		TaskManager.RunSave();
		if (this.dataIntegrity) return Service.Data;
		AILog.Error("No data saved!");
		return {};
	}

	/**
	 * Handle loading savegame by OpenTTD
	 */
	function Load(version, data) {
		Warn(" Loading from ver:", version);
		Warn("type of data was", typeof data);
		_Load = data;
		TaskManager.RunLoad();
	}

	function SetRandName(number) {
		while (AICompany.GetName(My.ID).find("Trans") == null) {
			number++;
			local c = number % Const.Name.len();
			local name = "Trans " + Const.Name[c];

			if (AICompany.SetPresidentGender(AICompany[Const.Gender[c % 2]])) {
				if (AICompany.SetPresidentName(name)) AICompany.SetName(name);
			}
		}
	}
}
