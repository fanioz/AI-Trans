/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that connect a route by rail.
 */
 
 class StationBuilder extends Infrastructure 
{	
	_platformLength = null;
	_num_platforms = null;
	_stationIsTerminus = null;
	_orientation = null;
	_industryTypes = null;
	_industries = null;
	_isSourceStation = null;
	_stationType = null;
	
	static TYPE_SIMPLE = 1;
	
	constructor(base, cargo, srcIndustry, dstIndustry, isSource) {
		Infrastructure.constructor(-1, base);
		this.SetVType(AIVehicle.VT_RAIL);
		this.SetCargo(cargo);
		this._platformLength =4;
		this._num_platforms = 1;
		this._stationIsTerminus = true;
		this._orientation = AIRail.RAILTRACK_NW_SE;
		this._industries = [srcIndustry, dstIndustry];
		this._industryTypes = [AIIndustry.GetIndustryType(srcIndustry), AIIndustry.GetIndustryType(dstIndustry)];
		this._isSourceStation = isSource;
		this._stationType = StationBuilder.TYPE_SIMPLE;
	}
	
	function IsBuildable() {
		//X = NESW; Y = NWSE
		local t = XTile.NW_Of(this.GetLocation(),1);
		local x = this._num_platforms;
		local y = this._platformLength + 2;
		if (this._orientation == AIRail.RAILTRACK_NE_SW) {
			y = this._num_platforms;
			x = this._platformLength + 2;
			t = XTile.NE_Of(this.GetLocation(), 1);
		}
		//Debug.Pause(t,"base x:"+x+"-y:"+y);
		return XTile.IsBuildableRange(t, x, y);
	}
	
	function Build() {
		local station_id = XStation.FindIDNear(this.GetLocation(), 8);
		local distance = AIIndustry.GetDistanceManhattanToTile(this._industries[0], AIIndustry.GetLocation(this._industries[1]));
		if (this._stationType == StationBuilder.TYPE_SIMPLE) {
			AIRail.BuildNewGRFRailStation(this.GetLocation(), this._orientation, this._num_platforms,
				this._platformLength, station_id, this.GetCargo(), this._industryTypes[0],
				this._industryTypes[1], distance, this._isSourceStation);
		}
		this.SetID(AIStation.GetStationID(this.GetLocation()));
		return AIRail.IsRailStationTile(this.GetLocation()) && XTile.IsMyTile(this.GetLocation());
	}
	
	function GetStartPath() {
		local ret = []; //[Start, Before] [End, After]
		if (this._stationType == StationBuilder.TYPE_SIMPLE) {
			if (this._orientation == AIRail.RAILTRACK_NW_SE) {
				ret.push([XTile.NW_Of(this.GetLocation(),1), this.GetLocation()]);
				ret.push([XTile.SE_Of(this.GetLocation(),this._platformLength), XTile.SE_Of(this.GetLocation(),this._platformLength-1)]);
			}
			if (this._orientation == AIRail.RAILTRACK_NE_SW) {
				ret.push([XTile.NE_Of(this.GetLocation(),1), this.GetLocation()]);
				ret.push([XTile.SW_Of(this.GetLocation(),this._platformLength), XTile.SW_Of(this.GetLocation(),this._platformLength-1)]);
			}
		}
		return ret;
	}
	
	function BuildTerminusSE(base) {
		this._buildRailTrack(base, [8,9,10,11], 2, AIRail.RAILTRACK_NW_SE);
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_NW_SW);
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NW_NE);
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusNW(base) {
		this._buildRailTrack(base, [2,3,4,5], -2, AIRail.RAILTRACK_NW_SE);
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_NW_SW);
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NW_NE);
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusSW(base) {
		this._buildRailTrack(base, [4,5,12,13], 8, AIRail.RAILTRACK_NE_SW);
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_NE_SE);
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_SW);
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_NE);
	}
	
	function BuildTerminusNE(base) {
		this._buildRailTrack(base, [-1,-2,-9,-10], -8, AIRail.RAILTRACK_NE_SW);
		this._buildRailTrack(base, [-1], -8, AIRail.RAILTRACK_NE_SE);
		this._buildRailTrack(base, [-1], -8, AIRail.RAILTRACK_SW_SE);
		this._buildRailTrack(base, [-9], -8, AIRail.RAILTRACK_NW_NE);
		this._buildRailTrack(base, [-9], -8, AIRail.RAILTRACK_NW_SW);
	}
	
	function _buildRailTrack(base, coord, divisor, dir) {
		while (coord.len() > 0) {
            local c = coord.pop();
            local tile = this._getTileIndex(base, c, divisor);
            Debug.Sign(tile, "" + c);
            if (!AIRail.BuildRailTrack(tile, dir) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
        }
	}
	
	function _getTileIndex(base, coord, divisor) {
		local x = coord % divisor;
        local y = (coord - x) / divisor;
		return base + AIMap.GetTileIndex(x, y);
	}
}
