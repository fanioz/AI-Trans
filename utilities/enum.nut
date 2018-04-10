/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/** Direction */
enum Direction {
	NE_SW = 1
	SW_NE = 2
	SE_NW = 4
	NW_SE = 8
}

/** Settings from config file */
enum SetString {
		subsidy_multiply = "difficulty.subsidy_multiplier" // 0 = 1.5, 1 = 2, 2 = 3, 3 = 4,
		max_loan = "difficulty.max_loan"
		breakdowns = "difficulty.vehicle_breakdowns"
		long_train = "vehicle.mammoth_trains"
		realistic_acceleration = "vehicle.train_acceleration_model"
		plane_speed_divisor = "vehicle.plane_speed"
		can_goto_depot = "order.gotodepot"
		build_on_slopes = "construction.build_on_slopes"
		autoslope = "construction.autoslope"
		extra_dynamite = "construction.extra_dynamite"
		longbridges = "construction.longbridges"
		dtrs_on_town = "construction.road_stop_on_town_road"
		dtrs_on_competitor = "construction.road_stop_on_competitor_road"
		raw_industry_construction = "construction.raw_industry_construction"
		freeform_edges = "construction.freeform_edges"
		always_small_airport = "station.always_small_airport"
		join_stations = "station.join_stations"
		nonuniform_stations = "station.nonuniform_stations"
		station_spread = "station.station_spread"
		modified_catchment = "station.modified_catchment"
		adjacent_stations = "station.adjacent_stations"
		distant_join_stations = "station.distant_join_stations"
		infrastructure_maintenance = "economy.infrastructure_maintenance"
}
