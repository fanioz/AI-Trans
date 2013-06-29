/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
* XTile class
* an AITile eXtension
*/
class XTile
{
	/**
	 * Get North tile(s) Of a tile
	 * @param tile tile to check
	 * @param num number of tile from 'tile'
	 * @return amount 'num' North of 'tile'
	 */
	function N_Of(tile, num) {
		return tile + AIMap.GetTileIndex(-num, -num);
	}

	/**
	* Get West tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' West of 'tile'
	*/
	function W_Of(tile, num) {
		return XTile.AddOffset(tile, num, -num);
	}

	/**
	* Get South tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' South of 'tile'
	*/
	function S_Of(tile, num) {
		return XTile.AddOffset(tile, num, num);
	}

	/**
	* Get East tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' East of 'tile'
	*/
	function E_Of(tile, num) {
		return XTile.AddOffset(tile, -num, num);
	}

	/**
	* Get North East tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' North East of 'tile'
	*/
	function NE_Of(tile, num) {
		return XTile.AddOffset(tile, -num, 0);
	}

	/**
	* Get  North West tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' North West of 'tile'
	*/
	function NW_Of(tile,  num) {
		return XTile.AddOffset(tile, 0, -num);
	}

	/**
	* Get  South East tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' South East of 'tile'
	*/
	function SE_Of(tile, num) {
		return XTile.AddOffset(tile, 0, num);
	}

	/**
	* Get  South West tile(s) Of a tile
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' South West of 'tile'
	*/
	function SW_Of(tile,  num) {
		return XTile.AddOffset(tile, num, 0);
	}

	/**
	* Get adjacent tiles of a tile
	* @param tile tile to check
	* @return Adjacent of 'tile' in 4 direction
	*/
	function Adjacent(tile) {
		foreach(id in [
					XTile.NE_Of(tile, 1),
					XTile.NW_Of(tile, 1),
					XTile.SE_Of(tile, 1),
					XTile.SW_Of(tile, 1)]
			   ) yield id;
	}

	/**
	 * Demolish Rectangle
	 * @return true if area demolished
	 */
	function DemolishRect(tilestart, x, y) {
		foreach(idx, val in XTile.MakeArea(tilestart, x, y, 0)) {
			if (!AITile.DemolishTile(idx)) return false;
		}
		return true;
	}

	/**
	 * Get the WholeMap tiles
	  * @return Whole Map Tile List (what for huh?)
	  */
	function WholeMap() {
		local loc = AITileList();
		loc.AddRectangle(AIMap.GetTileIndex(1, 1), AIMap.GetTileIndex(AIMap.GetMapSizeX() - 2, AIMap.GetMapSizeY() - 2));
		return loc;
	}

	/**
	* Check if these tile is in straight direction
	* @param tile_st first tile to check
	* @param tile_nd second tile check
	* @return True if they are straight, otherwise false
	*/
	function IsStraight(tile_st, tile_nd) {
		return (XTile.IsStraightX(tile_st, tile_nd) || XTile.IsStraightY(tile_st, tile_nd));
	}

	function IsStraightY(tile_st, tile_nd) {
		return AIMap.GetTileY(tile_st) == AIMap.GetTileY(tile_nd);
	}

	function IsStraightX(tile_st, tile_nd) {
		return AIMap.GetTileX(tile_st) == AIMap.GetTileX(tile_nd);
	}

	/**
	 * Make true tile level
	 * @return true if the tile is leveled
	 */
	function MakeLevel(tilestart, x, y) {
		if (!AIMap.IsValidTile(tilestart)) return false;
		local tile_num = x * y;
		local tiles = XTile.MakeArea(tilestart, x, y, 0);
		if (XTile.IsLevel(tiles)) return true;
		tiles.Valuate(XTile.Height);
		local minh = 100, maxh = 0;
		foreach(tile, h in tiles) {
			maxh = max(h, maxh);
			minh = min(h, minh);
		}
		local target_h = (minh + maxh) / 2;
		Info("target h:" + target_h);
		Debug.Sign(tilestart, target_h);
		local tileend = XTile.AddOffset(tilestart, x , y);
		if (!XTile.SetHeightEnough(tilestart, target_h)) return false;
		AITile.LevelTiles(tilestart, tileend);
		Warn("Leveling [API]", AIError.GetLastErrorString());
		return XTile.IsLevel(tiles);
	}

