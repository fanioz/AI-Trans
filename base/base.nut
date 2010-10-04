/*  10.02.27 - Base.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Base all class that has name :D
 */
class Base
{
	_name = null;
	_silent = null;

	/**
	 * class constructor
	 * @param name Set name of the storage
	 */
	constructor(name)
	{
		_name = name;
		_silent = false;
	}
	/**
	 * Get the name of class
	 */
	function GetName()  { return _name; }
	/**
	 * Set the name of class. Which is used on log.
	 * @param val string of class name to set
	 */
	function SetName(val)  { _name = val; }
	/**
	 * Standard Debug.Info feature
	 */
	function Info(...)
	{
		if (_silent) return;
		local txt = ["[" + _name + "] "];
		for(local c = 0; c < vargc; c++) txt.push(vargv[c]);
		Debug.Say(txt, 1);
	}
	/**
	 * Standard Debug.Warning feature
	 */
	function Warn(...)
	{
		if (_silent) return;
		local txt = ["[" + _name + "] "];
		for(local c = 0; c < vargc; c++) txt.push(vargv[c]);
		Debug.Say(txt, 2);
	}
	/**
	 * Standard Debug.Warning feature
	 */
	function Error(...)
	{
		if (_silent) return;
		local txt = ["[" + _name + "] "];
		for(local c = 0; c < vargc; c++) txt.push(vargv[c]);
		Debug.Say(txt, 3);
	}
	function tostring() { return _name; }
}

