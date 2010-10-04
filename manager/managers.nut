/*  09.05.03 - managers.nut
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
 * Manager is base class for management / group / list of storable objects
 */
class Manager extends KeyLists
{
	constructor(name) {
		::KeyLists.constructor(name);
	}

	/**
	 * Get the class name (overriden)
	 * @return this class name
	 */
	function GetClassName() { return this._storage._name + "Manager"; }
	
	/**
	 * Get available ID
	 * @return available ID number
	 */
	function FindNewID()
	{
		local c = 1;
        while (this.list.HasItem(c)) c++;
        return c;
	}
}

class StationManager extends Manager
{
	constructor() {
		::Manager.constructor("Station");
	}
	
	/**
	 * Insert new station item
	 * @param st_class Class of Station
	 * @return a valid ID of servable class
	 */
	function New(st_class)
	{
		assert(st_class instanceof Station);
        local c = st_class.GetLocation();
        local i = Memory("station")
        foreach (idx, val in st_class.GetStorage())
        {
        	i.idx = val;
        }
        this.AddItem(c, i.GetStorage());
        return c;
	}
	
	/**
	 * Pop class of station from storage
	 * @param idx Index of station in manager
	 * @return class of station and remove it from manager 
	 */
	 function PopClass(idx)
	 {
	 	local the_class = null;
	 	local the_storage = this.Item(idx);
	 	if (the_storage == null) return;
	 	this.RemoveItem(idx);
	 	switch (the_storage._name) {
	 		case "RailStation" : the_class = RailStation; break;
	 		case "RoadStation" : the_class = RoadStation; break;
	 		default : Debug.DontCallMe("not registered yet", the_storage._name);  
	 	}
	 	the_class.SetStorage(the_storage);
	 	return the_class;
	 }
}

class VehicleManager extends Manager
{
	constructor() {
		::Manager.constructor("Vehicle");
	}
}

class ServiceManager extends Manager
{
	constructor() {
		::Manager.constructor("Service");
	}

	/**
	 * Insert new service item
	 * @param serv Class of service
	 * @param priority Priority of service
	 * @return a valid ID of servable class
	 */
	function New(serv, priority)
	{
		assert(serv instanceof Services);
        local c = ::Manager.FindNewID();
        serv.Info.ID = c;
        this.Insert(c, priority, serv);
        return c;
	}

	/**
	 * Find an ID using key of service
	 * @param key Key to find
	 * @return a valid ID or null if not found
	 */
	function FindKey(key)
	{
		foreach (idx, val in this.list) if (this.Item(idx).Info.Key == key) return idx;
	}
}