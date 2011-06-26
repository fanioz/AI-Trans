/*
	This file is part of AI Library - List
	Copyright (C) 2009-2010  OpenTTD NoAI Community
	
	AI Library - List is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public
	License as published by the Free Software Foundation; either
	version 2.0 of the License, or (at your option) any later version.
	
	AI Library - List is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.
	
	You should have received a copy of the GNU General Public
	License along with AI Library - List; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

/**
 * Valuator libraries
 */
class CLList extends AIList
{
	_lib_class = CLCommon;

	/**
	 * List constructor
	 * @param list optional AIList to copy
	 */
	constructor(list = null)
	{
		::AIList.constructor();
		if (list != null) {
			assert(list instanceof AIList);
			this.AddList(list);
		}
	}
}

/**
 * Valuator function for functions that change the game state and as such
 * are nore allowed as function for AIAbstarctList::Valuate.
 * @param valuator Function to be used as valuator
 * @param ... Additional argument to be passed to the valuator
 */
function CLList::DoValuate(valuator, ...)
{
	assert(typeof valuator == "function");

	local args = [null, null];
	for (local c = 0; c < vargc; c++) args.push(vargv[c]);
	/* If values are changed while iterating over the list then some items
	 * might be skipped. Prevent this by caching all new values and applying
	 * them after iterating over all items. */
	local new_values = AIList();
	foreach (idx, val in this) {
		args[1] = idx;
		local value = this._lib_class.ACall(valuator, args);
		if (typeof value == "bool") value = value ? 1 : 0;
		new_values.AddItem(idx, value);
	}
	this.KeepTop(0);
	this.AddList(new_values);
}

/**
 * Set the value of all items to the item.
 */
function CLList::SetValueAsItem()
{
	/* We should never change a value while iterating over the list so create
	 * a copy first so we can iterate over the copy. */
	local copy = AIList();
	copy.AddList(this);
	foreach (idx, val in copy) this.SetValue(idx, idx);
}

/**
 * Get all of items as an array.
 * @return An array with all items in it.
 */
function CLList::GetItemArray()
{
	local ar = [];
	foreach (idx, val in this) {
		ar.push(idx);
	}
	return ar;
}

/**
 * Get all of values as an array.
 * @return An array with all values in it.
 */
function CLList::GetItemArray()
{
	local ar = [];
	foreach (idx, val in this) {
		ar.push(val);
	}
	return ar;
}

/**
 * Add items of AIList from array  All the new items
 * are added with value 0.
 */
function CLList::AddItems(an_array)
{
	foreach (item in an_array) { 
		this.AddItem(item, 0);
	}
}

/**
 * Get all of data as an array with [item, value]-pairs.
 * @return An array with all data.
 */
function CLList::GetItemValue()
{
	local ar = [];
	foreach (idx, val in this) {
		ar.push([idx, val]);
	}
	return ar;
}

/**
 * Add all [item, value]-pairs from a given array to this list.
 * @param an_array Array of same function returned by GetItemValue()
 */
function CLList::AddItemValue(an_array)
{
	foreach (pair in an_array) {
		assert(typeof pair == "array");
		assert(pair.len() == 2);
		this.AddItem(pair[0], pair[1]);
	}
}

/**
 * Sort by item, ascending.
 */
function CLList::SortItemAscending()
{ 
	this.Sort(AIList.SORT_BY_ITEM, AIList.SORT_ASCENDING); 
}

/**
 * Sort by item, descending.
 */
function CLList::SortItemDescending()
{
	this.Sort(AIList.SORT_BY_ITEM, AIList.SORT_DESCENDING);
}

/**
 * Sort by value, ascending.
 */
function CLList::SortValueAscending()
{
	this.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
}

/**
 * Sort by value, descending.
 */
function CLList::SortValueDescending() {
	this.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
}

/* From AITile List */
/**
 * Add a tile to the to-be-evaluated tiles.
 * @param tile The tile to add.
 * @pre AIMap::IsValidTile(tile).
 */
function CLList::AddTile(tile)
{
	if (AIMap.IsValidTile(tile)) this.AddItem(tile, 0);
}

