 /**
 *      09.02.05
 *      tile.nut
 *      
 *      Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *      
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *      
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */
 
/**
* Tile Static functions
*/
class Tile 
{
	constructor() {}
	/**
	* 
	* name: N_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' North of 'tile' 
	*/
	static function N_Of(tile, num = 1);
	
	/**
	* 
	* name: W_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' West of 'tile' 
	*/
	static function W_Of(tile, num = 1);
	
	/**
	* 
	* name: S_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' South of 'tile' 
	*/
	static function S_Of(tile, num = 1) ;
	
	/**
	* 
	* name: E_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' East of 'tile' 
	*/
	static function E_Of(tile, num = 1) ;
	
	/**
	* 
	* name: NE_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' North East of 'tile' 
	*/
	static function NE_Of(tile, num = 1);
	
	/**
	* 
	* name: SE_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' South East of 'tile' 
	*/
	static function SE_Of(tile, num = 1);
	
	/**
	* 
	* name: NW_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' North West of 'tile' 
	*/
	static function NW_Of(tile,  num = 1);
	
	/**
	* 
	* name: N_Of
	* @param tile tile to check
	* @param num number of tile from 'tile'
	* @return amount 'num' South West of 'tile' 
	*/
	static function SW_Of(tile,  num = 1) ;
	
  /**
  * 
  * name: Adjacent
  * @param tile tile to check
  * @return Adjacent of 'tile' in 4 direction
  */
	static function Adjacent(tile) ;
	
  /**
  *  
  * name: Radius
  * @param tile center of tile 
  * @param rad_X radius of area to get by X axis
  * @param rad_Y radius of area to get by Y axis
  * @return  tiles of "radius" from "tile" 
  * @note leave undefined rad_Y to get squared area
  */
  static function Radius(tile, rad_X, rad_Y = null);
  
  /**
  *  
  * name: Radius_N
  * @param tile center of tile 
  * @param rad_X radius of area to get by X axis
  * @param rad_Y radius of area to get by Y axis
  * @return  tiles of "radius" from North of "tile" 
  * @note use negative value to get South of tile
  * @note leave undefined rad_Y to get squared area
  */
  static function Radius_N(tile, rad_X, rad_Y = null);
  
  /**
  *  
  * name: Radius
  * @param tile center of tile 
  * @param rad_X radius of area to get by X axis
  * @param rad_Y radius of area to get by Y axis
  * @return  tiles of "radius" from West of "tile" 
  * @note use negative value to get East of tile
  * @note leave undefined rad_Y to get squared area
  */
  static function Radius_W(tile, rad_X, rad_Y = null);
  
	/**
 	* 
 	* name: Validated
 	* @param tiles tiles to validate
 	* @return validated tiles of 'tiles'
 	*/
  static function Validated(tiles);
  
  /**
  * 
  * name: IsMine
  * @param tile 'tile to check 
  * @return true if "tile" is mine and it's not a road
  */
	static function IsMine(tile);
	
	/**
 	* 
 	* name: Roads
 	* @param tiles area of tiles to filter
 	* @return the road tiles of 'tiles'
 	*/
	static function Roads(tiles);
	
	/**
 	* 
 	* name: Buildable
 	* @param tiles area of tiles to filter
 	* @return the buildable tiles of 'tiles'
 	*/
	static function Buildable(tiles);
  
  /**
  * 
  * name: WholeMap
  * @return Whole Map Tile List
  */
	static function WholeMap();
	
	/**
  * 
  * name: Flat
  * @param tiles area of tiles to filter
  * @return Flat Tile List
  */
	static function Flat(tiles);
	
/**
* Check if I can demolish a Tile using test mode
* @param tile to demolish
* @return true if can demolish that tile
*/
static function CanDemolish(tile);


/**
* Get Ignorance tile while path finding
* @param none
* @return AITileList()
*/
static function ToIgnore();
}

function Tile::N_Of(tile, num = 1) 
{
  return tile + AIMap.GetTileIndex(-num, -num);
}

function Tile::W_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(num, -num);
}

function Tile::S_Of(tile, num = 1) 
{
  return tile + AIMap.GetTileIndex(num, num);
}

function Tile::E_Of(tile, num = 1) 
{
  return tile + AIMap.GetTileIndex(-num, num);
}

function Tile::NE_Of(tile, num = 1) 
{
  return tile + AIMap.GetTileIndex(-num, 0);
}

function Tile::SE_Of(tile, num = 1) 
{
  return tile + AIMap.GetTileIndex(0, num);
}

function Tile::NW_Of(tile,  num = 1) 
{
  return tile + AIMap.GetTileIndex(0, -num);
}

function Tile::SW_Of(tile,  num = 1) 
{
  return tile + AIMap.GetTileIndex(num, 0);
}

