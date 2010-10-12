/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Base Memory Class
 * A class for store a thing
 * @note Not recomended to extends this class
 */
class Memory extends Base
{
	_storage = null;

	constructor(name) {
		::Base.constructor(name);
		_storage = {};
	}

	/**
	 * Get this class storage
	 * @return current storage table
	 */
	function GetStorage() { return _storage; }

	/**
	 * Set class storage
	 * @param val table to set into class
	 */
	function SetStorage(val) { _storage = val; }

	/**
	 * internal _get method
	 * @param idx index of table to get
	 * @return value of index
	 */
	function _get(idx) {
		if (idx == null) return;
		if (idx in this) return this[idx];
		if (idx in _storage) return _storage[idx];
		Warn("not found index:", idx);
		if (idx in My.Root) return My.Root[idx];
		Warn("not found index:", idx , " in My Root");
	}

	/**
	 * internal _set method
	 * @param idx index of table to set
	 * @param val Value to set
	 * @note Don't try to save class or instance
	 */
	function _set(idx, val) {
		_storage.rawset(idx, val);
	}

	function _delslot(idx) {
		if (idx in _storage) return delete _storage[idx];
	}

	/**
	 * Make a class of Memory()
	 * @param storage Table of class storage
	 * @return class instance of Memory()
	 */
	function MakeClass(storage) {
		if (typeof storage != "table") throw "storage must be table";
		local c = Memory("null");
		c.SetStorage(storage);
		return c;
	}
}
