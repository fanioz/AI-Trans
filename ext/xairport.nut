/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * An AIAirport extension
 */
class XAirport
{
	function AllowPlaneToLand(pt, at) {
		//AILog.Info("Plane:" + CLString.PlaneType (pt) + ":want to land on:" + CLString.AirportType (at));
		switch (at) {
			case AIAirport.AT_INTERCON:  //"AT_INTERCON";
			case AIAirport.AT_INTERNATIONAL:  //"AT_INTERNATIONAL";
			case AIAirport.AT_METROPOLITAN:  //"AT_METROPOLITAN";
			case AIAirport.AT_LARGE:
				if (pt == AIAirport.PT_BIG_PLANE) return true;
			case AIAirport.AT_COMMUTER:  //"AT_COMMUTER";
			case AIAirport.AT_SMALL:
				if (pt == AIAirport.PT_SMALL_PLANE) return true;
				break;
			case AIAirport.AT_HELIDEPOT:
			case AIAirport.AT_HELISTATION:
				if (pt == AIAirport.PT_HELICOPTER) return true;
			default :
				return false;
		}
		return false;
	}

	function HasPlaneType(tile, pt) {
		//please change behaviour if crashed
		//however a hangar would look like AITile.IsStationTile
		assert(AIAirport.IsAirportTile(tile));
		return XAirport.AllowPlaneToLand(pt, AIAirport.GetAirportType(tile));
	}

	function RealBuild(tile, type, x, y, self) {
		local id = XStation.FindIDNear(tile, 15);
		local timeout = 20;
		while (timeout > 0) {
			timeout--;
			local built = AIAirport.BuildAirport(tile, type, id);
			if (built) break;
			Warn("Airport building failed: ", AIError.GetLastErrorString());
			switch (AIError.GetLastError()) {
				case AIError.ERR_AREA_NOT_CLEAR :
				case AIError.ERR_FLAT_LAND_REQUIRED:
					if (!XTile.MakeLevel(tile, x y)) return -1;;
					break;
				case AIError.ERR_LOCAL_AUTHORITY_REFUSES:
					if (!self.ImproveRating()) return -1;
					break;
				case AIError.ERR_STATION_TOO_SPREAD_OUT:
				case AIStation.ERR_STATION_TOO_CLOSE_TO_ANOTHER_STATION:
					id = XStation.FindIDNear(tile, 0);
			}
		}
		return AIStation.GetStationID(tile);
	}

	function GetHangar(location) {
		local airport_tipe = AIAirport.GetAirportType(location);
		if (airport_tipe != AIAirport.AT_HELIPORT) return AIAirport.GetHangarOfAirport(location);
		local area = CLList(AIDepotList(AITile.TRANSPORT_AIR));
		area.Valuate(AIMap.DistanceMax, location);
		area.KeepBelowValue(15);
		area.SortValueAscending();
		if (area.Count()) return area.Pop();
		return -1;
	}

	function MaxPlane(at) {
		local num = 0;
		switch (at) {
			case AIAirport.AT_INTERCON: num ++; //7
			case AIAirport.AT_INTERNATIONAL: num ++; //6
			case AIAirport.AT_METROPOLITAN: num ++; //5
			case AIAirport.AT_LARGE: num ++; //4
			case AIAirport.AT_COMMUTER: //3
			case AIAirport.AT_HELISTATION: num ++; //3
			case AIAirport.AT_SMALL: //2
			case AIAirport.AT_HELIDEPOT: num ++; //2
			case AIAirport.AT_HELIPORT: num ++; //1
			default :
				return num;
		}
	}

	function GetDivisorNum(at) {
		return AIAirport.GetAirportWidth(at) * AIAirport.GetAirportHeight(at);
	}
}
