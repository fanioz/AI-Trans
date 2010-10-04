 /*
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
class Tiles
{

    /**
    *
    * Get North tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' North of 'tile'
    */
    static function N_Of(tile, num = 1);

    /**
    *
    * Get West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' West of 'tile'
    */
    static function W_Of(tile, num = 1);

    /**
    *
    * Get South tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South of 'tile'
    */
    static function S_Of(tile, num = 1) ;

    /**
    *
    * Get East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' East of 'tile'
    */
    static function E_Of(tile, num = 1) ;

    /**
    *
    * Get North East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' North East of 'tile'
    */
    static function NE_Of(tile, num = 1);

    /**
    *
    * Get  South East tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South East of 'tile'
    */
    static function SE_Of(tile, num = 1);

    /**
    *
    * Get  North West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' North West of 'tile'
    */
    static function NW_Of(tile,  num = 1);

    /**
    *
    * Get  South West tile(s) Of a tile
    * @param tile tile to check
    * @param num number of tile from 'tile'
    * @return amount 'num' South West of 'tile'
    */
    static function SW_Of(tile,  num = 1) ;

    /**
    *
    * Get adjacent tiles of a tile
    * @param tile tile to check
    * @return Adjacent of 'tile' in 4 direction
    */
    static function Adjacent(tile) ;

    /**
    *
    * Get tiles of an area in number of radius
    * @param tile center of tile
    * @param rad_X radius of area to get by X axis
    * @param rad_Y radius of area to get by Y axis
    * @return  tiles of "radius" from "tile"
    * @note leave undefined rad_Y to get squared area
    */
    static function Radius(tile, rad_X, rad_Y = null);

    /**
    *
    * Get North tiles of an area in number of radius
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
    * Get West tiles of an area in number of radius
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
    * Get Validated tiles of area
    * @param tiles tiles to validate
    * @return validated tiles of 'tiles'
    */
    static function Validated(tiles);

    /**
    *
    * Check if tile is mine
    * @param tile 'tile to check
    * @return true if "tile" is mine and it's not a road
    */
    static function IsMine(tile);

    /**
    *
    * Get Roads tiles of area
    * @param tiles area of tiles to filter
    * @param yes a Value to keep
    * @return the road tiles of 'tiles'
    */
    static function Roads(tiles, yes = 1);

    /**
    *
    * Get Buildable tiles of area
    * @param tiles area of tiles to filter
    * @param yes a Value to keep
    * @return the buildable tiles of 'tiles'
    */
    static function Buildable(tiles, yes = 1);

    /**
    *
    * Get the WholeMap tiles
    * @return Whole Map Tile List
    */
    static function WholeMap();

    /**
    *
    * Get Flattened tiles of area
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
    * @return Array of ignored tiles
    */
    static function ToIgnore();

    /**
    * Get water tiles of  area
    * @param area AITileList of an area
    * @param yes a Value to keep
    * @return  Water tiles of an area
    */
    static function Waters(area, yes = 1);

    /**
    * Check if a tile is good acceptance of certain cargo.
    * @param tile to check
    * @param cargoID of cargo to check acceptance
    * @return True if have acceptance above 6
    */
    static function IsGoodAccept(tile, cargoID);

    /**
    * Check if a tile is good production for certain cargo.
    * @param tile to check
    * @param cargoID of cargo to check production
    * @return True if have production above 8
    */
    static function IsGoodSource(tile, cargoID);

    /**
    * Get the body of "head" depot/station tile
    * @param head tile that become head
    * @return a non-water nor road AITileList that adjacent to the head
    */
    static function BodiesOf(head);

    /**
    * Check if these tile is in straight direction
    * @param tile_st first tile to check
    * @param tile_nd second tile check
    * @return True if they are straight, otherwise false
    */
    static function IsStraight(tile_st, tile_nd);

    /**
     * Get tiles that influenced by this town
     * @param townID The town to check
     * @param area AITileList of an area to filter
     * @param yes Wether to inverse this function
     * @return Tiles that have influence rating by this townID
     */
    static function OfTown(townID, area, yes = 1);

    /**
    * Check if these tile is road or buildable
    * @param tile tile to check
    * @return True if it was road or buildable
    */
    static function IsRoadBuildable(tile);

    /**
    * Get tile list of my station arround base
    * @param base the center of area
    * @return AITileList of my station arround base
    */
    static function StationOn(base);
}

function Tiles::N_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(-num, -num);
}

function Tiles::W_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(num, -num);
}

function Tiles::S_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(num, num);
}

