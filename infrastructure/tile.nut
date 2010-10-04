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
    static function N_Of(tile, num)
    {
      return tile + AIMap.GetTileIndex(-num, -num);
    }

    /**
    * Get West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' West of 'tile'
    */
    static function W_Of(tile, num)
    {
      return tile + AIMap.GetTileIndex(num, -num);
    }

    /**
    * Get South tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South of 'tile'
    */
    static function S_Of(tile, num)
    {
      return tile + AIMap.GetTileIndex(num, num);
    }

    /**
    * Get East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' East of 'tile'
    */
    static function E_Of(tile, num)
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
    static function NE_Of(tile, num)
    {
      return tile + AIMap.GetTileIndex(-num, 0);
    }

    /**
    * Get  North West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' North West of 'tile'
    */
    static function NW_Of(tile,  num)
    {
      return tile + AIMap.GetTileIndex(0, -num);
    }

    /**
    * Get  South East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South East of 'tile'
    */
    static function SE_Of(tile, num)
    {
      return tile + AIMap.GetTileIndex(0, num);
    }

    /**
    * Get  South West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South West of 'tile'
    */
    static function SW_Of(tile,  num)
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
        adjacen.AddTile(Tiles.NE_Of(tile, 1));
        adjacen.AddTile(Tiles.NW_Of(tile, 1));
        adjacen.AddTile(Tiles.SW_Of(tile, 1));
        adjacen.AddTile(Tiles.SE_Of(tile, 1));
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
    * Get tiles of an area in number of radius
    * @param tile center of tile
    * @param rad_X radius of area to get by X axis
    * @param rad_Y radius of area to get by Y axis
    * @return  tiles of "radius" from "tile"
    * @note leave undefined rad_Y to get squared area
    */
    static function Radius(tile, rad_X, rad_Y)
    {
        local area = Tiles.Radius_N(tile, rad_X, rad_Y);
        area.AddList(Tiles.Radius_N(tile, -rad_X, -rad_Y));
        area.AddList(Tiles.Radius_W(tile, rad_X, rad_Y));
        area.AddList(Tiles.Radius_W(tile, -rad_X, -rad_Y));
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
    static function Radius_N(tile, rad_X, rad_Y)
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
    static function Radius_W(tile, rad_X, rad_Y)
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
    static function Roads(tiles, yes)
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
    static function Buildable(tiles, yes)
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
        tile.Valuate(Tiles.IsFlat);
        tile.KeepValue(1);
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
    static function DepotOn(base, rad)
    {
        local area = Tiles.Radius(base, rad, rad);
        area.Valuate(Tiles.IsMine);
        area.KeepValue(1);
        area.Valuate(Tiles.IsDepotTile);
        area.KeepValue(1);
        area.Valuate(AIMap.DistanceManhattan, base);
        area.Sort(AIAbstractList.SORT_BY_VALUE, true);
        return area;
    }

    /**
    * Get water tiles of  area
    * @param area AITileList of an area
    * @param yes a Value to keep
    * @return  Water tiles of an area
    */
    static function Waters(area, yes)
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
		local tiles = AITileList();
		tiles.AddRectangle(tilestart, tileend);
		tiles = Tiles.Validated(tiles);
		if (tiles.IsEmpty()) return;
		local target_h = Tiles.ModusHeight(tiles);
		foreach (tile , val in tiles) if (!Tiles.SetFlatHeight(tile, target_h)) return;
		AILog.Info("Level tiles[1] passed");
		if (Tiles.IsLevel(tilestart, tileend)) return true;
		Debug.ResultOf("Level tiles[2]", AITile.LevelTiles(tilestart, tileend));
		foreach (tile , val in tiles) if (!Tiles.SetFlatHeight(tile, target_h)) return;
		AILog.Info("Level tiles[2] passed");
		return true;
    }

	/**
	 * Check if tiles is can leveled 
	 * @return true if have no slope
	*/
	static function IsLevel(tilestart, tileend)
	{
		local tiles = AITileList();
		tiles.AddRectangle(tilestart, tileend);
		foreach (idx, val in tiles) if (!Tiles.IsFlat(idx)) return false;
		return true;
	}

    /**
     * Get tiles that influenced by this town
     * @param townID The town to check
     * @param area AITileList of an area to filter
     * @param yes Wether to inverse this function
     * @return Tiles that have influence rating by this townID
     */
    static function OfTown(townID, areas, yes)
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
    * @return AIList of my station ID arround base
    */
    static function StationOn(base)
    {
        local area = Tiles.Radius(base, 12, 12);
        area.Valuate(Tiles.IsMine);
        area.KeepValue(1);
        area.Valuate(AITile.IsStationTile);
        area.RemoveValue(0);
        area.Valuate(AIMap.DistanceManhattan, base);
        area.Sort(AIAbstractList.SORT_BY_VALUE, true);
        local list = AIList();
        foreach (idx, val in area) {
        	local id = AIStation.GetStationID(idx);
        	if (!AIStation.IsValidStation(id)) continue;
        	list.AddItem(id, list.GetValue(id) + 1);
        }
        return area;
    }

    /** Set the tile flat on height
     * @param tile to set
     * @param height of tile to set
     * @return true if tile is flat and on that height
     */
    static function SetFlatHeight(tile, height)
    {
    	if (!AIMap.IsValidTile(tile)) return 0;
		local max_h = AITile.GetMaxHeight(tile);
		//if (Tiles.IsFlat(tile) && max_h == height) return 1;
		local slope = AITile.GetSlope(tile);
		local c = Debug.Sign(tile,"t");
		//AILog.Info("Max.H:" + max_h + " Target:" + height);
		foreach (corn in Const.Corner) {
			if (AITile.GetCornerHeight(tile, corn) == height) continue;
			if (AITile.GetCornerHeight(tile, corn) < height) {
				if (AITile.RaiseTile(tile, 1 << corn)) continue;
				return 0;
			}
			if (AITile.GetCornerHeight(tile, corn) > height) {
				if (AITile.LowerTile(tile, 1 << corn)) continue;
				return 0;
			}
			Debug.DontCallMe("should not reached", tile);
		}
		Debug.UnSign(c);
		return 1;
    }
    
    static function FrontMore(body, head, num)
	{
		if (Tiles.NE_Of(body, 1) == head) return Tiles.NE_Of(head, num);
		if (Tiles.NW_Of(body, 1) == head) return Tiles.NW_Of(head, num);
		if (Tiles.SE_Of(body, 1) == head) return Tiles.SE_Of(head, num);
		if (Tiles.SW_Of(body, 1) == head) return Tiles.SW_Of(head, num);
	}
	
	static function IsBuildableRange(start_t, end_t)
	{
		local tiles = AITileList();
		if (!AIMap.IsValidTile(start_t)) return false;
		if (!AIMap.IsValidTile(end_t)) return false;
		tiles.AddRectangle(start_t, end_t);
		foreach (idx, val in tiles) {
			if (!AITile.IsBuildable(idx)) return false;
			if (Tiles.IsMine(idx)) return false;
		}
		return true;
	}
	
	static function IsFlat(idx)
	{
		local slope = AITile.GetSlope(idx);
		if (slope == 0) return true;
		if (TransAI.Setting.Get(Const.Settings.build_on_slopes) && (slope == AITile.SLOPE_NWS || 
			slope == AITile.SLOPE_WSE || slope == AITile.SLOPE_SEN || 
			slope == AITile.SLOPE_ENW)) return true;
		return false;
	}
	
	static function IsAutoFlat(current, next)
	{
		local slope = AITile.GetSlope(current);
		if (slope == 0) return true;
		if (!TransAI.Settings.Get(Const.Settings.autoslope)) return;
		//Set to true if we want to go to the north-west
		local NW = Tiles.NW_Of(current, 1) == next;
		//Set to true if we want to go to the north-east
		local NE = Tiles.NE_Of(current, 1) == next;
		//Set to true if we want to go to the south-west 
		local SW = Tiles.SW_Of(current, 1) == next;
		//Set to true if we want to go to the south-east
		local SE = Tiles.SE_Of(current, 1) == next;
		
		if ((NW || SE) && (slope == AITile.SLOPE_NE || slope == AITile.SLOPE_SW)) return true;
		if ((NE || SW) && (slope == AITile.SLOPE_NW || slope == AITile.SLOPE_SE)) return true;
	}
	
	static function MostHeight(idx)
	{
		local tmp = [];
		foreach (corn in Const.Corner) tmp.push(AITile.GetCornerHeight(idx, corn));
		return Assist.Modus(tmp);
	}
	
	static function ModusHeight(tilelist)
	{
		return Assist.Modus(Assist.ValuateToArray(tilelist, Tiles.MostHeight));
	}
}