	/**
	 * Check if tiles is can leveled
	 * @return true if have no slope
	*/
	function IsLevel(tiles) {
		foreach(idx, v in tiles) if (!XTile.IsFlat(idx)) return false;
		return true;
	}

	function SetFlatHeight(tilestart, target_h) {
		if (!(XTile.IsFlat(tilestart) && AITile.GetMaxHeight(target_h))) {
			if (AITile.GetSlope(tilestart) != AITile.SLOPE_FLAT) {
				Info("Flattening");
				if (! AITile.RaiseTile(tilestart, AITile.GetComplementSlope(AITile.GetSlope(tilestart)))) return false;
			}
			if (XTile.Height(tilestart) < target_h) {
				Info("Increase height");
				if (! AITile.RaiseTile(tilestart, AITile.GetComplementSlope(AITile.GetSlope(tilestart)))) return false;
			} else if (XTile.Height(tilestart) > target_h) {
				Info("Decrease height");
				if (! AITile.LowerTile(tilestart, AITile.GetSlope(tilestart) == AITile.SLOPE_FLAT ? AITile.SLOPE_ELEVATED : AITile.GetSlope(tilestart)))	return false;
			}
		}
		return true;
	}

	/**
	* Check if these tile is road or buildable
	* @param tile tile to check
	* @return True if it was road or buildable
	*/
	function IsRoadBuildable(tile) {
		if (AITile.IsBuildable(tile)) return true;
		foreach(rt in Const.RoadTypeList) if (AIRoad.HasRoadType(tile, rt)) return true;
		return false;
	}

	/** Can Set the tile flat on height
	 * @param tile to set
	 * @param height of tile to set
	 * @return true if tile is flat and high enough (test mode)
	 */
	function CanSetFlatHeight(tile, height) {
		if (!AIMap.IsValidTile(tile)) return false;
		local slope = AITile.GetSlope(tile);
		//Debug.Say(["Max.H:" + max_h + " Target:" + height);
		foreach(corn in Const.Corner) {
			if (AITile.GetCornerHeight(tile, corn) < height) {
				if (!AITile.RaiseTile(tile, 1 << corn)) return false;
			}
			if (AITile.GetCornerHeight(tile, corn) > height) {
				if (!AITile.LowerTile(tile, 1 << corn)) return false;
			}
		}
		return true;
	}

	/**
	 * Should be used only when terraforming from top of tile to bottom
	 */
	function IsHeightEnough(tile, height) {
		return AITile.GetCornerHeight(tile, AITile.CORNER_N) == height;
	}

	/**
	 * Should be used only when terraforming from top of tile to bottom
	 */
	function SetHeightEnough(tile, height) {
		if (AITile.GetCornerHeight(tile,  AITile.CORNER_N) < height) {
			if (!AITile.RaiseTile(tile, 1 <<  AITile.CORNER_N)) return false;
		}
		if (AITile.GetCornerHeight(tile,  AITile.CORNER_N) > height) {
			if (!AITile.LowerTile(tile, 1 <<  AITile.CORNER_N)) return false;
		}
		return true;
	}

	/**
	 * Can we build on tiles
	 * @param start_t ile
	 * @param x Width
	 * @param y lenght
	 * @return 0 = can't build. 1 can w/o tf. other = cost for tf tiles
	 */
	function IsBuildableRange(start_t, x, y) {
		if (!AIMap.IsValidTile(start_t)) return 0;
		local tile_num = x * y;
		local tiles = XTile.MakeArea(start_t, x, y, 0);
		if (tiles.Count() != tile_num) {
			//Debug.Say(["area tiles count:num==", tiles.Count(), ":", tile_num], 0);
			return 0;
		}
		tiles.Valuate(XTile.IsMyTile);
		tiles.RemoveValue(1);
		if (tiles.Count() != tile_num) {
			//Debug.Say(["my tiles count:num==", tiles.Count(), ":", tile_num], 0);
			return 0;
		}
		tiles.Valuate(AITile.IsBuildable);
		tiles.RemoveValue(0);
		if (tiles.Count() != tile_num) {
			//Debug.Say(["buildable tiles count:num==" + tiles.Count() + ":" + tile_num);
			return 0;
		}
		tiles.Valuate(XTile.Height);
		tiles.RemoveValue(0);
		if (tiles.Count() != tile_num) {
			//Debug.Say(["height tiles count:num==", tiles.Count(),  ":", tile_num], 1);
			return 0;
		}
		if (XTile.IsLevel(tiles)) {
			//Debug.Say(["already flat"], 1);
			return 1;
		}
		local minh = 100, maxh = 0;
		foreach(tile, h in tiles) {
			maxh = max(h, maxh);
			minh = min(h, minh);
		}
		if ((maxh - minh) > 1) return 0;
		local target_h = (minh + maxh) / 2;
		local c = AIAccounting();
		local mode = AITestMode();
		local end_tile = XTile.AddOffset(start_t, x, y);
		foreach(tile, v in tiles) {
			if (!XTile.CanSetFlatHeight(tile, target_h)) {
				My.Warn("cant make flat a tile", AIError.GetLastErrorString());
				return 0;
			}
		}
		return max(c.GetCosts(), 1);
	}

