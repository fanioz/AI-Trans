/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Game settings related class
 */
class Setting
{
	Min_Town_Population = 300;	/// Minimum town population to be a drop off

	/**
	 * Get settings from .cfg file
	 * @param setting_str String of settings. Get it from Cons.Settings
	 * @return value from .cfg otherwise would crash if setting is no longer valid
	 * @note usage :
	 * print(SetString.long_train + " -> " +  Setting.Get(SetString.long_train))
	 */
	function Get(setting_str) {
		if (!AIGameSettings.IsValid(setting_str)) throw "Setting no longer valid :" + setting_str;
		return AIGameSettings.GetValue(setting_str);
	}

	function Init() {
		local ver = CLCommon.GetVersion();
		Info("Run On OpenTTD Ver:", ver.Major, ".", ver.Minor, "Build:", ver.Build, "(", (ver.IsRelease ?  "Release" : "Rev." + ver.Revision), ")");
		local need = 18520;
		if (ver.Revision < need) {
			Warn("need ", need, "and your is", ver.Revision);
			throw "Not match version";
		}
		local txt = ["invalid!", "Normal", "Sligthly slow", "More slow", "Very slow", "Slowest"];
		need = AIController.GetSetting("loop_time");
		AIController.SetCommandDelay(need);
		Setting.AllowPax <- AIController.GetSetting("allow_pax");
		Setting.AllowFreight <- AIController.GetSetting("allow_freight");
		Setting.Max_Transported <- AIController.GetSetting("last_transport");
		Setting.InfrastructureMaintenance <- Setting.Get(SetString.infrastructure_maintenance);
		Info("Speed was", txt[need]);
		txt = ["disabled", "enabled", "enabled"];
		local ar = Setting.Get(SetString.breakdowns);
		if (ar) {
			AICompany.SetAutoRenewMonths(-3);
			AICompany.SetAutoRenewStatus(true);
		} else {
			AICompany.SetAutoRenewStatus(false);
		}
		Info("Vehicle Autorenewal was", txt[ar]);
		Info("Passenger cargo was", txt[Setting.AllowPax]);
		Info("Freight cargoes were", txt[Setting.AllowFreight]);
		Info("Max. last month transported was", Setting.Max_Transported, "%");
		Info("Infrastructure Maintenance", txt[Setting.InfrastructureMaintenance]);

		AIGroup.EnableWagonRemoval(true);
	}

	/**
	 * Get maximum allowed number of vehicle
	 * @param vehicle_type vehicle type
	 * @return max.number
	 */
	function GetMaxVehicle(vehicle_type) {
		local sett = "vehicle.max_";
		switch (vehicle_type) {
			case AIVehicle.VT_AIR:
				sett += "aircraft";
				break;
			case AIVehicle.VT_RAIL:
				sett += "trains";
				break;
			case AIVehicle.VT_ROAD:
				sett += "roadveh";
				break;
			case AIVehicle.VT_WATER:
				sett += "ships";
				break;
		}
		return Setting.Get(sett);
	}
};
