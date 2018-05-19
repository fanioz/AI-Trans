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
	_orientation = null;
	_industryTypes = null;
	_industries = null;
	_isSourceStation = null;
	_stationType = null;
	_heading = null;
	
	static TYPE_SIMPLE = 1;
	static TYPE_TERMINUS = 2;
	
	constructor(base, cargo, srcIndustry, dstIndustry, isSource) {
		Infrastructure.constructor(-1, base);
		this.SetVType(AIVehicle.VT_RAIL);
		this.SetCargo(cargo);
		this._platformLength =4;
		this._num_platforms = 1;
		this._orientation = AIRail.RAILTRACK_NW_SE;
		this._industries = [srcIndustry, dstIndustry];
		this._industryTypes = [AIIndustry.GetIndustryType(srcIndustry), AIIndustry.GetIndustryType(dstIndustry)];
		this._isSourceStation = isSource;
		this._stationType = StationBuilder.TYPE_SIMPLE;
		this._heading = 0;
	}
	
	function SetTerminus(direction) {
		this._stationType = StationBuilder.TYPE_TERMINUS;
		this._num_platforms = 2;
		this._orientation = direction;
		local start = AIIndustry.GetLocation(this._industries[0]);
		local finish = AIIndustry.GetLocation(this._industries[1]);
		if (direction == AIRail.RAILTRACK_NW_SE) {
			this._heading = (AIMap.GetTileY(start) - AIMap.GetTileY(finish)) > 0 ? "NW" : "SE";
		} else {
			this._heading = (AIMap.GetTileX(start) - AIMap.GetTileX(finish)) > 0 ? "NE" : "SW";
		}
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
		
		if (this._stationType == StationBuilder.TYPE_TERMINUS) {
			local mode = AITestMode();
			if (!this.BuildEntry()) return 0;
		}
		//Debug.Pause(t,"base x:"+x+"-y:"+y);
		return XTile.IsBuildableRange(t, x, y);
	}
	
	function Build() {
		local station_id = XStation.FindIDNear(this.GetLocation(), 8);
		local distance = AIIndustry.GetDistanceManhattanToTile(this._industries[0], AIIndustry.GetLocation(this._industries[1]));
		AIRail.BuildNewGRFRailStation(this.GetLocation(), this._orientation, this._num_platforms,
				this._platformLength, station_id, this.GetCargo(), this._industryTypes[0],
				this._industryTypes[1], distance, this._isSourceStation);
		if (this._stationType == StationBuilder.TYPE_TERMINUS && AIRail.IsRailStationTile(this.GetLocation()))
			if (!this.BuildEntry()) {
				local end = -1;
				if (this._orientation == AIRail.RAILTRACK_NE_SW) {
					end = XTile.AddOffset(this.GetLocation(), this._platformLength-1, this._num_platforms-1);
				} else {
					end = XTile.AddOffset(this.GetLocation(), this._num_platforms-1, this._platformLength-1);
				}
				AIRail.RemoveRailStationTileRectangle(this.GetLocation(), end, false);
				return false;
			}
		this.SetID(AIStation.GetStationID(this.GetLocation()));
		return AIRail.IsRailStationTile(this.GetLocation()) && XTile.IsMyTile(this.GetLocation());
	}
	
	function BuildEntry() {
		if (((this._heading == "NW")  && (this._isSourceStation)) || ((this._heading == "SE")  && (!this._isSourceStation))) {
			if (!this.BuildTerminusNW(this.GetLocation())) return false;
		}
		
		if (((this._heading == "SE")  && (this._isSourceStation)) || ((this._heading == "NW")  && (!this._isSourceStation))) {
			if (!this.BuildTerminusSE(this.GetLocation())) return false;
		}
		
		if (((this._heading == "NE")  && (this._isSourceStation)) || ((this._heading == "SW")  && (!this._isSourceStation))) {
			if (!this.BuildTerminusNE(this.GetLocation())) return false;
		}
		
		if (((this._heading == "SW")  && (this._isSourceStation)) || ((this._heading == "NE")  && (!this._isSourceStation))) {
			if (!this.BuildTerminusSW(this.GetLocation())) return false;
		}
		return true;
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
		} else if (this._stationType == StationBuilder.TYPE_TERMINUS) {
			if (((this._heading == "NW")  && (this._isSourceStation)) || ((this._heading == "SE")  && (!this._isSourceStation))) {
				//BuildTerminusNW
				ret.push(this._getTiles(this.GetLocation(), [6,4], -2));
			}
			
			if (((this._heading == "SE")  && (this._isSourceStation)) || ((this._heading == "NW")  && (!this._isSourceStation))) {
				//BuildTerminusSE
				ret.push(this._getTiles(this.GetLocation(), [13,11], 2));
			}
			
			if (((this._heading == "NE")  && (this._isSourceStation)) || ((this._heading == "SW")  && (!this._isSourceStation))) {
				//BuildTerminusNE
				ret.push(this._getTiles(this.GetLocation(), [-11,-10], -8));
			}
			
			if (((this._heading == "SW")  && (this._isSourceStation)) || ((this._heading == "NE")  && (!this._isSourceStation))) {
				//BuildTerminusSW
				ret.push(this._getTiles(this.GetLocation(), [6,5], 8));
			}
		}
		return ret;
	}
		
	function GetIgnoredTiles() {
		local ret = [];
		if (this._stationType == StationBuilder.TYPE_TERMINUS) {
			if (((this._heading == "NW")  && (this._isSourceStation)) || ((this._heading == "SE")  && (!this._isSourceStation))) {
				//BuildTerminusNW
				ret.extend(this._getTiles(this.GetLocation(), [5, 7], -2));
			}
			
			if (((this._heading == "SE")  && (this._isSourceStation)) || ((this._heading == "NW")  && (!this._isSourceStation))) {
				//BuildTerminusSE
				ret.extend(this._getTiles(this.GetLocation(), [10, 12], 2));
			}
			
			if (((this._heading == "NE")  && (this._isSourceStation)) || ((this._heading == "SW")  && (!this._isSourceStation))) {
				//BuildTerminusNE
				ret.extend(this._getTiles(this.GetLocation(), [-2, -3], -8));
			}
			
			if (((this._heading == "SW")  && (this._isSourceStation)) || ((this._heading == "NE")  && (!this._isSourceStation))) {
				//BuildTerminusSW
				ret.extend(this._getTiles(this.GetLocation(), [13, 14], 8));
			}
		}
		return ret;
	}
	
	function BuildTerminusSE(base) {
		local tiles = this._getTiles(this.GetLocation(), [12, 13], 2);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [8,9,10,11], 2, AIRail.RAILTRACK_NW_SE) &&
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_NW_SW) &&
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NW_NE) &&
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusNW(base) {
		local tiles = this._getTiles(this.GetLocation(), [6, 7], -2);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [2,3,4,5], -2, AIRail.RAILTRACK_NW_SE) &&
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_NW_SW) &&
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NW_NE) &&
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusSW(base) {
		local tiles = this._getTiles(this.GetLocation(), [6, 14], 8);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [4,5,12,13], 8, AIRail.RAILTRACK_NE_SW) &&
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_NE_SE) &&
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_SW) &&
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_NE);
	}
	
	function BuildTerminusNE(base) {
		local tiles = this._getTiles(this.GetLocation(), [-11, -3], -8);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [-1,-2,-9,-10], -8, AIRail.RAILTRACK_NE_SW) &&
		this._buildRailTrack(base, [-1], -8, AIRail.RAILTRACK_NE_SE) &&
		this._buildRailTrack(base, [-1], -8, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [-9], -8, AIRail.RAILTRACK_NW_NE) &&
		this._buildRailTrack(base, [-9], -8, AIRail.RAILTRACK_NW_SW);
	}
	
	function _buildRailTrack(base, coord, divisor, dir) {
		foreach (tile in this._getTiles(base, coord, divisor))
			if (!AIRail.BuildRailTrack(tile, dir) && AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return false;
		return true;
	}
	
	function _getTiles(base, coord, divisor) {
		local ret = [];
		foreach (idx in coord)
			ret.push(this._getTileIndex(base, idx, divisor));
		return ret;
	}
	
	function _getTileIndex(base, coord, divisor) {
		local x = coord % divisor;
		local y = (coord - x) / divisor;
		return base + AIMap.GetTileIndex(x, y);
	}
}
