/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XEngine class
 * an AIEngine eXtension
 */
class XEngine
{
	function Sort(engine_id) {
		return 10000000 * AIEngine.GetCapacity(engine_id) * AIEngine.GetMaxSpeed(engine_id) / AIEngine.GetPrice(engine_id);
	}

	function SortLoco(engine_id) {
		local fn = Setting.Get(SetString.realistic_acceleration) ? AIEngine.GetMaxSpeed : AIEngine.GetMaxTractiveEffort;
		return 10000000 * fn(engine_id) / AIEngine.GetPrice(engine_id);
	}

	function GetTrack(eng) {
		switch (AIEngine.GetVehicleType(eng)) {
			case AIVehicle.VT_RAIL:
				return AIEngine.GetRailType(eng);
			case AIVehicle.VT_AIR:
				return AIEngine.GetPlaneType(eng);
			case AIVehicle.VT_ROAD:
				return AIEngine.GetRoadType(eng);
			case AIVehicle.VT_WATER:
				return 1;
			default :
				return -1;
		}
	}
}
