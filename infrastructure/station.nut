/*  09.06.23 - station.nut
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
 * Station object
 */
class Station extends Infrastructure
{
	constructor(name)
	{
		::Infrastructure.constructor(name);
		this._storage._width <- -1; ///< Station width
		this._storage._length <- -1; ///< Station length
		this._storage._direction <- -1; ///< Station direction
		this._storage._area <- []; ///< Array of tile area in use
		this._storage._path_entry <- []; ///< Array of path entry
		this._storage._path_exit <- []; ///< Array of path exit
		this._storage._is_drop_station <- false; ///< Flag a drop off point
		this._storage._station_type <- -1; //type station (bus, truck, small, big)
		this._storage._data <- {}; // Data of station
	}

	/**
	 * Creates a list of vehicles that have orders to this station.
	 */
	function GetVehicleList() { return AIVehicleList_Station(this.GetID()); }

	/**
	 * @return true if has one of AIStation::StationType
	 * Type of stations known in the game.
	 * STATION_TRAIN Train station.
	 * STATION_TRUCK_STOP Truck station.
	 * STATION_BUS_STOP Bus station.
	 * STATION_AIRPORT Airport.
	 * STATION_DOCK Dock.
	 * STATION_ANY All station types.
	 */
	function HasStationType(val) { return AIStation.HasStationType(this._id, val); }
	
	/**
	 * Get the coverage radius of this type of station. 
	 */
	function GetRadius() { return AIStation.GetCoverageRadius(this._storage._station_type); }

	/**
	 * See how much cargo there is waiting on a station.
	 */
	function GetCargoWaiting (cargo_id) { return AIStation.GetCargoWaiting( this._id, cargo_id); }

	/**
	 * See how high the rating is of a cargo on a station.
	 */
	function GetCargoRating (cargo_id) { return AIStation.GetCargoRating(this._id, cargo_id); }

	/**
	 * Get the manhattan distance from the tile to the AIStation::GetLocation() of the station.
	 */
	function GetDistanceManhattanToTile(tile) { return AIStation.GetDistanceManhattanToTile(this._id, tile); }

	/**
	 * Check if can build distant/join/adjacent/nonuniform station
	 * actually I'm still confuse with this term
	 */
	function CanBuildJoint()
	{
		return Settings.Get(Const.Settings.distant_join_stations) || Settings.Get(Settings.game.adjacent_stations) ||
		Settings.Get(Const.Settings.distant_join_stations);
	}

	function GetLength() {return this._storage._length;}
	function GetWidth() {return this._storage._width;}
	function GetDirection() {return this._storage._direction;}
	function SetLength(val) { this._storage._length = val;}
	function SetWidth(val) { this._storage._width = val;}
	function SetDirection(val) { this._storage._direction = val;}
	
	/** Get area stored as TileList
	 * @return AITileList of stored area
	 */
	function GetArea() 
	{
		local val = Assist.ArrayToList(this._storage._area);
		val.Sort(AIAbstractList.SORT_BY_ITEM, true);  
		return val;
	}
	
	/** Set tile area of station
	 * @param tilestart Starting TileID
	 * @param tileend Ending Tile ID
	 */
	function SetArea(tilestart, tileend) 
	{
		local val = AITileList().AddRectangle(tilestart, tileend);
		val = Assist.ListToArray(val);
		this._storage._area = val; 
	}
	
	function GetStationType() { return this._storage._station_type; }
	function SetStationType(type) { this._storage._station_type = type; }
	function IsDropOff() { return this._storage._is_drop_station; }
	function SetDropOff(val) { this._storage._is_drop_station = val; }
	function GetData() { return this._storage._data; }
	function SetData(val) { this._storage._data = val; }
	
	/**
	 * Can we build a station on
	 * @param top Most top-left of location
	 * @param x Width of station
	 * @param y Height of station
	 * @return 0 = can't build. 1 maybe can with tf. 2 can w/o tf
	 */
	static function CanBuild(from, to) {
		if (!Tiles.IsBuildableRange(from, to)) return 0;
		local tiles = AITileList();
		tiles.AddRectangle(from, to);
		local h = Tiles.ModusHeight(tiles);
		if (h == 0) return 0;
		if (Tiles.IsLevel(from, to)) return 2;
		foreach (tile , val in tiles) if (!Tiles.SetFlatHeight(tile, h)) return 0;
		return 1;
	}
	
	static function GetPlatform(x_width, y_height)
	{
		local area = [];
		for (local y = 0; y < y_height; y++) {
			for (local x = 0; x < x_width; x++) {
				area.push(AIMap.GetTileIndex(x, y));
			}
		}
		return area;
	}
	
	static function GetPath(list, arraynumber, base)
	{
		local Path = T_AyStar.Path;
		local fpath = null;
		while (arraynumber.len()) {
			local num = arraynumber.pop();
			fpath = Path(fpath, base + list[num] , null, function(a,b,c,d) {}, null);
		}
		return fpath;
	}
	
	
	static function FindLastTile(start, dir, is_front, num)
    {
    	local tmp = start;
        if (!AIRail.IsRailStationTile(tmp)) return -1;
        local func = null;
        switch (dir)
        {
            case AIRail.RAILTRACK_NE_SW : func = is_front ? Tiles.NE_Of : Tiles.SW_Of; break;
            case AIRail.RAILTRACK_NW_SE : func = is_front ? Tiles.NW_Of : Tiles.SE_Of; break;
            default : Debug.DontCallMe("FindLastTile:" + is_front + " front", dir);
        }
        while (AIRail.IsRailStationTile(func(tmp))) tmp = func(tmp);
        if (num == 0) return tmp;
        return func(tmp, num);
    }

