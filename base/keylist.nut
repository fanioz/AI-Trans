/*  09.06.10 - keylist.nut
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
  * Base class for collection of storable objects
  */
class KeyLists extends Storage
{
	/** Internal List */
	list = null;

	constructor(name) {
		::Storage.constructor(name);
		this.list = AIList();
	}

	/**
	 * Count of list
	 * @return Count of storable item has
	 */
	function Count() {return this.list.Count(); }

	/**
	 * Add Item and it storage to list
	 * @param item ID of item
	 * @param storage of item
	 */
	function AddItem(item, storage)
	{
		this.list.AddItem(item, 0);
		this._storage.rawset(item, storage);
	}

	/**
	 * Change Item and it storage already in the list
	 * @param item ID of item
	 * @param storage of item
	 */
	function ChangeItem(item, storage)
	{
		this._storage.rawset(item, storage);
	}

	/**
	 * Remove Item and it storage in the list
	 * @param item ID of item
	 */
	function RemoveItem(item)
	{
		this.ChangeItem(item, null);
		this._storage.rawdelete(item);
		this.list.RemoveItem(item);
	}

	/**
	 * Find an Item in the list
	 * @param item ID of item
	 * @return true if found
	 */
	function HasItem(item)
	{
		return this.list.HasItem(item) && this._storage.rawin(item);
	}

	/**
	 * Completely clear the list
	 */
	function Clear()
	{
		foreach (idx, val in this.list) this.RemoveItem(idx);
	}

	/**
	 * Set value of Item (for sorting)
	 * @param item ID
	 * @param value of item
	 */
	function SetValue(item, value) { return this.list.SetValue(item, value); }

	/**
	 * Get value of Item (for sorting)
	 * @param item ID
	 * @param value of item
	 */
	function GetValue(item) { return this.list.GetValue(item); }

	/**
	 * Add Item, value and it storage to list
	 * @param item ID
	 * @param value of item
	 * @param storage of item
	 */
	function Insert(item, value, storage)
	{
		if (this.HasItem(item)) this.ChangeItem(item, storage);
		else this.AddItem(item, storage);
		this.SetValue(item, value);
	}

	/**
	 * Get the first storage and remove it
	 */
	function Pop()
	{
		local c = this.Peek();
		this.RemoveItem(this.list.Begin());
		return c;
	}

	/**
	 * Get the first storage without remove it
	 */
	function Peek()
	{
		return this.Item(this.list.Begin());
	}

	/**
	 * Get a storage from list
	 * @param item ID
	 * @return storage of item
	 */
	function Item(id) {
		if (id != null && this.HasItem(id)) return this._storage.rawget(id);		
	}

	/**
	 * Sort list ascending by it value
	 */
	function SortValueAscending()
	{
		this.list.Sort(AIAbstractList.SORT_BY_VALUE, true);
	}

	/**
	 * Sort list descending by it value
	 */
	function SortValueDescending()
	{
		this.list.Sort(AIAbstractList.SORT_BY_VALUE, false);
	}


	/**
	 * Clear list and rebuild using storage table
	 */
	function ResetList()
	{
		this.list.Clear();
		foreach (idx, val in this._storage) this.list.AddItem(idx , 0);
	}

	/**
	 * Set storage after load /// overriden
	 */
	function SetStorage(val)
	{
		::Storage.SetStorage(val);
		if (val) this.ResetList();
	}
}
