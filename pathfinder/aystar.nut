/*  09.06.16 - aystar.nut
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
 * extending official Aystar 6
 */
 class T_AyStar extends AyStar_6
 {
 	_ignored_tile_list = null;
 	
 	/**
 	 * Aystar constructor
 	 *
	 * @param pf_instance An instance that'll be used as 'this' for all
	 *  the callback functions.
	 * @param cost_callback A function that returns the cost of a path. It
	 *  should accept four parameters, old_path, new_tile, new_direction and
	 *  cost_callback_param. old_path is an instance of AyStar.Path, and
	 *  new_node is the new node that is added to that path. It should return
	 *  the cost of the path including new_node.
	 * @param estimate_callback A function that returns an estimate from a node
	 *  to the goal node. It should accept four parameters, tile, direction,
	 *  goal_nodes and estimate_callback_param. It should return an estimate to
	 *  the cost from the lowest cost between node and any node out of goal_nodes.
	 *  Note that this estimate is not allowed to be higher than the real cost
	 *  between node and any of goal_nodes. A lower value is fine, however the
	 *  closer it is to the real value, the better the performance.
	 * @param neighbours_callback A function that returns all neighbouring nodes
	 *  from a given node. It should accept three parameters, current_path, node
	 *  and neighbours_callback_param. It should return an array containing all
	 *  neighbouring nodes, which are an array in the form [tile, direction].
	 * @param check_direction_callback A function that returns either false or
	 *  true. It should accept four parameters, tile, existing_direction,
	 *  new_direction and check_direction_callback_param. It should check
	 *  if both directions can go together on a single tile.
	 */
	constructor(pf_instance, cost_callback, estimate_callback, neighbours_callback, check_direction_callback)
	{		
 		::AyStar_6.constructor(pf_instance, cost_callback, estimate_callback, neighbours_callback, check_direction_callback);
 		this._queue_class = FibonacciHeap;
 		this._ignored_tile_list = AITileList(); 		
 	}
 	
 	/**
 	 * Get ignored tile list on pathfinding
 	 * @return AITileList of ignored tiles
 	 */
 	function GetIgnoredTileList()
 	{
 		this.MergeList();
 		return this._ignored_tile_list; 
 	}
 
 	function MergeList()
	{
		if (this._closed) {
 			local c = this._closed;
 			c.KeepValue(0);
 			this._ignored_tile_list.AddList(c); 			
 		}
	}
	
	function GetCurrentPath()
	{
		return this._open.Peek();
	}
	
 	function _CleanPath()
	{
		this.MergeList();
		::AyStar_6._CleanPath();
	}
 }
