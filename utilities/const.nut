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
