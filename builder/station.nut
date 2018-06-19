/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that build a rail station.
 */
 
 class StationBuilder extends Base 
{	
	_station = null;
	
	static TYPE_SIMPLE = 1;
	static TYPE_TERMINUS = 2;
	
	constructor(base, cargo, srcIndustry, dstIndustry, isSource) {
		Base.constructor("StationBuilder");		
		if (Service.Data.RailStations.rawin("current")) {
			this._station = Service.Data.Stations.rawget("current");
		} else {
			//set new station
			this._station = StationBuilder.New(base, cargo);
			this.SetIndustries(srcIndustry, dstIndustry);
			this._station.IsSource = isSource;
		}
	}
	
	function New(base, cargo) {
		local t = {
			ID = -1,
			Base = base,
			Cargo = cargo,
			PlatformLength = 4,
			NumPlatform = 1,
			Orientation = AIRail.RAILTRACK_NW_SE,
			Industries = [-1,-1],
			IndustryTypes = [-1,-1],
			IsSource = true,
			Type = StationBuilder.TYPE_SIMPLE,
			Heading = "",
			Depot = -1
		}
		return t;
	}
	
	function Save() {
		Service.Data.RailStations.rawset(this._station.Base, this._station);
	}
	
	function Load(base) {
		if (Service.Data.Stations.rawin(base)) {
			this._station = Service.Data.RailStations.rawget(base);
			return true;
		}
		Info("Load failed. Index", base, "not found");
		return false;
	}
	
