/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * The path of the AyStar algorithm.
 *  It is reversed, that is, the first entry is more close to the goal-nodes
 *  than his GetParent(). You can walk this list to find the whole path.
 *  The last entry has a GetParent() of null.
 */
class AyPath
{
	_prev = null;
	_tile = null;
	_direction = null;
	_cost = null;
	_length = null;
	_first = null;
	_count = null;
	_build_cost = null;

	constructor(old_path, new_tile, new_direction, buildCost, cost) {
		_prev = old_path;
		_tile = new_tile;
		_direction = new_direction;
		_cost = cost
		if (old_path == null) {
			_length = 0;
			_first = new_tile;
			_count = 1;
			_build_cost = buildCost;
		} else {
			_length = old_path.GetLength() + AIMap.DistanceManhattan(old_path.GetTile(), new_tile);
			_first =  old_path.GetFirstTile();
			_count = old_path.Count() + 1;
			_build_cost = old_path.GetBuildCost() + buildCost;
		}
	};

	/**
	 * Return the tile where this (partial-)path ends.
	 */
	function GetTile() { return _tile; }

	/**
	 * Return the direction from which we entered the tile in this (partial-)path.
	 */
	function GetDirection() { return _direction; }

	/**
	 * Return an instance of this class leading to the previous node.
	 */
	function GetParent() { return _prev; }

	/**
	 * Return the cost of this (partial-)path from the beginning up to this node.
	 */
	function GetCost() { return _cost; }
	/**
	 * Return the length (in tiles) of this path.
	 */
	function GetLength() { return _length; }

	/**
	 * Return the first tile of this path.
	 */
	function GetFirstTile() { return _first; }

	/**
	 * return the building cost 
	 */
	function GetBuildCost() { return _build_cost; }
	/**
	 * Return the number of node in this path.
	 * @note if path no longer has a parent, it would return 1
	 */
	function Count() { return _count;}
	
	function GetID() { return _tile;}
};