function Tile::Adjacent(tile) 
{
	local adjacen = AITileList();
	adjacen.AddTile(Tile.NE_Of(tile));
	adjacen.AddTile(Tile.NW_Of(tile));
	adjacen.AddTile(Tile.SW_Of(tile));
	adjacen.AddTile(Tile.SE_Of(tile));
	return adjacen;
}

function Tile::Radius(tile, rad_X, rad_Y = null) 
{
	local area = Tile.Radius_N(tile, rad_X, rad_Y);
	area.AddList(Tile.Radius_N(tile, -rad_X, rad_Y));
	area.AddList(Tile.Radius_W(tile, rad_X, rad_Y));
	area.AddList(Tile.Radius_W(tile, -rad_X, rad_Y));
	area.Sort(AIAbstractList.SORT_BY_ITEM, true);
	return area;
}

function Tile::Radius_N(tile, rad_X, rad_Y = null)
{
  rad_Y = (rad_Y == null) ? rad_X : rad_Y;
	local area = AITileList();
	area.AddRectangle(tile, tile - AIMap.GetTileIndex(rad_X, rad_Y));
	return area;
}

function Tile::Radius_W(tile, rad_X, rad_Y = null)
{
  rad_Y = (rad_Y == null) ? rad_X : rad_Y;
	local area = AITileList();
	area.AddRectangle(tile, tile + AIMap.GetTileIndex(rad_X, -rad_Y));
	return area;
}

function Tile::Validated(tiles) 
{
	tiles.Valuate(AIMap.IsValidTile);
	tiles.KeepValue(1);
	return tiles;
}

function Tile::IsMine(tile)
{
	return  AICompany.IsMine(AITile.GetOwner(tile)) && !AIRoad.IsRoadTile(tile);
}

function Tile::Buildable(tiles, yes = 1)
{
	tiles.Valuate(AITile.IsBuildable);
	tiles.KeepValue(yes);
	return tiles;
}

function Tile::Roads(tiles, yes = 1) 
{
	tiles.Valuate(AIRoad.IsRoadTile);
	tiles.KeepValue(yes);
	return tiles;
}

function Tile::WholeMap()
{
	local loc = AITileList();
	loc.AddRectangle(AIMap.GetTileIndex(2, 2),AIMap.GetTileIndex(AIMap.GetMapSizeX() - 2, AIMap.GetMapSizeY() - 2));
	return loc;
}

function Tile::Flat(tiles)
{
  tiles.Valuate(AITile.GetSlope);
  tiles.KeepValue(AITile.SLOPE_FLAT);
	return tiles;
}

// Return not water tiles
function Tile::Waters(area, yes = 1) 
{
	area.Valuate(AITile.IsWaterTile);
	area.KeepValue(yes);
	return area;
}
// =======================================
// Get the body of "head" depot/station tile
function Tile::BodiesOf(head)
{
	return Tile.Roads(Tile.Waters(Tile.Adjacent(head), 0), 0);;
}
// =======================================
// Get tile of My depots arround "base"
function Tile::RoadDepot(base) 
{
	local area = Tile.Radius(base,10);
	area.Valuate(Tile.IsMine);
	area.RemoveValue(0);
	area.Valuate(AIRoad.IsRoadDepotTile);
	area.RemoveValue(0);
  area.Valuate(AITile.GetDistanceManhattanToTile, base);
  area.Sort(AIAbstractList.SORT_BY_VALUE, true);
	return area;
}

function Tile::RailDepot(base) 
{
	local area = Tile.Radius(base,10);
	area.Valuate(Tile.IsMine);
	area.RemoveValue(0);
	area.Valuate(AIRail.IsRailDepotTile);
	area.RemoveValue(0);
  area.Valuate(AITile.GetDistanceManhattanToTile, base);
  area.Sort(AIAbstractList.SORT_BY_VALUE, true);
	return area;
}

function Tile::GoodSource(tiles, cargoID)
{
	tiles.Valuate(AITile.GetCargoProduction,cargoID,1,1,RoadStationRadius(RoadStationOf(cargoID)));
	tiles.KeepAboveValue(8);
  return tiles;
}

function Tile::GoodAccept(tiles, cargoID)
{
	tiles.Valuate(AITile.GetCargoAcceptance,cargoID,1,1,RoadStationRadius(RoadStationOf(cargoID)));
	tiles.KeepAboveValue(8);
	return tiles;
}

function Tile::IsStraight(tile1, tile2) return (Tile.IsStraightX(tile1,tile2) || Tile.IsStraightY(tile1,tile2));
function Tile::IsStraightX(tile1, tile2) return AIMap.GetTileX(tile1) == AIMap.GetTileX(tile2);
function Tile::IsStraightY(tile1, tile2) return AIMap.GetTileY(tile1) == AIMap.GetTileY(tile2);

function Tile::CanDemolish(tile)
{
  local at = AITestMode();
  return AITile.DemolishTile(tile);
}

function Tile::ToIgnore()
{
  local b = Tile.WholeMap();
  local c = Tile.Buildable(b, 0);
  local r = Tile.Roads(c, 0);
  return r;
}
