/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that have ID and location
 */
class CIDLocation extends Base
{
	_id = -1;
	_location = -1;

	constructor(id, loc) {
		::Base.constructor("anonymous");
		SetID(id);
		SetLocation(loc);
	}

	function GetID() { return _id; }
	function SetID(id) { _id = id; }
	function GetLocation() { return _location; }
	function SetLocation(loc) { _location = loc; }
}
