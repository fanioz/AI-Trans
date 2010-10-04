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
		game_start = "game_creation.starting_year",
	},
	
	/** Vehicle type - order is important */
	VType = [AIVehicle.VT_RAIL, AIVehicle.VT_ROAD, AIVehicle.VT_WATER, AIVehicle.VT_AIR],
	/** Vehicle type in string - order is important */
	VType_Str = ["RAIL", "ROAD", "WATER", "AIR"],
	
	/** Corner tile */
	Corner = [AITile.CORNER_W, 	//West corner.
			AITile.CORNER_S,	//South corner.
			AITile.CORNER_E,	//East corner.
			AITile.CORNER_N,	//North corner.
		],
		
	/** Store the cost of track */
	Cost = {
			Road = {},
			Rail = {},
			Water = {},
	},
	
	/** Industry closed structure */
	IndustryClosed = {
		ID = 0,
		Loc = 0,
		CargoAccept = [],
		CargoProduce = [],
	},
	
	/** All rail track */
	RailTrack = [AIRail.RAILTRACK_NE_SW, AIRail.RAILTRACK_NW_SE, AIRail.RAILTRACK_NW_NE,
		AIRail.RAILTRACK_SW_SE, AIRail.RAILTRACK_NW_SW, AIRail.RAILTRACK_NE_SE],
		
	/** Rail station direction */
	RailStationDir = [AIRail.RAILTRACK_NE_SW, AIRail.RAILTRACK_NW_SE],
	
	/** AIRoad type list */
	RoadTypeList = [AIRoad.ROADTYPE_TRAM, AIRoad.ROADTYPE_ROAD],
}
