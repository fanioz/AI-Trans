/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Constanta useful in program
 */
Const <- {
	/** Direction */
	Direction = {
		NE_SW = 1,
		SW_NE = 2,
		SE_NW = 4,
		NW_SE = 8,
	},
	/** Settings from config file */
	Settings = {
		subsidy_multiply = "difficulty.subsidy_multiplier", // 0 = 1.5, 1 = 2, 2 = 3, 3 = 4,
		max_loan = "difficulty.max_loan",
		breakdowns = "difficulty.vehicle_breakdowns",
		long_train = "vehicle.mammoth_trains",
		realistic_acceleration = "vehicle.train_acceleration_model",
		plane_speed_divisor = "vehicle.plane_speed",
		can_goto_depot = "order.gotodepot",
		build_on_slopes = "construction.build_on_slopes",
		autoslope = "construction.autoslope",
		extra_dynamite = "construction.extra_dynamite",
		longbridges = "construction.longbridges",
		dtrs_on_town = "construction.road_stop_on_town_road",
		dtrs_on_competitor = "construction.road_stop_on_competitor_road",
		raw_industry_construction = "construction.raw_industry_construction",
		freeform_edges = "construction.freeform_edges",
		always_small_airport = "station.always_small_airport",
		join_stations = "station.join_stations",
		nonuniform_stations = "station.nonuniform_stations",
		station_spread = "station.station_spread",
		modified_catchment = "station.modified_catchment",
		adjacent_stations = "station.adjacent_stations",
		distant_join_stations = "station.distant_join_stations",
	},
	
	/** Vehicle type - order is important */
	VType = [AIVehicle.VT_RAIL, AIVehicle.VT_ROAD, AIVehicle.VT_WATER, AIVehicle.VT_AIR],
	
	/** Corner tile */
	Corner = [AITile.CORNER_W, AITile.CORNER_S, AITile.CORNER_E, AITile.CORNER_N],
	
	/** All rail track */
	RailTrack = [
		AIRail.RAILTRACK_NE_SW, AIRail.RAILTRACK_NW_SE, AIRail.RAILTRACK_NW_NE,
	    AIRail.RAILTRACK_SW_SE, AIRail.RAILTRACK_NW_SW, AIRail.RAILTRACK_NE_SE
	],
		
	/** Rail station direction */
	RailStationDir = [AIRail.RAILTRACK_NE_SW, AIRail.RAILTRACK_NW_SE],
	
	/** AIRoad type list */
	 RoadTypeList = [AIRoad.ROADTYPE_ROAD, AIRoad.ROADTYPE_TRAM],

	/** Plane Type **/
	PlaneType = [AIAirport.PT_BIG_PLANE, AIAirport.PT_SMALL_PLANE, AIAirport.PT_HELICOPTER],

	/** Airport available */
	AirportType = [
		AIAirport.AT_INTERCON, AIAirport.AT_INTERNATIONAL, AIAirport.AT_METROPOLITAN,
		AIAirport.AT_LARGE,	AIAirport.AT_COMMUTER, AIAirport.AT_SMALL,
		AIAirport.AT_HELISTATION, AIAirport.AT_HELIDEPOT, AIAirport.AT_HELIPORT
	],

	/** real station type */
	StationType = [
		AIStation.STATION_TRAIN, AIStation.STATION_TRUCK_STOP, AIStation.STATION_BUS_STOP,
		AIStation.STATION_AIRPORT, AIStation.STATION_DOCK
	],

	/** possible name and gender */
	Name = [
		"Sour", "Sweet", "Cool", "Hot", "Winter", "Summer", "Cute",
		"Chubby", "Continent", "Sea", "Sun", "Moon", "Angel", "Evil"
	],

	Gender = ["GENDER_MALE", "GENDER_FEMALE"]
}

/**
 * My global storage
 */
My <- null;
_root_ <- this;