	function IsFlat(idx) {
		local slope = AITile.GetSlope(idx);
		if (slope == AITile.SLOPE_FLAT || slope == AITile.SLOPE_ELEVATED) return true;
		if (!Setting.Get(SetString.build_on_slopes)) return false;
		switch (slope) {
			case AITile.SLOPE_NWS :
			case AITile.SLOPE_WSE :
			case AITile.SLOPE_SEN :
			case AITile.SLOPE_ENW :
				return true;
		}
		return false;
	}

	function IsAutoFlat(current, next) {
		if (::XTile.IsFlat(current)) return true;
		local slope = AITile.GetSlope(current);
		if (AITile.IsSteepSlope(slope)) return false;
		if (!Setting.Get(SetString.build_on_slopes)) return false;
		local dist = AIMap.DistanceManhattan(current, next);
		if ((::XTile.NW_Of(current, dist) == next) &&
				(Assist.HasBit(slope, AITile.SLOPE_N) || Assist.HasBit(slope, AITile.SLOPE_W))) return false;
		if ((::XTile.NE_Of(current, dist) == next) &&
				(Assist.HasBit(slope, AITile.SLOPE_N) || Assist.HasBit(slope, AITile.SLOPE_E))) return false;
		if ((::XTile.SE_Of(current, dist) == next) &&
				(Assist.HasBit(slope, AITile.SLOPE_S) || Assist.HasBit(slope, AITile.SLOPE_E))) return false;
		if ((::XTile.SW_Of(current, dist) == next) &&
				(Assist.HasBit(slope, AITile.SLOPE_S) || Assist.HasBit(slope, AITile.SLOPE_W))) return false;
		return true;
	}

	/**
	 * Is going from current to next is sloped up
	 * @param current tile
	 * @param next tile
	 * @return true if next tile is sloped up (absolute) from current view
	 */
	function IsNextSlopedUp(current, next) {
		assert(AIMap.DistanceManhattan(current, next) == 1);
		switch (AITile.GetSlope(next)) {
			case AITile.SLOPE_NW: return (XTile.NW_Of(current, 1) == next);
			case AITile.SLOPE_NE: return (XTile.NE_Of(current, 1) == next);
			case AITile.SLOPE_SE: return (XTile.SE_Of(current, 1) == next);
			case AITile.SLOPE_SW: return (XTile.SW_Of(current, 1) == next);
			default: break;
		}
		return false;
	}

	function Height(idx) {
		if (XTile.IsFlat(idx)) return AITile.GetMaxHeight(idx);
		local slope = AITile.GetSlope(idx);
		switch (slope) {
			case AITile.SLOPE_STEEP_W:
			case AITile.SLOPE_STEEP_S:
			case AITile.SLOPE_STEEP_N:
			case AITile.SLOPE_STEEP_E:
			case AITile.SLOPE_N:
			case AITile.SLOPE_E:
			case AITile.SLOPE_W:
			case AITile.SLOPE_S:
				return AITile.GetMaxHeight(idx) - 1;
			case AITile.SLOPE_SE:
			case AITile.SLOPE_SW:
			case AITile.SLOPE_NW:
			case AITile.SLOPE_NS:
			case AITile.SLOPE_NE:
			case AITile.SLOPE_EW:
				return AITile.GetMaxHeight(idx) / 2;
		}
		Debug.Say(["slope invalid:" + slope], 2);
		return 0;
	}

	/**
	 * Check if tile is my tile
	 * @param tile 'tile to check
	 * @return true if "tile" is mine
	 */
	function IsMyTile(tile) {
		return AICompany.IsMine(AITile.GetOwner(tile));
	}

