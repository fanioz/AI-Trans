/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2019 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

class ListSorter
{
	data = null;
	key = null;
	
	constructor() {
		data = {};
		key = CLList();
		key.SortValueAscending();
	}
	
	function Insert(item, priority) {
		data[item.GetID()] <- item;
		key.AddItem(item.GetID(), priority.tointeger());
	}
	
	function Peek() {
		return data[key.Begin()];
	}
	
	function Pop() {
		local d = key.Pop();
		return delete data[d];
	}
	
	function Count() {
		return data.len();
	}
}

