/*  09.05.24 - storage.nut
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
 * Base all class that has storage table
 */
class Storage
{
	/** Storage to support save/load */
	_storage = null;

	/**
	 * class constructor
	 * @param name Set name of the storage
	 */
	constructor(name)
	{
		this._storage = {};
		this._storage._name <- name; 
	}

	/**
	 * Get this class storage
	 * @return current storage table
	 */
	function GetStorage() { return this._storage; }

	/**
	 * Set class storage
	 * @param val table to set into class
	 */
	function SetStorage( val) { this._storage = val; }

	/**
	 * Get the storage name
	 * @return string of this storage name
	 */
	function GetClassName() { return this._storage._name; }
}

/**
 * Base Memory Class
 * A class for store a thing
 * @note Not recomended to extends this class
 */
class Memory extends Storage
{
	constructor(name) {
		::Storage.constructor(name);
	}

	/**
	 * internal _get method
	 * @param idx index of table to get
	 * @return value of index
	 */
	function _get(idx)
	{
		if (idx in this) return this[idx];
		if (idx in this._storage) return this._storage[idx];
		::print("not found in class storage");
		if (idx in ::TransAI.Root) return ::TransAI.Root[idx];
		::print("not found in TransAI Root");
		::print(idx);
	}

	/**
	 * internal _set method
	 * @param idx index of table to set
	 * @param val Value to set
	 * @note Don't try to save class or instance
	 */
	function _set(idx, val)
	{
		if((typeof val == "class") || (typeof val == "instance")) throw "using " + typeof val;
		this._storage.rawset(idx, val);
	}
	
	function _cmp(other)
	{
		assert(typeof(other) == "table");
		foreach (idx, val in this._storage) if (other[idx] != val) return 1;
		return 0;
	}
	
	/**
	 * Make a class of Memory()
	 * @param storage Table of class storage
	 * @return class instance of Memory()
	 */
	static function MakeClass(storage)
	{
		if (typeof storage != "table") throw "storage must be table";
		local c = Memory("null");
		c.SetStorage(storage);
		return c;
	}
}

/**
 * Storable is class that have 'Mem' as its storage
 * A base class for object that has an ID and storage
 */
class Storable extends Storage
{
	constructor(name) {
		::Storage.constructor(name);
		this._storage._id <- 0; //ID of this object
	}
	
	/**
	 * Get ID in storage
	 * @return class ID
	 */
	function GetID() { return this._storage._id; }
	
	/**
	 * Set ID in storage
	 * @param id class ID to set
	 */
	 function SetID(id) { this._storage._id = id; }
	
	/**
	 * Make a class of Storable()
	 * @param storage Table of class storage
	 * @return class instance of Storable()
	 */
	static function MakeClass(storage)
	{
		if (typeof storage != "table") throw "storage must be table";
		local c = Storable("null");
		c.SetStorage(storage);
		return c;
	}
}

/**
 * Base class of storable objects that has custom ID (key)
 */
class StorableKey extends Storable
{
	constructor(name) {
		::Storable.constructor(name);
		this._storage._key <- 0; // key of class
	}
	
	/**
	 * Get Key in storage
	 * @return class key
	 */
	function GetKey() { return this._storage._key; }
	
	/**
	 * Set Key in storage
	 * @param key class Key to set
	 */
	function SetKey(key) { this._storage._key = key; }
	 
	/**
	 * Make a class of StorableKey()
	 * @param storage Table of class storage
	 * @return class instance of StorableKey()
	 */
	static function MakeClass(storage)
	{
		if (typeof storage != "table") throw "storage must be table";
		local c = StorableKey("null");
		c.SetStorage(storage);
		return c;
	}
}
 