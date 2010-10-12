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
	static ids = AIList();
	static queue = [];

	/**
	 * Insert new task into scheduler
	 * @param task Class of TaskItem to insert
	 */
	function New(task) {
		if (task instanceof TaskItem) {
			local id = task.GetID();
			if (!TaskManager.ids.HasItem(id)) {
				TaskManager.ids.AddItem(id, task.GetKey());
				TaskManager.queue.insert(0, task);
				return;
			}
			local c = 100;
			while (TaskManager.ids.HasItem(c)) c--;
			throw "Task " + task.GetName() + " already exist for ID " + id + " use " + c;
		}
		throw "need an instance of TaskItem";
	}

	/**
	 * Run the scheduler
	 * execute scheduled task by tick
	 */
	function Run() {
		if (TaskManager.queue.len()) {
			local task = TaskManager.queue.pop();
			TaskManager.ids.RemoveItem(task.GetID());
			if (!task.TryToStart()) {
				TaskManager.New(task);
				return;
			}
			if (!task.IsRemovable()) TaskManager.New(task);
		}
	}
}

