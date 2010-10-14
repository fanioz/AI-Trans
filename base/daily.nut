/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Fake Task Namespace
 */
class Task {}

/**
 * Daily task
 */
class DailyTask extends Base
{
	_removable = true;
	_result = null;
	_key = null;
	_next_date = null;
	
	constructor(name, key) {
		::Base.constructor(name);
		_key = key;
		SetRemovable(false);
	}

	/**
	 * Get remove-ability of this task
	 * @return true if can remove after executing
	 */
	function IsRemovable() { return _removable; }

	/**
	 * Set remove-ability of this task
	 * @param val Set true if can remove after executing
	 */
	function SetRemovable(val) { _removable = val; }

	/**
	 * Actually execute this task
	 * @note to be overriden by class descendants
	 * @return null if not execute anything
	 */
	function On_Start() { throw "not implemented"; }

	/**
	 * Try executing task.
	 * If time is match will execute On_Start() methode.
	 * @return true if time to execute task
	 */
	function TryToStart() {
		local now = AIDate.GetCurrentDate();
		if (_next_date < now) {
			_next_date = now + _key;
			Warn(":..");
			On_Start();
			return true;
		}
		return false;
	}
	
	/**
	 * Execute this task on load
	 * @note to be overriden by class descendants
	 */
	function On_Load();

	/**
	 * Execute this task on save
	 * @note to be overriden by class descendants
	 */
	function On_Save();
}
