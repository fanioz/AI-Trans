/*  09.06.09 - task.nut
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
 * Fake Task Namespace
 */
class Task {}

/**
 * Task item is base for all task item
 */
class TaskItem extends StorableKey
{
	constructor(name)
	{
		::StorableKey.constructor(name);		
		this._storage._removable <- true;
		this._storage._result <- null;
	}
	
	/**
     * Get remove-ability of this task
     * @return true if can remove after executing
     */
    function IsRemovable() { return this._storage._removable; }
    
    /**
     * Set remove-ability of this task
     * @param val Set true if can remove after executing
     */
    function SetRemovable(val) { this._storage._removable = val; }

	/**
     * Get result of this task
     * @return any result
     */
    function GetResult() { return this._storage._result; }
    
    /**
     * Set result of this task
     * @param val set the result of task
     */
    function SetResult(val) { this._storage._result = val; }
    
    /**
     * Try executing task.
     * If time is match will execute Execute() methode.
     * @param tick at what tick now ?
     * @return true if time to execute task
     */
    function TryExecute(tick)
    {
    	local can_do = (tick % ::StorableKey.GetKey() == 0);
    	if (can_do) {
    		this.Execute();
    	}
    	return can_do;
    }
    
    /**
	 * Actually execute this task
	 * @note to be overriden by class descendants
	 * @return null if not execute anything
	 */
	function Execute()
	{
		AILog.Warning("Executing " + ::StorableKey.GetClassName());
	}

}

/**
 * Task that is using yield from generator
*/
class YieldTask extends TaskItem
{
	constructor(name)
	{
		::TaskItem.constructor(name);
		::TaskItem.SetRemovable(false);
		///last yield holder
		this._storage._yield <- "new";
		/// flag to repeat generator
		this._storage._repeat <- true;
	}

	function Execute()
	{
		::TaskItem.Execute();
		if (this._storage._yield == "new") this._storage._yield = this._exec();
		try {
			if (typeof(this._storage._yield) == "generator") {
				if (this._storage._yield.getstatus() == "suspended") {
					this.SetResult(resume this._storage._yield);
					return this.GetResult();
				}
			}
		} catch (x) {
			if (x != "resuming dead generator") throw x;
			AILog.Warning("Expected error. Don't worry");
		}
		/* detect repeatesion */
		AILog.Info("Generator stopped");
		if (this.IsRepeat()) {
			AILog.Info("Rebuild yield");
			this._storage._yield = "new";
			return true;
		}
		this._storage._yield = null;
		this.SetResult("YT_stop");
		::TaskItem.SetRemovable(true);
	}
	
	/**
     * Get repeat of this task
     * @return true if must repeat
     */
    function IsRepeat() { return this._storage._repeat; }
    
    /**
     * Set repeat of this task
     * @param val set true to repeat
     */
    function SetRepeat(val) { this._storage._repeat = val; }
    
	function _exec()
	{
		AILog.Warning("Executing Yield " + ::TaskItem.GetClassName());
	}
}

/**
 * Daily task
 */
class DailyTask extends TaskItem
{
	constructor(name)
	{
		::TaskItem.constructor(name);
		this._storage._lastdate <- AIDate.GetCurrentDate();
	}
	
	/**
     * Try executing task. (overriden)
     * If time is match will execute Execute() methode.
     * @param tick at what tick now ?
     * @return true if time to execute task
     */
    function TryExecute(tick)
    {
    	local now = AIDate.GetCurrentDate();
    	local target = ::TaskItem.GetKey() + this._storage._lastdate;
    	local can_do = (target < now);
    	if (can_do) {
    		this.Execute();
    		this._storage._lastdate = now;
    	}
    	return can_do;
    }	
}
