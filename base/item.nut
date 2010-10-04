/*  10.02.27 - item.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Fake Task Namespace
 */
class Task {}

/**
 * Task item is base for all task item
 */
class TaskItem extends CIDLocation
{
	_removable = true;
	_result = null;
	_key = -1;
	constructor (name, id) {
		::CIDLocation.constructor (id, 0);
		SetName (name);
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
	function SetRemovable (val) { _removable = val; }

	/**
	 * Get result of this task
	 * @return any result
	 */
	function GetResult() { return _result; }

	/**
	 * Set result of this task
	 * @param val set the result of task
	 */
	function SetResult (val) { _result = val; }

	/**
	 * Actually execute this task
	 * @note to be overriden by class descendants
	 * @return null if not execute anything
	 */
	function On_Start() {
		throw "not implemented";
	}

	function GetKey() { return _key; }
	function SetKey (key) { _key = key; }

	/**
	 * Try executing task.
	 * If time is match will execute On_Start() methode.
	 * @return true if time to execute task
	 */
	function TryToStart () {
		Info (":..");
		On_Start();
		return true;
	}
}

