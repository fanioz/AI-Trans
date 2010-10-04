/*  09.02.05 - tile.nut
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
* Tile Static functions
*/
class Tiles
{

    /**
     * Get North tile(s) Of a tile
     * @param tile tile to check
     * @param num number of tile from 'tile'
     * @return amount 'num' North of 'tile'
     */
    static function N_Of(tile = 0, num = 1)
    {
      return tile + AIMap.GetTileIndex(-num, -num);
    }

    /**
    * Get West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' West of 'tile'
    */
    static function W_Of(tile = 0, num = 1)
    {
      return tile + AIMap.GetTileIndex(num, -num);
    }

    /**
    * Get South tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South of 'tile'
    */
    static function S_Of(tile = 0, num = 1)
    {
      return tile + AIMap.GetTileIndex(num, num);
    }

    /**
    * Get East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' East of 'tile'
    */
    static function E_Of(tile = 0, num = 1)
    {
        return tile + AIMap.GetTileIndex(-num, num);
    }

    /**
    *
    * Get North East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' North East of 'tile'
    */
    static function NE_Of(tile = 0, num = 1)
    {
      return tile + AIMap.GetTileIndex(-num, 0);
    }

    /**
    * Get  North West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' North West of 'tile'
    */
    static function NW_Of(tile = 0,  num = 1)
    {
      return tile + AIMap.GetTileIndex(0, -num);
    }

    /**
    * Get  South East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South East of 'tile'
    */
    static function SE_Of(tile = 0, num = 1)
    {
      return tile + AIMap.GetTileIndex(0, num);
    }

    /**
    * Get  South West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South West of 'tile'
    */
    static function SW_Of(tile = 0,  num = 1)
    {
      return tile + AIMap.GetTileIndex(num, 0);
    }

    /**
    * Get adjacent tiles of a tile
    * @param tile tile to check
    * @return Adjacent of 'tile' in 4 direction
    */
    static function Adjacent(tile)
    {
        local adjacen = AITileList();
        adjacen.AddTile(Tiles.NE_Of(tile));
        adjacen.AddTile(Tiles.NW_Of(tile));
        adjacen.AddTile(Tiles.SW_Of(tile));
        adjacen.AddTile(Tiles.SE_Of(tile));
        return Tiles.Validated(adjacen);
    }

    /**
     * Demolish Rectangle
     * @return true if area demolished
     */
    static function DemolishRect(tilestart, tileend) {
        local tiles = AITileList();
        tiles.AddRectangle(tilestart, tileend);
        foreach (idx, val in tiles) {            
            if (!AITile.DemolishTile(idx)) return false;
        }
        return true;
    }

    /**
     * @return average height of tile list
     */
    static function AverageHeight(tiles)
    {
		assert(typeof tiles == "array");
		local heights = [];
		local ht = 0;
		foreach (idx, val in tiles) {
			ht = AITile.GetMaxHeight(val);
			if (ht != AITile.GetMinHeight(val)) {
				local hcor = [];
				foreach (idx, corner in Const.Corner) hcor.push(AITile.GetCornerHeight(val, corner));
				ht = Assist.Average(hcor);
				if (ht == 0) ht = 1;				
			}
			heights.push(ht);
		}
		ht = Assist.Average(heights);
		if (ht == 0) ht = 1;
		return ht;
	}

    /**
    * Get tiles of an area in number of radius
    * @param tile center of tile
    * @param rad_X radius of area to get by X axis
    * @param rad_Y radius of area to get by Y axis
    * @return  tiles of "radius" from "tile"
    * @note leave undefined rad_Y to get squared area
    */
    static function Radius(tile, rad_X, rad_Y = null)
    {
        local area = Tiles.Radius_N(tile, rad_X, rad_Y);
        area.AddList(Tiles.Radius_N(tile, -rad_X, rad_Y));
        area.AddList(Tiles.Radius_W(tile, rad_X, rad_Y));
        area.AddList(Tiles.Radius_W(tile, -rad_X, rad_Y));
        area.Sort(AIAbstractList.SORT_BY_ITEM, true);
        return area;
    }

