/*  09.12.22 - aystar.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * An AyStar implementation.
 * It solves graphs by finding the fastest route from one point to the other.
 * Should not instantiated directly, use the pathfinders instead.
 */
class AyStar extends Base
 {
	_max_len = null;				///< The maximum len expected.
	_open = null;					///< The list of open items sorted by cost.
	_closed = null;					///< The list of closed items.
	_goals = null;					///< The array of goals.
	_running = null;     			///< The state of pathfinder.
	_accountant = null;     		///< The AIAccounting instance.
	_max_bridge_length = null;		///< The maximum length of a bridge that will be build.
	_max_tunnel_length = null;		///< The maximum length of a tunnel that will be build.
 	
 	/**
	 * Aystar Constructor
	 * @param name Name of inheritance
	 */
	constructor(name)
	{		
		Base.constructor(name);
		_max_len = AIMap.GetMapSize();
		_accountant = AIAccounting();
		_max_bridge_length = 10;
		_max_tunnel_length = 20;
		_running = false;
 	}
 	
 	/**
	 * A function that returns the cost of a path.
	 * @param path current is an instance of AyStar.Path
	 * @param new_tile the new node that is added to that path.
	 * @param new_direction current direction
	 * @return the cost of the path including new tile
 	 */
	function _Cost (path, new_tile, new_direction);
	
	/**
	 * A function that returns all neighbouring nodes from a given node
	 * @param path current path
	 * @param cur_tile current node
	 * @return return an array containing all
	 *  neighbouring nodes, which are an array in the form [tile, direction, cost]
	 */
	function _Neighbours (path, cur_tile);
	
	/**
	 * Get direction bit to go from "from" to "to"
	 * @param from tile to go from
	 * @param to tile to go to
	 * @param is_bridge set true if it was bridge
	 * @return direction bit, should not be zero
	 */
	function _GetDirection(from, to, is_bridge);
	
	/**
	 * A function to check if both directions can go together on a single tile.
	 * @param tile current node
	 * @param existing_direction current direction
	 * @param new_direction new direction
	 * @return true if both directions can go together on a single tile.
	 */
	function _CheckDirection(tile, existing_direction, new_direction) { return false; }
	
	/**
	 * Get the state of pathfinder
	 * @return true if the pathfinder is in running mode
	 */
	function IsRunning() { return _running; }
		
	/**
	 * Destructor of AyStar. Set all (important) values to null | false;
	 */
	function Reset()
 	{
		_closed = null;
		_open = null;
		_goals = null;
		_running = false;
		_accountant.ResetCosts();
 	}
 
	/**
	 * Estimate from a node to the goal node
	 * @param cur_tile current node
	 * @return a minimum estimate distance left between node and any node out of goal_nodes.
	 * @note this estimate is only return distance, they could be combined with tile cost, etc.
	 */
	function _Estimate (path, cur_tile) {
		local min_cost = _max_len;
		foreach (tile in _goals) {
			if (typeof tile == "array") {
				min_cost = min(min_cost, AIMap.DistanceManhattan(tile[0], cur_tile));
			} else {
				min_cost = min(min_cost, AIMap.DistanceManhattan(tile, cur_tile));
			}
		}
		return min_cost;		
	}
	
	/** check if tunnel/bridge is in correct direction (must be exist)
	 * @param current_tile tile before b/t
	 * @param new_tile tile that is b/t
	 * @return true if [current_tile => new_tile => other_end b/t] is straight forward.
	 */
	function _CheckTunnelBridge(current_tile, new_tile)
	{
		if (!XTile.IsBridgeTunnel(new_tile)) return false;
		local other_end = XTile.GetBridgeTunnelEnd(new_tile);
		return current_tile == XTile.NextTile(other_end, new_tile);
	}
	
	/**
	 * Initialize a path search between sources and goals.
	 * @param sources The source nodes. This can an array of either [tile, direction]-pairs or AyStar.Path-instances.
	 * @param goals The target tiles. This can be an array of either tiles or [tile, next_tile]-pairs.
	 * @param ignored_tiles An array of tiles that cannot occur in the final path.
	 */
	function Initialize (sources, goals, ignored_tiles) {
		if (typeof(sources) != "array" || sources.len() == 0) throw("sources has be a non-empty array.");
		if (typeof(goals) != "array" || goals.len() == 0) throw("goals has be a non-empty array.");
	
		_open = FibonacciHeap_2();
		_closed = AIList();
		_goals = goals;
		
		foreach (node in sources) {
			if (typeof(node) == "array") {
				//for road, water and ... air :D
				if (node[1] <= 0) throw("directional value should never be zero or negative.");
	
				local new_path = AyPath(null, node[0], node[1], node[2]);
				_open.Insert(new_path, new_path.GetCost() + _Estimate(new_path, node[0]));
			} else {
				//for rail pf
				_open.Insert(node, node.GetCost());
 		}
	}
	
		foreach (tile in ignored_tiles) {
			_closed.AddItem(tile, ~0);
		}
		_running = true;
	}
	
	/**
	 * Try to find the path as indicated with InitializePath with the lowest cost.
	 * @param iterations After how many iterations it should abort for a moment.
	 *  This value should either be -1 for infinite, or > 0. Any other value
	 *  aborts immediatly and will never find a path.
	 * @return A route if one was found, or false if the amount of iterations was
	 *  reached, or null if no path was found.
	 *  You can call this function over and over as long as it returns false,
	 *  which is an indication it is not yet done looking for a route.
	 */
	function FindPath (iterations)
	{
		if (_open == null) throw("can't execute over an uninitialized path");
		local test_mode = AITestMode();
		Info ("path finding #", iterations);
		while (_open.Count() > 0 && (iterations == -1 || iterations-- > 0)) {
			//commit : Do we need to sleep first ?
			AIController.Sleep(1);
			//Info("Get the path with the best score so far");
			local path = _open.Pop();
			local cur_tile = path.GetTile();
			/* Make sure we didn't already passed it */
			if (_closed.HasItem(cur_tile)) {
				/* If the direction is already on the list, skip this entry */
				if ((_closed.GetValue(cur_tile) & path.GetDirection()) != 0) continue;
	
				/* Scan the path for a possible collision */
				local scan_path = path.GetParent();
	
				local mismatch = false;
				while (scan_path != null) {
					if (scan_path.GetTile() == cur_tile) {
						if (!_CheckDirection(cur_tile, scan_path.GetDirection(), path.GetDirection())) {
							mismatch = true;
							break;
	}
 }
					scan_path = scan_path.GetParent();
				}
				if (mismatch) continue;
	
				/* Add the new direction */
				_closed.SetValue(cur_tile, _closed.GetValue(cur_tile) | path.GetDirection());
			} else {
				/* New entry, make sure we don't check it again */
				_closed.AddItem(cur_tile, path.GetDirection());
			}
			//Info("Check if we found the end");
			foreach (goal in _goals) {
				if (typeof(goal) == "array") {
					if (cur_tile == goal[0]) {
						local neighbours = _Neighbours(path, cur_tile);
						foreach (node in neighbours) {
							if (node[0] == goal[1]) {
								Info ("path finding succeed");
								Reset();
								return path;
							}
						}
						continue;
					}
				} else {
					if (cur_tile == goal) {
						Info ("path finding succeed");
						Reset();
						return path;
					}
				}
			}
			//Info("Scan all neighbours");
			local neighbours = _Neighbours(path, cur_tile);
			foreach (node in neighbours) {
				//don't know where
				//if (typeof node != "array") continue;
				
				if ((_closed.GetValue(node[0]) & node[1]) != 0) continue;
				/* Calculate the new paths and add them to the open list */
				local new_path = AyPath(path, node[0], node[1], node[2]);
				_open.Insert(new_path, new_path.GetCost() + _Estimate(path, node[0]));
			}
		}
	
		if (_open.Count() > 0) {
			Info("Next cost:", _open.Peek().GetCost());
			return false;
		}
		Warn ("path finding failed");
		Reset();
		return null;
	}
};