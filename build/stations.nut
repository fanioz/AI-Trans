/*  09.04.19 - stations.nut
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
 *  Depot & Station
 */
class Stations
{
    id = null;
    length = null;
    width = null;
    direction = null;
    platform = null;
    constructor()
    {
        this.id = -1;
        this.length = -1;
        this.width = -1;
        this.direction = -1;
        this.platform = {};
        this.platform[0] <- Platform();
    }

    static function RoadFor(cargo_id)
    {
        if (AICargo.HasCargoClass(cargo_id, AICargo.CC_PASSENGERS)) return AIRoad.ROADVEHTYPE_BUS;
        return AIRoad.ROADVEHTYPE_TRUCK;
    }

    static function RoadRadius() {return AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP );}
    static function RailRadius() {return AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);}

    function GetID() {return this.id;}
    function GetLength() {return this.length;}
    function GetWidth() {return this.width;}
    function GetDirection() {return this.direction;}
    function GetPlatform(idx) {return this.platform[idx];}
    function SetID(val) {this.id = val;}
    function SetLength(val) {this.length = val;}
    function SetWidth(val) {this.width = val;}
    function SetDirection(val) {this.direction = val;}
    function SetPlatform(idx, val) { this.platform[idx] <- val;}
    function SetupAllPlatform()
    {
        if (this.length < 2) return false;
        local func = null;
        local source = this.platform[0].GetBody();
        switch (this.direction) {
            case AIRail.RAILTRACK_NE_SW: func = Tiles.SE_Of; break;
            case AIRail.RAILTRACK_NW_SE: func = Tiles.SW_Of; break;
            default: Debug.DontCallMe("Setup Platform", this.direction);
        }
        for (local w = 1; w < this.length; w++) {
            local target = Platform();
            target.SetBody(func(source));
            target.SetHead(target.FindLastTile(this.direction, true, 1));
            target.SetBack(target.FindLastTile(this.direction, false));
            target.SetBackHead(target.FindLastTile(this.direction, false, 1));
            this.platform[w] <- target;
        }
    }

    function FindFree(platform_idx = 0)
    {
        local dtile = -1;
        local tile = this.platform[platform_idx].GetBody();
        switch (this.direction) {
            case AIRail.RAILTRACK_NE_SW:
                dtile = (AITile.IsBuildable(NE_Of(tile))) ? NE_Of(tile) : SW_Of(tile, this.length - 1);
                break;
            case AIRail.RAILTRACK_NW_SE:
                dtile = (AITile.IsBuildable(NW_Of(tile))) ? NW_Of(tile) : SE_Of(tile, this.length - 1);
                break;
            default: Debug.DontCallMe("FindFree", this.direction);
            break;
        }
        return dtile;
    }
}

class Platform
{
    body = null;
    head = null;
    back = null;
    backhead = null;
    constructor()
    {
        this.body = -1;
        this.head = -1;
        this.back = -1;
        this.backhead = -1;
    }
    function GetBody() { return this.body; }
    function GetHead() { return this.head; }
    function GetBack() { return this.back; }
    function GetBackHead() { return this.backhead;}
    function SetBody(val) { this.body = val; }
    function SetHead(val) { this.head = val; }
    function SetBack(val) { this.back = val; }
    function SetBackHead(val) { this.backhead = val; }
    function FindDirection(ind_object) {
        local diffX = abs(AIMap.GetTileX(this.body) - AIMap.GetTileX(ind_object));
        local diffY = abs(AIMap.GetTileY(this.body) - AIMap.GetTileY(ind_object));
        local maxDiff = max(diffX, diffY);
        if (diffX < 0) return AIRail.RAILTRACK_NE_SW;
        if (diffY < 0) return AIRail.RAILTRACK_NW_SE;
        if (diffX < diffY) return AIRail.RAILTRACK_NW_SE;
        return AIRail.RAILTRACK_NE_SW;
    }

    /**
    *@return the NE of station if NE_SW direction
    *@return the NW of station if NW_SE direction
    *@return the SW of station if NE_SW direction
    *@return the SE of station if NW_SE direction
    */
    function FindLastTile(dir, is_front = true, num = 0)
    {
        local tmp = this.body;
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