function Tiles::E_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(-num, num);
}

function Tiles::NE_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(-num, 0);
}

function Tiles::SE_Of(tile, num = 1)
{
  return tile + AIMap.GetTileIndex(0, num);
}

function Tiles::NW_Of(tile,  num = 1)
{
  return tile + AIMap.GetTileIndex(0, -num);
}

function Tiles::SW_Of(tile,  num = 1)
{
  return tile + AIMap.GetTileIndex(num, 0);
}

function Tiles::Adjacent(tile)
{
    local adjacen = AITileList();
    adjacen.AddTile(Tiles.NE_Of(tile));
    adjacen.AddTile(Tiles.NW_Of(tile));
    adjacen.AddTile(Tiles.SW_Of(tile));
    adjacen.AddTile(Tiles.SE_Of(tile));
    return adjacen;
}

function Tiles::Radius(tile, rad_X, rad_Y = null)
{
    local area = Tiles.Radius_N(tile, rad_X, rad_Y);
    area.AddList(Tiles.Radius_N(tile, -rad_X, rad_Y));
    area.AddList(Tiles.Radius_W(tile, rad_X, rad_Y));
    area.AddList(Tiles.Radius_W(tile, -rad_X, rad_Y));
    area.Sort(AIAbstractList.SORT_BY_ITEM, true);
    return area;
}

function Tiles::Radius_N(tile, rad_X, rad_Y = null)
{
    rad_Y = (rad_Y == null) ? rad_X : rad_Y;
    local area = AITileList();
    area.AddRectangle(tile, tile - AIMap.GetTileIndex(rad_X, rad_Y));
    return area;
}

function Tiles::Radius_W(tile, rad_X, rad_Y = null)
{
    rad_Y = (rad_Y == null) ? rad_X : rad_Y;
    local area = AITileList();
    area.AddRectangle(tile, tile + AIMap.GetTileIndex(rad_X, -rad_Y));
    return area;
}

function Tiles::Validated(tiles)
{
    tiles.Valuate(AIMap.IsValidTile);
    tiles.KeepValue(1);
    return tiles;
}

function Tiles::IsMine(tile, non_road = true)
{
    local result = true;
    if (non_road) result = !AIRoad.IsRoadTile(tile);
    return  AICompany.IsMine(AITile.GetOwner(tile)) && result;
}

function Tiles::Buildable(tiles, yes = 1)
{
    local tilest = tiles;
    tilest.Valuate(AITile.IsBuildable);
    tilest.KeepValue(yes);
    return tilest;
}

function Tiles::Roads(tiles, yes = 1)
{
    tiles.Valuate(AIRoad.IsRoadTile);
    tiles.KeepValue(yes);
    return tiles;
}

function Tiles::WholeMap()
{
    local loc = AITileList();
    loc.AddRectangle(AIMap.GetTileIndex(1, 1),AIMap.GetTileIndex(AIMap.GetMapSizeX() - 2, AIMap.GetMapSizeY() - 2));
    return loc;
}

function Tiles::Flat(tiles)
{
    local tile = tiles;
    tile.Valuate(AITile.GetSlope);
    tile.KeepValue(AITile.SLOPE_FLAT);
    return tile;
}

function Tiles::Waters(area, yes = 1)
{
    local tiles = area;
    tiles.Valuate(AITile.IsWaterTile);
    tiles.KeepValue(yes);
    return tiles;
}

function Tiles::BodiesOf(head)
{
    return Tiles.Roads(Tiles.Waters(Tiles.Adjacent(head), 0), 0);;
}

function Tiles::DepotOn(base, rad = 10)
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

function Tiles::IsGoodSource(tile, cargoID, width = 1, height = 1)
{
  return (AITile.GetCargoProduction(tile, cargoID, width, height, 4) > 5);
}

function Tiles::IsGoodAccept(tile, cargoID, width = 1, height = 1)
{
    return (AITile.GetCargoAcceptance(tile, cargoID, width, height, 4) > 7);
}

function Tiles::IsStraight(tile_st, tile_nd)
{
    return (AIMap.GetTileX(tile_st) == AIMap.GetTileX(tile_nd))
        || (AIMap.GetTileY(tile_st) == AIMap.GetTileY(tile_nd));
}

function Tiles::CanDemolish(tile)
{
    local at = AITestMode();
    return AITile.DemolishTile(tile);
}

