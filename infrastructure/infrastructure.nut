/*  09.05.01 - Infrastructure.nut
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
 * Infrastructure :: station, vehicle, and depot only
 */
class Infrastructure extends Storable
{
	/* Use : AIVehicle::VehicleType
	* The type of a vehicle available in the game.
	* Trams for example are road vehicles, as maglev is a rail vehicle.
	* Enumerator:
	* VT_RAIL  Rail type vehicle.
	* VT_ROAD  Road type vehicle (bus / truck).
	* VT_WATER  Water type vehicle.
	* VT_AIR  Air type vehicle.
	* VT_INVALID  Invalid vehicle type.
	*/

	/**
	 * class constructor
	 */
	constructor() {
		::Storable.constructor();
		this._storage._location <- -1; ///< Top location of this object
		this._storage._type <- AIVehicle.VT_INVALID; ///< Vehicle Type
		this._storage._sub_type <- AIAirport.PT_INVALID;  ///< Vehicle sub type
		this._storage._track_type <- AIRail.RAILTYPE_INVALID; ///< Vehicle track type
	}

	/**
	 * @return this class name
	 */
	function GetClassName() { return "Infrastructure"; }

	/**
	 * @return tile location of this object
	 * @note must be overriden on vehicle by API
	 */
	function GetLocation() { return this._storage._location; }

	/**
	 * Set location of this object
	 */
	function SetLocation(val) { this._storage._location = val; }

	/**
	 * Get Vehicle type, sub type and track will used
	 */
	function GetV_Type() {return this._storage._type; }
	function GetV_SubType() { return this._storage._sub_type; }
	function GetV_TrackType() {return this._storage._track_type; }

	/**
	 * Set Transport vehicle type, sub type and track will used
	 */
	function SetTransportType(type, sub_type, track_type)
	{
		this._storage._type = type;
		this._storage._sub_type = sub_type;
		this._storage._track_type = track_type;
	}
}

/**
 * Station object
 */
class Station extends Infrastructure
{
	constructor()
	{
		::Infrastructure.constructor();
		this._storage._width <- -1; ///< Station width
		this._storage._length <- -1; ///< Station length
		this._storage._direction <- -1; ///< Station direction
		this._storage._area <- []; ///< Array of tile area in use
		this._storage._path_entry <- []; ///< Array of path entry
		this._storage._path_exit <- []; ///< Array of path exit
		this._storage._is_drop_station <- false; ///< Flag a drop off point
	}

	function GetClassName() { return "Station"; }

	/**
	 * Creates a list of vehicles that have orders to this station.
	 */
	function GetVehicleList() { return AIVehicleList_Station(this._id); }

	/**
	 * @return true if has one of AIStation::StationType
	 * Type of stations known in the game.
	 * STATION_TRAIN Train station.
	 * STATION_TRUCK_STOP Truck station.
	 * STATION_BUS_STOP Bus station.
	 * STATION_AIRPORT Airport.
	 * STATION_DOCK Dock.
	 * STATION_ANY All station types.
	 */
	function HasStationType(val) { return AIStation.HasStationType(this._id, val); }

	/**
	 * See how much cargo there is waiting on a station.
	 */
	function GetCargoWaiting (cargo_id) { return AIStation.GetCargoWaiting( this._id, cargo_id); }

	/**
	 * See how high the rating is of a cargo on a station.
	 */
	function GetCargoRating (cargo_id) { return AIStation.GetCargoRating(this._id, cargo_id); }

	/**
	 * Get the manhattan distance from the tile to the AIStation::GetLocation() of the station.
	 */
	function GetDistanceManhattanToTile(tile) { return AIStation.GetDistanceManhattanToTile(this._id, tile); }

	/**
	 * Check if can build distant/join/adjacent/nonuniform station
	 * actually I'm still confuse with this term
	 */
	function CanBuildJoint()
	{
		return Settings.Get(Settings.game.join_stations) || Settings.Get(Settings.game.adjacent_stations) ||
		Settings.Get(Settings.game.distant_join_stations);
	}

	function GetLength() {return this._storage._length;}
	function GetWidth() {return this._storage._width;}
	function GetDirection() {return this._storage._direction;}
	function SetLength(val) {this._storage._length = val;}
	function SetWidth(val) {this._storage._width = val;}
	function SetDirection(val) {this._storage._direction = val;}
	function GetArea() { return this._storage._area; }
	function SetArea(val) { this._storage._area = val; }
	function IsDropOff() { return this._storage._is_drop_station; }
	function SetDropOff(val) { this._storage._is_drop_station = val; }
}
/**
 * Road Station class
 */
class RoadStation extends Station
{
	constructor()
	{
		::Station.constructor();
		this.SetTransportType(AIVehicle.VT_ROAD, null, AIRoad.ROADTYPE_ROAD);
	}

	function GetClassName() { return "RoadStation"; }

	/**
	 * @return true if can build DTRS
	 */
	function CanBuildDTRS() {
		return Settings.Get(Const.dtrs_on_town) || Settings.Get(Const.dtrs_on_competitor);
	}
}

class RailStation extends Station
{
	constructor()
	{
		::Station.constructor();
	}

	function GetClassName() { return "RailStation"; }
}

class AirStation extends Station
{
	constructor()
	{
		::Station.constructor();
	}

	function GetClassName() { return "AirStation"; }

}

class WaterStation extends Station
{
	constructor()
	{
		::Station.constructor();
	}

	function GetClassName() { return "WaterStation"; }
}

class TramStation extends RoadStation
{
	constructor()
	{
		::RoadStation.constructor();
		::RoadStation.SetTransportType(AIVehicle.VT_ROAD, null, AIRoad.ROADTYPE_TRAM);
	}

	function GetClassName() { return "TramStation"; }
}

/**
 * Depot object
 */
class Depot extends Infrastructure
{
	constructor()
	{
		::Infrastructure.constructor();
	}

	function GetClassName() { return "Depot"; }
}

/**
 * Vehicle object
 */
class Vehicle extends Infrastructure
{
	constructor()
	{
		::Infrastructure.constructor();
	}

	function GetClassName() { return "Vehicle"; }
}

/**
 * Track object
 */
class Track extends Infrastructure
{
	/**
	 * Path finder used
	 */
	 _pathfinder = null;
	 
	constructor()
	{
		::Infrastructure.constructor();
		this._pathfinder = null;
	}

	function GetClassName() { return "Track"; }
}

/**
 * Road Track object
 */
class RoadTrack extends Track
{
	constructor()
	{
		::Track.constructor();
		this._pathfinder = RoadPF();
	}

	function GetClassName() { return "Road" + ::Track.GetClassName(); }
}

/**
 * Tram Track object
 */
class TramTrack extends RoadTrack
{
	constructor()
	{
		::RoadTrack.constructor();
	}

	function GetClassName() { return "Tram" + ::Track.GetClassName(); }
}
