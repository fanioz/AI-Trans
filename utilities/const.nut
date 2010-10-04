/*  09.05.05 - const.nut
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
		subsidy_multiply = "difficulty.subsidy_multiplier",
		long_train = "vehicle.mammoth_trains",
		realistic_acceleration = "vehicle.train_acceleration_model",
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
		forbid_90_deg = "pf.forbid_90_deg",
		disable_train = "ai.ai_disable_veh_train",
		disable_roadveh = "ai.ai_disable_veh_roadveh",
		disable_aircraft = "ai.ai_disable_veh_aircraft",
		disable_ship = "ai.ai_disable_veh_ship",
    },    
}