	/**
	 * Check if tile is competitor tile
	 * @param tile to check
	 * @return true if its owned by competitor
	 */
	function IsCompetitorTile(tile) {
		local owner = AITile.GetOwner(tile);
		return AICompany.COMPANY_INVALID != owner && !AICompany.IsMine(owner);
	}

	/**
	 * Gets the TileIndex relatively from given offset.
	 * @param tile Start tile.
	 * @param x The X offset.
	 * @param y The Y offset.
	 * @pre x and y adjustement is not out of map size
	 * @return The new tile.
	 */
	function AddOffset(tile, x, y) {
		if (!AIMap.IsValidTile(tile)) return AIMap.TILE_INVALID;

		local tx = AIMap.GetTileX(tile) + x;
		local ty = AIMap.GetTileY(tile) + y;
		if (tx < 1 || tx > (AIMap.GetMapSizeX() - 2)) return AIMap.TILE_INVALID;
		if (ty < 1 || ty > (AIMap.GetMapSizeY() - 2)) return AIMap.TILE_INVALID;

		return AIMap.GetTileIndex(tx, ty);
	}

	/**
	 * Display tile co-ordinat inside in the form of [x,y]
	 * @param idx tile index
	 */
	function ToString(idx) {
		return "[" + AIMap.GetTileX(idx) + ", " + AIMap.GetTileY(idx) + "]";
	}

	function IsRailable(pre, from, to) {
		if (XRail.HasRail(from) && AIRail.AreTilesConnected(pre, from, to)) return true;
		if (AITile.GetMaxHeight(from) < 1) return false;
		return AIRail.BuildRail(pre, from, to);
	}

	function IsWaterable(from, to) {
		if (AIMarine.AreWaterTilesConnected(from, to)) return true;
		return AIMarine.BuildCanal(from);
	}

	/**
	 * Get tiles of an area in number of radius
	 * @param tile center of tile
	 * @param rad_X radius of area to get by X axis
	 * @param rad_Y radius of area to get by Y axis
	 * @return  tiles of radius x.y from "tile"
	 */
	function Radius(tile, rad_X, rad_Y) {
		local area = CLList(null);
		local top = XTile.GetMaxNorth(tile, rad_X, rad_Y);
		local bottom = XTile.GetMaxSouth(tile, rad_X, rad_Y);
		area.AddRectangle(top, bottom);
		return area;
	}
	/**
	 * Make area from North to South
	 * @param tile North
	 * @param w x length
	 * @param h  y length
	 * @param rad radius from each corners of [w x h] area
	 * @return tiles of [w x h] area expanded by radius
	 * @note MakeArea (tile, 1, 1, 0) would fill the tile alone
	 */
	function MakeArea(tile, w, h, rad) {
		local top = XTile.GetMaxNorth(tile, rad, rad);
		local bottom = XTile.GetMaxSouth(tile, w - 1 + rad, h - 1 + rad);
		local area = CLList();
		area.AddRectangle(top, bottom);
		return area;
	}

	function GetMaxNorth(center, rad_x, rad_y) {
		if (!AIMap.IsValidTile(center)) return -1;
		local tilex = AIMap.GetTileX(center) - rad_x;
		local tiley = AIMap.GetTileY(center) - rad_y;
		return AIMap.GetTileIndex(max(0, tilex), max(0, tiley));
	}
	function GetMaxSouth(center, rad_x, rad_y) {
		if (!AIMap.IsValidTile(center)) return -1;
		local tilex = AIMap.GetTileX(center) + rad_x;
		local tiley = AIMap.GetTileY(center) + rad_y;
		return AIMap.GetTileIndex(min(tilex, AIMap.GetMapSizeX() - 2), min(tiley, AIMap.GetMapSizeY() - 2));
	}

	function GetAdjacentRoad(t) {
		foreach(tile in XTile.Adjacent(t)) {
			if (AIRoad.IsRoadStationTile(tile)) continue;
			if (AIRoad.IsRoadDepotTile(tile)) continue;
			if (AIRoad.IsRoadTile(tile)) return tile;
		}
		return -1;
	}

