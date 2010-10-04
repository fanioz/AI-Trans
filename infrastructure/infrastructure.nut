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
	constructor(name) {
		::Storable.constructor(name);
		this._storage._location <- -1; ///< Top location of this object
		this._storage._type <- AIVehicle.VT_INVALID; ///< Vehicle Type
	}

	/**
	 * Get Location
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

	/**
	 * Set Transport vehicle type, sub type and track will used
	 */
	function SetV_Type(type) { this._storage._type = type; }
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

/**
 * Depot Object
 */
class Depot extends Infrastructure
{
	constructor(body, head)
	{
		::Infrastructure.constructor("Depot");
        this._storage._head <- head;
        this.SetLocation(body);
	}
    function GetHead() { return this._storage._head; }
}