    /**
    * Get North tiles of an area in number of radius
    * @param tile center of tile
    * @param rad_X radius of area to get by X axis
    * @param rad_Y radius of area to get by Y axis
    * @return  tiles of "radius" from North of "tile"
    * @note use negative value to get South of tile
    * @note leave undefined rad_Y to get squared area
    */
    static function Radius_N(tile, rad_X, rad_Y = null)
    {
        rad_Y = (rad_Y == null) ? rad_X : rad_Y;
        local area = AITileList();
        area.AddRectangle(tile, tile - AIMap.GetTileIndex(rad_X, rad_Y));
        return Tiles.Validated(area);
    }

    /**
    * Get West tiles of an area in number of radius
    * @param tile center of tile
    * @param rad_X radius of area to get by X axis
    * @param rad_Y radius of area to get by Y axis
    * @return  tiles of "radius" from West of "tile"
    * @note use negative value to get East of tile
    * @note leave undefined rad_Y to get squared area
    */
    static function Radius_W(tile, rad_X, rad_Y = null)
    {
        rad_Y = (rad_Y == null) ? rad_X : rad_Y;
        local area = AITileList();
        area.AddRectangle(tile, tile + AIMap.GetTileIndex(rad_X, -rad_Y));
        return Tiles.Validated(area);
    }

    /**
    * Get Validated tiles of area
    * @param tiles tiles to validate
    * @return validated tiles of 'tiles'
    */
    static function Validated(tiles)
    {
        tiles.Valuate(AIMap.IsValidTile);
        tiles.KeepValue(1);
        return tiles;
    }

    /**
    * Get Roads tiles of area
    * @param tiles area of tiles to filter
    * @param yes a Value to keep
    * @return the road tiles of 'tiles'
    */
    static function Roads(tiles, yes = 1)
    {
        local tile = tiles;
        tile.Valuate(AIRoad.IsRoadTile);
        tile.KeepValue(yes);
        return tile;
    }

    /**
    * Get Buildable tiles of area
    * @param tiles area of tiles to filter
    * @param yes a Value to keep
    * @return the buildable tiles of 'tiles'
    */
    static function Buildable(tiles, yes = 1)
    {
        local tilest = tiles;
        tilest.Valuate(AITile.IsBuildable);
        tilest.KeepValue(yes);
        return tilest;
    }

    /**
    * Get the WholeMap tiles
    * @return Whole Map Tile List
    */
    static function WholeMap()
    {
        local loc = AITileList();
        loc.AddRectangle(AIMap.GetTileIndex(1, 1),AIMap.GetTileIndex(AIMap.GetMapSizeX() - 2, AIMap.GetMapSizeY() - 2));
        return loc;
    }

    /**
    * Get Flattened tiles of area
    * @param tiles area of tiles to filter
    * @return Flat Tile List
    */
    static function Flat(tiles)
    {
        local tile = tiles;
        tile.Valuate(AITile.GetSlope);
        tile.KeepValue(AITile.SLOPE_FLAT);
        return tile;
    }

   /**
    * Check if tile is mine
    * @param tile 'tile to check
    * @return true if "tile" is mine
    */
    static function IsMine(tile)
    {
        return  AICompany.IsMine(AITile.GetOwner(tile));
    }

    /**
    * Check if tile is competitor own
    * @param tile to check
    * @return true if its owned by competitor
    */
    static function IsCompetitors(tile)
    {
        return (!Tiles.IsMine(tile) && AICompany.COMPANY_INVALID != AITile.GetOwner(tile));
    }

    /**
     * @param tile to check
     * @return true if tile is kind of depot
     */
    static function IsDepotTile(tile)
    {
        return  (AIRoad.IsRoadDepotTile(tile) || AIRail.IsRailDepotTile(tile) ||
                    AIAirport.IsHangarTile(tile) || AIMarine.IsWaterDepotTile(tile));
    }

    /**
    * Check if I can demolish a Tile using test mode
    * @param tile to demolish
    * @return true if can demolish that tile
    */
    static function CanDemolish(tile)
    {
        local at = AITestMode();
        return AITile.DemolishTile(tile);
    }

    /**
     * Find any depot around base
     * @return tiles of depot
     */
    static function DepotOn(base, rad = 10)
    {
        local area = Tiles.Radius(base, rad);
        area.Valuate(Tiles.IsMine);
        area.KeepValue(1);
        area.Valuate(Tiles.IsDepotTile);
        area.KeepValue(1);
        area.Valuate(AITile.GetDistanceManhattanToTile, base);
        area.Sort(AIAbstractList.SORT_BY_VALUE, true);
        return area;
    }

