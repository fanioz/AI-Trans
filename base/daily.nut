/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Daily task
 */
class DailyTask extends TaskItem
{
	_next_date = 0;
	constructor(name, id) {
		::TaskItem.constructor(name, id);
		SetRemovable(false);
	}

	/**
	 * Try executing task. (overriden)
	 * If time is match will execute On_Start() methode.
	 * @param tick at what tick now ?
	 * @return true if time to execute task
	 */
	function TryToStart() {
		local now = AIDate.GetCurrentDate();
		if (_next_date < now) {
			_next_date = now + GetKey();
			return TaskItem.TryToStart();
		}
		return false;
	}
}