	function SetIndustries(src, dst) {
		this._station.Industries = [src, dst];
		this._station.IndustryTypes = [AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst)];
	}
	
	function SetTerminus(direction) {
		this._station.Type = StationBuilder.TYPE_TERMINUS;
		this._station.NumPlatform = 2;
		this._station.Orientation = direction;
		local start = AIIndustry.GetLocation(this._station.Industries[0]);
		local finish = AIIndustry.GetLocation(this._station.Industries[1]);
		if (direction == AIRail.RAILTRACK_NW_SE) {
			this._station.Heading = (AIMap.GetTileY(start) - AIMap.GetTileY(finish)) > 0 ? "NW" : "SE";
		} else {
			this._station.Heading = (AIMap.GetTileX(start) - AIMap.GetTileX(finish)) > 0 ? "NE" : "SW";
		}
	}
	
	function IsBuildable() {
		//X = NESW; Y = NWSE
		local t = XTile.NW_Of(this._station.Base,1);
		local x = this._station.NumPlatform;
		local y = this._station.PlatformLength + 2;
		if (this._station.Orientation == AIRail.RAILTRACK_NE_SW) {
			y = this._station.NumPlatform;
			x = this._station.PlatformLength + 2;
			t = XTile.NE_Of(this._station.Base, 1);
		}
		
		if (this._station.Type == StationBuilder.TYPE_TERMINUS) {
			local mode = AITestMode();
			if (!this.BuildEntry()) return 0;
		}
		//Debug.Pause(t,"base x:"+x+"-y:"+y);
		return XTile.IsBuildableRange(t, x, y);
	}
	
	function Build() {
		local station_id = XStation.FindIDNear(this._station.Base, 8);
		local distance = AIIndustry.GetDistanceManhattanToTile(this._station.Industries[0], AIIndustry.GetLocation(this._station.Industries[1]));
		AIRail.BuildNewGRFRailStation(this._station.Base, this._station.Orientation, this._station.NumPlatform,
				this._station.PlatformLength, station_id, this._station.Cargo, this._station.IndustryTypes[0],
				this._station.IndustryTypes[1], distance, this._station.IsSource);
		if (this._station.Type == StationBuilder.TYPE_TERMINUS && AIRail.IsRailStationTile(this._station.Base))
			if (!this.BuildEntry()) {
				local end = -1;
				if (this._station.Orientation == AIRail.RAILTRACK_NE_SW) {
					end = XTile.AddOffset(this._station.Base, this._station.PlatformLength-1, this._station.NumPlatform-1);
				} else {
					end = XTile.AddOffset(this._station.Base, this._station.NumPlatform-1, this._station.PlatformLength-1);
				}
				AIRail.RemoveRailStationTileRectangle(this._station.Base, end, false);

				if (AIRail.IsRailDepotTile(this._station.Depot)) {
					AITile.DemolishTile(this._station.Depot);
					AITile.DemolishTile(AIRail.GetRailDepotFrontTile(this._station.Depot));
					this._station.Depot = -1;
				}
				
				return false;
			}
		this._station.ID = AIStation.GetStationID(this._station.Base);
		return AIRail.IsRailStationTile(this._station.Base) && XTile.IsMyTile(this._station.Base);
	}
	
	function BuildEntry() {
		if (((this._station.Heading == "NW")  && (this._station.IsSource)) || ((this._station.Heading == "SE")  && (!this._station.IsSource))) {
			if (!this.BuildTerminusNW(this._station.Base)) return false;
			this.BuildDepot("NW");
		}
		
		if (((this._station.Heading == "SE")  && (this._station.IsSource)) || ((this._station.Heading == "NW")  && (!this._station.IsSource))) {
			if (!this.BuildTerminusSE(this._station.Base)) return false;
			this.BuildDepot("SE");
		}
		
		if (((this._station.Heading == "NE")  && (this._station.IsSource)) || ((this._station.Heading == "SW")  && (!this._station.IsSource))) {
			if (!this.BuildTerminusNE(this._station.Base)) return false;
			this.BuildDepot("NE");
		}
		
		if (((this._station.Heading == "SW")  && (this._station.IsSource)) || ((this._station.Heading == "NE")  && (!this._station.IsSource))) {
			if (!this.BuildTerminusSW(this._station.Base)) return false;
			this.BuildDepot("SW");
		}
		return true;
	}
	
	function GetStartPath() {
		local ret = []; //[Start, Before] [End, After]
		if (this._station.Type == StationBuilder.TYPE_SIMPLE) {
			if (this._station.Orientation == AIRail.RAILTRACK_NW_SE) {
				ret.push([XTile.NW_Of(this._station.Base,1), this._station.Base]);
				ret.push([XTile.SE_Of(this._station.Base,this._station.PlatformLength), XTile.SE_Of(this._station.Base,this._station.PlatformLength-1)]);
			}
			if (this._station.Orientation == AIRail.RAILTRACK_NE_SW) {
				ret.push([XTile.NE_Of(this._station.Base,1), this._station.Base]);
				ret.push([XTile.SW_Of(this._station.Base,this._station.PlatformLength), XTile.SW_Of(this._station.Base,this._station.PlatformLength-1)]);
			}
		} else if (this._station.Type == StationBuilder.TYPE_TERMINUS) {
			if (((this._station.Heading == "NW")  && (this._station.IsSource)) || ((this._station.Heading == "SE")  && (!this._station.IsSource))) {
				//BuildTerminusNW
				ret.push(this._getTiles(this._station.Base, [6,4], -2));
				ret.push(this._getTiles(this._station.Base, [7,5], -2));
			}
			
			if (((this._station.Heading == "SE")  && (this._station.IsSource)) || ((this._station.Heading == "NW")  && (!this._station.IsSource))) {
				//BuildTerminusSE
				ret.push(this._getTiles(this._station.Base, [13,11], 2));
				ret.push(this._getTiles(this._station.Base, [12,10], 2));
			}
			
			if (((this._station.Heading == "NE")  && (this._station.IsSource)) || ((this._station.Heading == "SW")  && (!this._station.IsSource))) {
				//BuildTerminusNE
				ret.push(this._getTiles(this._station.Base, [-11,-10], -8));
				ret.push(this._getTiles(this._station.Base, [-3, -2], -8));
			}
			
			if (((this._station.Heading == "SW")  && (this._station.IsSource)) || ((this._station.Heading == "NE")  && (!this._station.IsSource))) {
				//BuildTerminusSW
				ret.push(this._getTiles(this._station.Base, [6,5], 8));
				ret.push(this._getTiles(this._station.Base, [14,13], 8));
			}
		}
		return ret;
	}
	
	function BuildDepot(direction) {
		local depots = [];
		if (direction == "NW") {
			local head1 = XTile.NW_Of(this._station.Base, 1);
			local head2 = XTile.SW_Of(head1, 1);
			local depot1 = XTile.NE_Of(head1, 1);
			local depot2 = XTile.SW_Of(head2, 1);
			depots.extend([[depot1, head1],[depot2, head2]]);
		}
		
		if (direction == "SE") {
			local head1 = XTile.SE_Of(this._station.Base, this._station.PlatformLength);
			local head2 = XTile.SW_Of(head1, 1);
			local depot1 = XTile.NE_Of(head1, 1);
			local depot2 = XTile.SW_Of(head2, 1);
			depots.extend([[depot1, head1],[depot2, head2]]);
		}
		
		if (direction == "NE") {
			local head1 = XTile.NE_Of(this._station.Base, 1);
			local head2 = XTile.SE_Of(head1, 1);
			local depot1 = XTile.NW_Of(head1, 1);
			local depot2 = XTile.SE_Of(head2, 1);
			depots.extend([[depot2, head2], [depot1, head1]]);
		}
		
		if (direction == "SW") {
			local head1 = XTile.SW_Of(this._station.Base, this._station.PlatformLength);
			local head2 = XTile.SE_Of(head1, 1);
			local depot1 = XTile.NW_Of(head1, 1);
			local depot2 = XTile.SE_Of(head2, 1);
			depots.extend([[depot2, head2], [depot1, head1]]);
		}
		
		if (!this._station.IsSource) depots.reverse();
		
		foreach (body in depots) {
			if ((AITile.GetMinHeight(body[0]) != AITile.GetMaxHeight(body[1])) || (AITile.GetMinHeight(body[1]) != AITile.GetMaxHeight(body[0]))) {
				XTile.SetFlatHeight(body[1], AITile.GetMaxHeight(body[1]));
				if ((AITile.GetMinHeight(body[0]) != AITile.GetMaxHeight(body[1])) || (AITile.GetMinHeight(body[1]) != AITile.GetMaxHeight(body[0]))) continue;
			}	
			AIRail.BuildRailDepot(body[0], body[1]);
			if (AIRail.IsRailDepotTile(body[0])) {
				this._station.Depot = body[0];
				foreach(track in Const.RailTrack)
					AIRail.BuildRailTrack(body[1], track);
				return true;
			}
		}
		return false;
	}
		
	function GetIgnoredTiles() {
		local ret = [];
		/*
		if (this._station.Type == StationBuilder.TYPE_TERMINUS) {
			if (((this._station.Heading == "NW")  && (this._station.IsSource)) || ((this._station.Heading == "SE")  && (!this._station.IsSource))) {
				//BuildTerminusNW
				ret.extend(this._getTiles(this._station.Base, [5, 7], -2));
			}
			
			if (((this._station.Heading == "SE")  && (this._station.IsSource)) || ((this._station.Heading == "NW")  && (!this._station.IsSource))) {
				//BuildTerminusSE
				ret.extend(this._getTiles(this._station.Base, [10, 12], 2));
			}
			
			if (((this._station.Heading == "NE")  && (this._station.IsSource)) || ((this._station.Heading == "SW")  && (!this._station.IsSource))) {
				//BuildTerminusNE
				ret.extend(this._getTiles(this._station.Base, [-2, -3], -8));
			}
			
			if (((this._station.Heading == "SW")  && (this._station.IsSource)) || ((this._station.Heading == "NE")  && (!this._station.IsSource))) {
				//BuildTerminusSW
				ret.extend(this._getTiles(this._station.Base, [13, 14], 8));
			}
		}
		*/
		return ret;
	}
	
	function BuildTerminusSE(base) {
		local tiles = this._getTiles(this._station.Base, [12, 13], 2);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [8,9,10,11], 2, AIRail.RAILTRACK_NW_SE) &&
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_NW_SW) &&
		this._buildRailTrack(base, [8], 2, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NW_NE) &&
		this._buildRailTrack(base, [9], 2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusNW(base) {
		local tiles = this._getTiles(this._station.Base, [6, 7], -2);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [2,3,4,5], -2, AIRail.RAILTRACK_NW_SE) &&
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_NW_SW) &&
		this._buildRailTrack(base, [2], -2, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NW_NE) &&
		this._buildRailTrack(base, [3], -2, AIRail.RAILTRACK_NE_SE);
	}
	
	function BuildTerminusSW(base) {
		local tiles = this._getTiles(this._station.Base, [6, 14], 8);
		return AITile.IsBuildable(tiles[0]) && AITile.IsBuildable(tiles[1]) &&
		this._buildRailTrack(base, [4,5,12,13], 8, AIRail.RAILTRACK_NE_SW) &&
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_NE_SE) &&
		this._buildRailTrack(base, [4], 8, AIRail.RAILTRACK_SW_SE) &&
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_SW) &&
		this._buildRailTrack(base, [12], 8, AIRail.RAILTRACK_NW_NE);
	}
	
	function BuildTerminusNE(base) {
		local tiles = this._getTiles(this._station.Base, [-11, -3], -8);
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