function Tiles::ToIgnore()
{
    local w = Tiles.Waters(Tiles.WholeMap());
    /*
    local result = [];
    foreach (idx, val in w) {
        AIController.Sleep(1);
        //if (AITile.IsBuildable(idx)) continue;
        //if (AIRoad.IsRoadTile(idx)) continue;
        //if (AIBridge.IsBridgeTile(idx)) continue;
        //if (AITunnel.IsTunnelTile(idx)) continue;
        result.push(idx);
    }
    */
    return Assist.ListToArray(w);
}

function Tiles::OfTown(townID, area, yes = 1)
{
    area.Valuate(AITile.IsWithinTownInfluence, townID);
    area.KeepValue(yes);
    return area;
}

function Tiles::IsRoadBuildable(tile)
{
    return AITile.IsBuildable(tile) || AIRoad.IsRoadTile(tile);
}

function Tiles::StationOn(base)
{
    local area = Tiles.Radius(base, 10);
    area.Valuate(AITile.GetOwner);
    area.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
    area.Valuate(AITile.IsStationTile);
    area.RemoveValue(0);
    area.Valuate(AIMap.DistanceMax, base);
    area.Sort(AIAbstractList.SORT_BY_VALUE, true);
    return area;
}

function Tiles::IsDepotTile(tile)
{
    return  (AIRoad.IsRoadDepotTile(tile) || AIRail.IsRailDepotTile(tile) ||
                AIAirport.IsHangarTile(tile) || AIMarine.IsWaterDepotTile(tile));
}

function Tiles::GetAdjacentHeight(tile)
{
    local tiles = [Tiles.N_Of, Tiles.E_Of, Tiles. W_Of, Tiles.S_Of];
    local bh = BinaryHeap();
    while (tiles.len() > 0) {
        local idx = tiles.pop();
        local x = idx(tile);
        local valu = 100 - AITile.GetHeight(x);
        if (AIMap.IsValidTile(x)) bh.Insert(x, valu);
    }
    return (bh.Count() > 0) ? AITile.GetHeight(bh.Peek()) : AITile.GetHeight(tile);
}

function Tiles::AverageHeight(tiles)
{
    local sam = 0, count = tiles.Count();
    if (count == 0) return AITile.GetHeight(tiles.Begin());
    for(local idx = tiles.Begin(); tiles.HasNext(); idx = tiles.Next()) {
        sam += AITile.GetHeight(idx);
    }
    local mod = sam % count;
    local rounded = (mod / count > 0.5) ? 1: 0;
    return (sam - mod) / count + rounded;
}

function Tiles::SetHeight(tile, height)
{
    local act_h = -1;
    local do_cmd = null;
    while (true) {
        //local c = Debug.Sign(tile, "t");
        act_h = Debug.ResultOf("Height/Actual:" + AITile.GetHeight(tile) , Tiles.GetAdjacentHeight(tile));
        local slope = AITile.GetSlope(tile);
        AILog.Info("target = " + height);
        if ((AITile.GetHeight(tile) == height) &&
            //(slope && AITile.SLOPE_STEEP != AITile.SLOPE_STEEP) &&
            (slope == AITile.SLOPE_FLAT || (slope && AITile.SLOPE_ELEVATED == AITile.SLOPE_ELEVATED))) break;
        if (act_h <= height) do_cmd = AITile.RaiseTile;
        if (act_h > height) do_cmd = AITile.LowerTile;
        local to_slope = -1;
        if ((slope && AITile.SLOPE_W == AITile.SLOPE_W) ||
            (slope == AITile.SLOPE_STEEP_E)) to_slope = AITile.SLOPE_W;
        if ((slope && AITile.SLOPE_N == AITile.SLOPE_N) ||
            (slope == AITile.SLOPE_STEEP_S)) to_slope = AITile.SLOPE_N;
        if ((slope && AITile.SLOPE_S == AITile.SLOPE_S) ||
            (slope == AITile.SLOPE_STEEP_N)) to_slope = AITile.SLOPE_S;
        if ((slope && AITile.SLOPE_E == AITile.SLOPE_E) ||
            (slope == AITile.SLOPE_STEEP_W)) to_slope = AITile.SLOPE_E;
        if (!do_cmd(tile, to_slope)) return false;
        //AISign.RemoveSign(c);
    }
    return true;
}

function Tiles::MakeLevel(tilestart, tileend)
{
    local tiles = AITileList();
    tiles.AddRectangle(tilestart, tileend);
    local target_h = Tiles.AverageHeight(tiles);
    foreach (idx, val in tiles) Tiles.SetHeight(idx, target_h);
    return AITile.LevelTiles(tilestart, tileend);
}
