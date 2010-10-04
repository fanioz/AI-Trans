/*  09.05.22 - task.nut
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
 * Task management
 */
class TaskManager extends Manager
{
	/** local  ticker */
	tick =  null;
	/** local  ticker */
	_sleep_time = null;
	
	/**
	 * class constructor
	 */
	constructor()
	{
		::Manager.constructor("Task");
		this.tick = 0;
		this._sleep_time = 10;
	}

	/**
	 * Insert new task into scheduler
	 * @param task Class of TaskItem to insert
	 * @param looper In what tick will executed
	 * @return the ID of this task in scheduler
	 */
	function New(task)
	{		
		if (task instanceof TaskItem) {			
			local c = this.FindByName(task.GetClassName());
			if (c) {
				this.ChangeItem(c, task);
			} else {
				c = this.FindNewID();
				this.AddItem(c, task);
			}
			return c;
		}
		throw "need an instance of TaskItem"; 
	}

	/**
	 * Set Sleep time for each iteration
	 * @param time Time in tick to sleep
	 */
	function SetSleep(time)
	{
		this._sleep_time = time;
	}

	/**
	 * Run the scheduler
	 * execute scheduled task by tick
	 */
	function Run () {
		if (this.Count()) {
			local task = null;
			this.SortValueAscending();
			for (local i= this.list.Begin(); this.list.HasNext(); i = this.list.Next()) {
				AIController.Sleep(this._sleep_time);				
				task = this.Item(i).weakref();
				if (task.ref().TryExecute(this.tick)) {
					if (task.ref().IsRemovable()) this.RemoveItem(i);
				}
			}
			this.tick ++;
			if (this.tick == 0xFFFF) this.tick = 0;
		}		
	}

	/**
	 * Find a task by matching its name *
	 * @param name Name of task
	 * @return the ID of this task in scheduler or null if not found
	 */
	function FindByName(name)
	{
		foreach (idx, val in this.list) if (this.Item(idx).GetClassName() == name) return idx;
	}
}
