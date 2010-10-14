/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Task management
 */
class TaskManager
{
	static queue = [];

	/**
	 * Insert new task into scheduler
	 * @param task Class of TaskItem to insert
	 */
	function New(task) {
		if (task instanceof DailyTask) {
			TaskManager.queue.insert(0, task);
		} else {
			throw "need an instance of DailyTask";
		}
	}

	/**
	 * Run the scheduler
	 * execute scheduled task by tick
	 */
	function Run() {
		if (TaskManager.queue.len()) {
			local task = TaskManager.queue.pop();
			if (!task.TryToStart()) {
				TaskManager.New(task);
				return;
			}
			if (!task.IsRemovable()) TaskManager.New(task);
		}
	}
}