/**
 * Remove a tile to the to-be-evaluated tiles.
 * @param tile The tile to remove.
 * @pre AIMap::IsValidTile(tile).
 */
function CLList::RemoveTile(tile)
{
	if (AIMap.IsValidTile(tile)) this.RemoveItem(tile);
}

/**
 * Adds the rectangle between t1 and t2 to the list.
 * @param tile_from One corner of the tiles to add.
 * @param tile_to The other corner of the tiles to add.
 * @pre AIMap::IsValidTile(tile_from).
 * @pre AIMap::IsValidTile(tile_to).
 */
function CLList::AddRectangle(tile_from, tile_to)
{
	local tmp = AITileList();
	tmp.AddRectangle(tile_from, tile_to);
	this.AddList(tmp);
}

/**
 * Remove the rectangle between t1 and t2 from the list.
 * @param t1 One corner of the tiles to remove.
 * @param t2  The other corner of the tiles to remove.
 */
function CLList::RemoveRectangle(tile_from, tile_to)
{
	local tmp = AITileList();
	tmp.AddRectangle(tile_from, tile_to);
	this.RemoveList(tmp);
}

/* Queue mode */

/**
 * Get the topmost item from the list
 * @pre !IsEmpty()
 * @return the topmost item of the list
 */
function CLList::Peek()
{
	assert(!this.IsEmpty());
	return this.Begin();
}

/**
 * Remove the topmost item from the list and return it.
 * @pre !IsEmpty()
 * @return the topmost item of the list
 */
function CLList::Pop()
{
	assert(!this.IsEmpty());
	local ret = this.Begin();
	this.RemoveItem(ret);
	return ret;
}

/**
 * Add an item to the list
 */
function CLList::Push(idx) {
	this.AddItem(idx, 0);
}

/* Preview Mode */

/**
 * Pre-count items left if Removes all items with a value above start and below end.
 * @param start  the lower bound of the to be removed values (exclusive).
 * @param end  the upper bound of the to be removed valuens (exclusive).
 * @return count of left item.
 */
function CLList::CountIfRemoveBetweenValue(start, end)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.RemoveBetweenValue(start, end);
	return tmp.Count();
}

/**
 * Pre-count items left if Removes all items with a higher value than 'val'.
 * @param val the value above which all items are removed.
 * @return count of left item.
 */
function CLList::CountIfRemoveAboveValue(val)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.RemoveAboveValue(val);
	return tmp.Count();
}

/**
 * Pre-count items left if Removes all items with a lower value than 'val'.
 * @param val the value below which all items are removed.
 * @return count of left item.
 */
function CLList::CountIfRemoveBelowValue(val)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.RemoveBelowValue(val);
	return tmp.Count();
}

/**
 * Pre-count items left if Remove all items with this value.
 * @param val the value to remove.
 * @return count of left item.
 */
function CLList::CountIfRemoveValue(val)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.RemoveValue(val);
	return tmp.Count();
}

/**
 * Pre-count items left if Keep all items with this value.
 * @param val the value to keep.
 * @return count of left item.
 */
function CLList::CountIfKeepValue(val)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.KeepValue(val);
	return tmp.Count();
}

/**
 * Pre-count items left if Remove n items from top.
 * @param n the number of item to remove from top.
 * @return count of left item.
 */
function CLList::CountIfRemoveTop(n)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.RemoveTop(n);
	return tmp.Count();
}

/**
 * Pre-count items left if Remove n items from bottom.
 * @param n the number of item to remove from bottom.
 * @return count of left item.
 */
function CLList::CountIfRemoveBottom(n)
{
	local tmp = AIList();
	tmp.AddList(this);
	tmp.RemoveBottom(n);
	return tmp.Count();
}


/**
 * Check if there is an element left.
 * Make sure the compatibility with both API 1.0 / 1.1
 * @return true if no element left
 * @note this would be a kind of .... preprocessor :D
 */

/* check with 1.1 API first */
if(AIList.rawin("IsEnd")) {
	
	if(!AIList.rawin("HasNext")) {
		CLList.HasNext <- function() return !IsEnd();
	}
	
} else {
	/* we are on 1.0 or its API layer */
	CLList.IsEnd <- function() return !HasNext();
}