    /**
    * Get Ignorance tile while path finding
    * @return AITilelist of ignored tiles
    */
    static function ToIgnore()
	{
		local w = TransAI.WholeMapTiles;
		Assist.Valuate(w, function(tile) {
			if (AITile.GetMaxHeight(tile) == 0) return 0;
			return Tiles.IsRoadBuildable(tile);
		});
		w.KeepValue(0);		
		return w;
	}

    /**
    * Get water tiles of  area
    * @param area AITileList of an area
    * @param yes a Value to keep
    * @return  Water tiles of an area
    */
    static function Waters(area, yes = 1)
    {
        local tiles = area;
        tiles.Valuate(AITile.IsWaterTile);
        tiles.KeepValue(yes);
        return tiles;
    }

    /**
    * Get the body of "head" depot/station tile
    * @param head tile that become head
    * @return a non-water nor road AITileList that adjacent to the head
    */
    static function BodiesOf(head)
    {
        return Tiles.Roads(Tiles.Waters(Tiles.Adjacent(head), 0), 0);;
    }

    /**
    * Check if these tile is in straight direction
    * @param tile_st first tile to check
    * @param tile_nd second tile check
    * @return True if they are straight, otherwise false
    */
    static function IsStraight(tile_st, tile_nd)
    {
        return (AIMap.DistanceManhattan(tile_st, tile_nd) == AIMap.DistanceMax(tile_st, tile_nd));
    }

    /**
     * Make tile level
     * @return true if the tile is leveled
     */
    static function MakeLevel(tilestart, tileend)
    {
    	if (Debug.ResultOf("Level tiles[1]", AITile.LevelTiles(tilestart, tileend))) return true;
		if (AIError.GetLastError() == AITile.ERR_AREA_ALREADY_FLAT) return true;
		local tiles = AITileList();
		tiles.AddRectangle(tilestart, tileend);
		tiles = Assist.ListToArray(tiles);
		if (tiles.len() == 0) return;
		if (!Tiles.SetFlatHeight(tilestart, Tiles.AverageHeight(tiles))) return false;
		if (Debug.ResultOf("Level tiles[2]", AITile.LevelTiles(tilestart, tileend))) return true;
		if (AIError.GetLastError() == AITile.ERR_AREA_ALREADY_FLAT) return true;
		Assist.Valuate(Assist.ArrayToList(tiles), Tiles.SetFlatHeight, Tiles.AverageHeight(tiles));
		if (Debug.ResultOf("Level tiles[3]", AITile.LevelTiles(tilestart, tileend))) return true;
		if (AIError.GetLastError() == AITile.ERR_AREA_ALREADY_FLAT) return true;
    }

	/**
	 * Check if tiles is can leveled 
	 * @return true if AREA_ALREADY_FLAT
	*/
	static function IsLevel(tilestart, tileend)
	{
		if (AITile.GetSlope(tilestart)) return false;
		local tiles = AITileList();
		tiles.AddRectangle(tilestart, tileend);
		foreach (idx, val in tiles) if (AITile.GetSlope(idx)) return false;
		return true;
	}

    /**
     * Get tiles that influenced by this town
     * @param townID The town to check
     * @param area AITileList of an area to filter
     * @param yes Wether to inverse this function
     * @return Tiles that have influence rating by this townID
     */
    static function OfTown(townID, areas, yes = 1)
    {
		local area = areas;
        area.Valuate(AITile.IsWithinTownInfluence, townID);
        area.KeepValue(yes);
        return area;
    }

    /**
    * Check if these tile is road or buildable
    * @param tile tile to check
    * @return True if it was road or buildable
    */
    static function IsRoadBuildable(tile)
    {
        return AITile.IsBuildable(tile) || AIRoad.IsRoadTile(tile);
    }