	// return true if tile IsMatchLayOut with townID
	function IsMatchLayOut(tile, townID) {
		local factor = (AITown.GetRoadLayout(townID) == AITown.ROAD_LAYOUT_2x2) ? 3 : 4;
		return (AIMap.DistanceMax(AITown.GetLocation(townID), tile) % factor) == 1;
		//return AIMap.DistanceMax(AITown.GetLocation (townID) ,tile) > 0;
	}

	// Build a station need rating -200 => AITown.TOWN_RATING_POOR
	function HasEnoughRating(tile) {
		local id = AITile.GetClosestTown(tile);
		if (!AITown.IsWithinTownInfluence(id, tile)) return true;
		return XTown.HasEnoughRating(id);
	}

	function GetTrackList(tile, vt) {
		AIController.Sleep(1);
		local track_list = CLList();
		switch (vt) {
			case AIVehicle.VT_RAIL:
				foreach(rt, v in AIRailTypeList()) {
					if (XRail.HasRail(tile, rt)) track_list.AddItem(rt, 0);
				}
				return track_list;
			case AIVehicle.VT_ROAD:
				foreach(rt in Const.RoadTypeList) {
					if (AIRoad.HasRoadType(tile, rt)) track_list.AddItem(rt, 0);
				}
				return track_list;
			case AIVehicle.VT_AIR:
				local air_type = AIAirport.GetAirportType(tile);
				foreach(rt in Const.PlaneType) {
					if (XAirport.AllowPlaneToLand(rt, air_type)) track_list.AddItem(rt, 0);
				}
				return track_list;
			case AIVehicle.VT_WATER:
				track_list.AddItem(1);
			default :
				return track_list;
		}
	}

	function NextTile(from, to) {
		return XTile.NextTileNum(from, to, 1);
	}

	function NextTileNum(from, to, num) {
		if (AIMap.GetTileX(to) < AIMap.GetMapSizeX() && AIMap.GetTileY(to) < AIMap.GetMapSizeY()) {
			return to + (to - from) / AIMap.DistanceManhattan(to, from) * num;
		}
		if (Debug.Sign(to, "here") != -1) throw("reach edge map");
		return -1;
	}

	function IsBridgeTunnel(tile) {
		return (AIBridge.IsBridgeTile(tile) || AITunnel.IsTunnelTile(tile));
	}

	function GetBridgeTunnelEnd(tile) {
		if (AIBridge.IsBridgeTile(tile)) return AIBridge.GetOtherBridgeEnd(tile);
		return AITunnel.GetOtherTunnelEnd(tile);
	}

	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param trans_type current transport type
	 * @return cost of new tile
	 */
	function GetCost(self, path, new_tile, trans_type) {
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
		if (!AITile.HasTransportType(new_tile, trans_type)) return self._max_cost;
		return path.GetCost() + 1;
	}

	/**
	 * Calculate cost of using this bridge tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @return cost factor of bridge tile
	 */
	function BridgeCost(self, path, new_tile) {
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
		/* if vhc speed not set, return */
		if (self._vhc_max_spd == 0) return 0;
		local prev_tile = path.GetTile();
		local cost = 0;

		/* If the new tile is a bridge tile, check whether we came from the other
		 * end of the bridge. */
		if (AIBridge.IsBridgeTile(new_tile) && AIBridge.GetOtherBridgeEnd(new_tile) == prev_tile) {
			local old_spd = AIBridge.GetMaxSpeed(AIBridge.GetBridgeID(new_tile));
			if (self._vhc_max_spd < old_spd) return 0;
			local cur_len = AIMap.DistanceManhattan(new_tile, prev_tile);
			local b_list = AIBridgeList_Length(cur_len);
			b_list.Valuate(AIBridge.GetMaxSpeed);
			foreach(b, speed in b_list) {
				if (self._vhc_max_spd > speed) return (10 * speed / old_spd).tointeger();
			}
		}
		/* dont call path.getcost */
		return cost;
	}

	function NextNeighbour(pre_from, from, to) {
		if (pre_from == null) pre_from = PFHelper.NextTile(to, from);
		foreach(next in XTile.Adjacent(to)) {
			/* Don't turn back */
			if (next == from) continue;
			/* Disallow 90 degree turns */
			if (next - to == pre_from - from) continue;
			/* can only pass a twoway or PBS signal */
			if (!(::PFHelper.IsMatchSignal(to, next) || PFHelper.IsReversableSignal(to, next))) continue;
			/* assume we can go to next tile */
			yield next;
		}
	}
}
