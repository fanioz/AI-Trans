/*  09.06.19 - servable.nut
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
  * Base Serv-able class for store either town or industry handling in game
  */
class Servable extends StorableKey
{
	_API = null; ///< common API function to be used by this class
	constructor()
	{
		::StorableKey.constructor("servable");
		/// Flag of town
		this._storage._istown <- null;
		/// cache area
		this._storage._area <- []; 
		this._API = function(){};
	}

	/**
	 * Get the name of servable object
	 * @return string name
	 */
	function GetName() { return this._API.GetName(this.GetID()); }

	/**
	 * Get type of servable object
	 * @return true if Town or  false if Industry
	 */
	function IsTown() { return this._storage._istown; }
	
	/**
	 * Set current servable object as Town/Industry
	 * @param val True for town and false for industry
	 */
	function SetTown(val)
	{
		this._storage._istown = val;
		this._API = val ? AITown : AIIndustry;
	}    

	/**
	 * Get Base Area
	 * @return AITileList around servable
	 */
	function GetArea()
	{
		if (this._storage._area.len()) return Assist.ArrayToList(this._storage._area);
		local area = null;
		if (this.IsTown()) {
			area = Tiles.OfTown(this.GetID(), Tiles.Radius(this.GetLocation(), 20, 20) , 1);
		} else {    		
			area = AITileList_IndustryProducing(this.GetID(), 10);
			if (area.IsEmpty()) area = AITileList_IndustryAccepting(this.GetID(), 10);
		}
		this._storage._area = Assist.ListToArray(area);
		return area;
	}
    
	/**
	 * Get the location of servable object
	 * @return tile index of location
	 */
	function GetLocation() { return this._API.GetLocation(this.GetID()); }
	
	/**
	 * Get the total last month's production of the given cargo.
	 * @param cargo_id  The index of the cargo.
	 * @return The last month's production of the given cargo
	 */
	function GetLastMonthProduction(cargo_id)
	{
		if (!AICargo.IsValidCargo(cargo_id)) return 0;
		if (this.IsTown()) return AITown.GetMaxProduction(this.GetID(), cargo_id);
		return this._API.GetLastMonthProduction(this.GetID(), cargo_id);
	}

	/**
	 * Get the total amount of cargo transported  last month.
	 * @param cargo_id  The index of the cargo.
	 * @return The percentage amount of given cargo transported last month.
	 */
	function GetLastMonthTransported(cargo_id)
	{
		if (!AICargo.IsValidCargo(cargo_id)) return 0;
		local p = this.GetLastMonthProduction(cargo_id);
		if (p) {
			local t = this._API.GetLastMonthTransported(this.GetID(), cargo_id);
			return (100 * t / p).tointeger();
		}
		return 0;
	}

	/**
	 * Get the manhattan distance from the tile
	 * @param tile  The tile to get the distance to.
	 * @return The distance between this object and tile.
	 */
	function GetDistanceManhattanToTile(tile)
	{
		return this._API.GetDistanceManhattanToTile(this.GetID(), tile);
	}

	/**
	 * Just make sure it was valid
	 * @return true if it was valid
	 */
	function IsValid()
	{
		return this.IsTown() ? AITown.IsValidTown(this.GetID()) : AIIndustry.IsValidIndustry(this.GetID());
	}

	/**
	 * New Servable Town
	 * @param id Servable ID
	 * @return Servable class
	 */
	static function NewTown(id)
	{
		local tmp = Servable();
		tmp.SetID(id);
		tmp.SetTown(true);
		local loc = tmp.GetLocation();
		tmp.SetKey(loc);        
		return tmp;
	}

	/**
	 * New Servable Industry
	 * @param id Servable ID
	 * @return Servable class
	 */
	static function NewIndustry(id)
	{
		local tmp = Servable();
		tmp.SetID(id);
		tmp.SetTown(false);        
		local loc = tmp.GetLocation();
		tmp.SetKey(loc);
		return tmp;
	}

	/**
	 * New Unknown Servable
	 * @param id Servable ID
	 * @param istown Is this belong to town
	 * @return Servable class
	 */
	static function New(id, istown)
	{
		if (istown) return Servable.NewTown(id);
		return Servable.NewIndustry(id);
	}    
}