    /**
    * Get tile list of my station arround base
    * @param base the center of area
    * @return AITileList of my station arround base
    */
    static function StationOn(base)
    {
        local area = Tiles.Radius(base, 10);
        area.Valuate(Tiles.IsMine);
        area.KeepValue(1);
        area.Valuate(AITile.IsStationTile);
        area.RemoveValue(0);
        area.Valuate(AIMap.DistanceMax, base);
        area.Sort(AIAbstractList.SORT_BY_VALUE, true);
        return area;
    }

    /** Set the tile flat on height
     * @param tile to set
     * @param height of tile to set
     * @return true if tile is flat and on that height
     */
    static function SetFlatHeight(tile, height)
    {
		local max_h = 0;
		local slope = 0;
		local do_cmd = null;
		local info = "";
		/*
		API would never return these :

		local SLOPE_HALFTILE = 32;
        local SLOPE_HALFTILE_MASK = 244;
        local SLOPE_HALFTILE_W = SLOPE_HALFTILE || (0 << 6);
        local SLOPE_HALFTILE_S = SLOPE_HALFTILE || (1 << 6);
        local SLOPE_HALFTILE_E = SLOPE_HALFTILE || (2 << 6);
        local SLOPE_HALFTILE_N = SLOPE_HALFTILE || (3 << 6);
		*/
        while (AIMap.IsValidTile(tile)) {
			max_h = AITile.GetMaxHeight(tile);
			slope = AITile.GetSlope(tile);
			do_cmd = AITile.RaiseTile;
			info = "Raising ";
			if (slope == AITile.SLOPE_FLAT && max_h == height) return true;
            local c = Debug.Sign(tile,"t");
            local to_slope = 0;
            AILog.Info("Height=" + max_h + "Target=" + height);
            local lowering = max_h > height;
			if (lowering) {
				do_cmd =  AITile.LowerTile;
				info = "Lowering ";
			}
            if (AITile.IsSteepSlope(slope)) {
                switch (slope) {
                    case AITile.SLOPE_STEEP_W :
                        to_slope = lowering ? AITile.SLOPE_E : AITile.SLOPE_W;
                        break;
                    case AITile.SLOPE_STEEP_S :
                        to_slope = lowering ? AITile.SLOPE_N : AITile.SLOPE_S;
                        break;
                    case AITile.SLOPE_STEEP_E :
                        to_slope = lowering ? AITile.SLOPE_W : AITile.SLOPE_E;
                        break;
                    case AITile.SLOPE_STEEP_N :
                        to_slope = lowering ? AITile.SLOPE_S : AITile.SLOPE_N;
                        break;
                    default :
                        Debug.Sign(tile, "Invalid steep");
                        Debug.DontCallMe("Invalid steep slope", slope);
                }
            } else if (AITile.IsHalftileSlope(slope)) {
				Debug.DontCallMe("API should not return Half Tile Slope", slope);
                switch (slope) {
                    case SLOPE_HALFTILE_W :
                    case SLOPE_HALFTILE_S :
                    case SLOPE_HALFTILE_E :
                    case SLOPE_HALFTILE_N :
                    default :
                        Debug.DontCallMe("Invalid half slope", slope);
                }

            } else {
                /* now, we have no Half nor Steep tile */
                if (lowering) {
                    if (slope && AITile.SLOPE_W == AITile.SLOPE_W) to_slope = to_slope || AITile.SLOPE_W;
                    if (slope && AITile.SLOPE_S == AITile.SLOPE_S) to_slope = to_slope || AITile.SLOPE_S;
                    if (slope && AITile.SLOPE_E == AITile.SLOPE_E) to_slope = to_slope || AITile.SLOPE_E;
                    if (slope && AITile.SLOPE_N == AITile.SLOPE_N) to_slope = to_slope || AITile.SLOPE_N;
                } else {
                    to_slope = AITile.GetComplementSlope(slope);
                }
            }
            if (!Debug.ResultOf("Try to " + info, do_cmd(tile, to_slope) == 1)) break;
        }
        return false;
    }
    
    static function FrontMore(body, head, num =1)
	{
		if (Tiles.NE_Of(body) == head) return Tiles.NE_Of(head, num);
		if (Tiles.NW_Of(body) == head) return Tiles.NW_Of(head, num);
		if (Tiles.SE_Of(body) == head) return Tiles.SE_Of(head, num);
		if (Tiles.SW_Of(body) == head) return Tiles.SW_Of(head, num);
	}
}