    static function RailTemplateNE_SW(base)
    {
        local to_build = [1, 2, 3, 7, 14, 18, 19, 20];
        local nese = [2, 8];
        local nwsw = [13, 19];
        local signal = [[3, 2], [7, 8], [14, 15], [18, 19]];
        local door = [[1, 2], [20, 21]];
        local _tmp = -1;
        while (to_build.len() > 0) {
            local c = to_build.pop();
            local x = c % 11;
            local y = (c - x) / 11;
            local tile = base + AIMap.GetTileIndex(x, y);
            if (!AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NE_SW) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
        while (nese.len() > 0) {
            local c = nese.pop();
            local x = c % 11;
            local y = (c - x) / 11;
            local tile = base + AIMap.GetTileIndex(x, y);
            if (!AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NE_SE) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
        while (nwsw.len() > 0) {
            local c = nwsw.pop();
            local x = c % 11;
            local y = (c - x) / 11;
            local tile = base + AIMap.GetTileIndex(x, y);
            if (!AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_SW) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
        while (signal.len() > 0) {
            local c = signal.pop();
            local x = c[0] % 11;
            local y = (c[0] - x) / 11;
            local xf = c[1] % 11;
            local yf = (c[1] - xf) / 11;
            if (!AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_EXIT_TWOWAY)) return false;
        }
        while (door.len() > 0) {
            local c = door.pop();
            local x = c[0] % 11;
            local y = (c[0] - x) / 11;
            local xf = c[1] % 11;
            local yf = (c[1] - xf) / 11;
            if (!AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_ENTRY_TWOWAY)) return false;
        }
        return true;
    }

    static function RailTemplateNW_SE(base)
    {
        local to_build = [3, 5, 6, 7, 14, 15, 16, 18];
        local swse = [4, 16];
        local nenw = [5, 17];
        local signal = [[6, 4], [7, 5], [14, 16], [15, 17]];
        local door = [[3, 5], [18, 16]];
        local _tmp = -1;
        while (to_build.len() > 0) {
            local c = to_build.pop();
            local x = c % 2;
            local y = (c - x) / 2;
            local tile = base + AIMap.GetTileIndex(x, y);
            if (!AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_SE) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
        while (nenw.len() > 0) {
            local c = nenw.pop();
            local x = c % 2;
            local y = (c - x) / 2;
            local tile = base + AIMap.GetTileIndex(x, y);
		if (!AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_NE) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
        while (swse.len() > 0) {
            local c = swse.pop();
            local x = c % 2;
            local y = (c - x) / 2;
            local tile = base + AIMap.GetTileIndex(x, y);
            if (!AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_SW_SE) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
        while (signal.len() > 0) {
            local c = signal.pop();
            local x = c[0] % 2;
            local y = (c[0] - x) / 2;
            local xf = c[1] % 2;
            local yf = (c[1] - xf) / 2;
            if (!AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_EXIT_TWOWAY)) return false;
        }
        while (door.len() > 0) {
            local c = door.pop();
            local x = c[0] % 2;
            local y = (c[0] - x) / 2;
            local xf = c[1] % 2;
            local yf = (c[1] - xf) / 2;
            if (!AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_ENTRY_TWOWAY)) return false;
        }
        return true;
    }
}

/**
 * Road Station class
 */
class RoadStation extends Station
 {
 	constructor()
 	{
 		::Station.constructor("RoadStation");
		this.SetV_Type(AIVehicle.VT_ROAD);
 	}

	/**
	 * @return true if can build DTRS
	 */
	function CanBuildDTRS() {
		return Settings.Get(Const.dtrs_on_town) || Settings.Get(Const.dtrs_on_competitor);
	}
}

class AirStation extends Station
{
	constructor()
	{
		::Station.constructor("AirStation");
	}
}

class WaterStation extends Station
{
	constructor()
	{
		::Station.constructor("WaterStation");
	}
}

/**
 * Rail Station class
 */
class RailStation extends Station
{
	constructor()
	{
		::Station.constructor("RailStation");
		this.SetV_Type(AIVehicle.VT_RAIL);
		this.SetStationType(AIStation.STATION_TRAIN);
	}
	
	function BuildFace(path)
	{
		local prev = null;
		local prevprev = null;
		local c = 2;
		while (path != null) {
			if (prevprev != null) {	
				AIRail.BuildRail(prevprev, prev, path.GetTile());
				if (c % 2 == 0) {
					if (AIRail.BuildSignal(prev, path.GetTile(), AIRail.SIGNALTYPE_EXIT_TWOWAY)) c++;
				}
			}
			if (path != null) {
				prevprev = prev;
				prev = path.GetTile();
				path = path.GetParent();
			}
		}
	}
	
	function BuildSignal(path, head)
	{
		while (path) {
			local parn = path.GetParent();
			if (parn != null && (AIRail.GetSignalType(path.GetTile(),path.GetTile() + head) == AIRail.SIGNALTYPE_NONE)) {
				AIRail.BuildSignal(path.GetTile(), parn.GetTile(), AIRail.SIGNALTYPE_EXIT_TWOWAY);
			}
			if (path != null) {
				path = parn;
			}
		}
	}
}
