/*  10.02.27 - XRoad.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XRoad class
 * an AIRoad eXtension
 */
class XRoad
{
	function GetRoadType (tile) {
		local ret = 0;
		foreach (rt in Const.RoadTypeList) {
			if (AIRoad.HasRoadType (tile, rt)) ret = ret | 1 << rt;
		}
		return ret - 1;
	}

	function GetBackOrFrontStation(tile) {
		local ret = AIRoad[(AIRoad.IsDriveThroughRoadStationTile (tile) ? "GetDriveThroughBackTile" : "GetRoadStationFrontTile")] (tile);
		while (!XTile.IsFlat(ret)) {
			ret = XTile.NextTile(tile, ret);
		}
		return ret;
	}

	function IsRoadTile (tile) {
		return AIRoad.HasRoadType (tile, AIRoad.ROADTYPE_ROAD);
	}
	
	function GetNeighbourRoadCount(tile) {
		local count = 0;
		foreach (h in XTile.Adjacent(tile)) if (XRoad.IsRoadTile(tile)) count++;
		return count;
	}

	function BuilderStation (tile, dtrs, type, area) {
		Info ("Building new RoadStation");
		local restriction = CLList();
		local bt = AIRoad[(type == AIRoad.ROADVEHTYPE_BUS ? "BT_BUS_STOP" : "BT_TRUCK_STOP")];
		local est_cost = AIRoad.GetBuildCost(AIRoad.GetCurrentRoadType(), bt);
		if (area.IsEmpty()) return -1;
		foreach (body, v in area) {
			local head = -1;
			if (body == tile) continue;
			local path = null;
			if (AIMap.DistanceManhattan(body, tile) == 1) {
				head = tile;
			} else {
				path = XRoad.FindPath([tile], [body], restriction.GetItemArray());
				if (path == null) continue;
				if (!Money.Get(est_cost + path.GetCost())) continue;
				Info ("route len", path.GetLength());
				local pf = AyPath.GetEndTiles(path);
				assert(body == pf[0]);
				head = pf[1];
			} 
			assert(head != body);
			if (XRoad.BuildStation (body, head, true, type)) {
				Info ("we've just build a road station" );
				restriction.AddTile(body);
				if (head == tile || XRoad.BuildRoute (path, [head], [tile], restriction.GetItemArray(), 4)) return body;
				AIRoad.RemoveRoadStation(body);
				restriction.RemoveItem(body);
			}
		}
		Warn ("building dtrs failed");
		if (dtrs) return -1;
		foreach (head, v in area) {
			foreach (body in XTile.Adjacent(head)) {
				if (XRoad.IsRoadTile(body)) continue;
				if (XTile.IsMyTile(body)) continue;
				AITile.DemolishTile(body);
				if (XRoad.BuildStation (body, head, false, type)) {
					local path = XRoad.FindPath([head], [tile], restriction.GetItemArray());
					if (XRoad.IsConnectedTo([head], [tile]) || XRoad.BuildRoute (path, [head], [tile], restriction.GetItemArray(), 4)) return body;
					AIRoad.RemoveRoadStation(body);
				}				
			}
		}
		Money.Pay();
		return -1;
	}

	function BuildStation (tile, head, is_dtrs, type) {
		assert (tile != head);
		local retry = 20;
		local st_id = XStation.FindIDNear (tile, retry);
		local back = XTile.NextTile (head, tile);
		local is_built = false;
		while (retry > 0) {
			retry--;
			if (is_dtrs) {
				is_built = AIRoad.BuildDriveThroughRoadStation (tile, head, type, st_id);
			} else {
				is_built = AIRoad.BuildRoadStation (tile, head, type, st_id);
				back = tile;
			}
			if (is_built) {
				XRoad.BuildStraight (back, head) ;
				break;
			}
			Warn ("build road station failed:", AIError.GetLastErrorString());
			switch (AIError.GetLastError()) {
				case AIRoad.ERR_ROAD_CANNOT_BUILD_ON_TOWN_ROAD:
				case AIError.ERR_AREA_NOT_CLEAR:
					AITile.DemolishTile (tile);
					XRoad.BuildStraight (back, head) ;
					retry -= 8;
					break;
				case AIError.ERR_NOT_ENOUGH_CASH:
				case AIError.ERR_VEHICLE_IN_THE_WAY:
					retry++;
					AIController.Sleep (5 * retry);
					break;
				case AIError.ERR_FLAT_LAND_REQUIRED:
					retry -= 8;
					XTile.MakeLevel (tile, 1, 1);
					break;
				case AIError.ERR_STATION_TOO_SPREAD_OUT:
				case AIStation.ERR_STATION_TOO_CLOSE_TO_ANOTHER_STATION:
					retry -= 5;
					st_id = XStation.FindIDNear (tile, -1);
					break;
				case AIStation.ERR_STATION_TOO_MANY_STATIONS:
				case AIStation.ERR_STATION_TOO_MANY_STATIONS_IN_TOWN:
				case AIRoad.ERR_ROAD_DRIVE_THROUGH_WRONG_DIRECTION:
				case AIError.ERR_PRECONDITION_FAILED:
				case AIError.ERR_UNKNOWN:
				case AIError.ERR_OWNED_BY_ANOTHER_COMPANY:
				case AIError.ERR_LOCAL_AUTHORITY_REFUSES:
					retry = 0;
					break;
				default:
					Warn ("un-handled:", AIError.GetLastErrorString());
					Debug.Halt (tile);
					retry = 0;
			}
		}
		return AIRoad.IsRoadStationTile(tile);
	}

	// @note exec mode only
	function BuildStraight (from, to) {
		local retry_num = 50;
		while (retry_num > 0) {
			if (AIRoad.AreRoadTilesConnected (from, to)) return true;
			if (AIRoad.BuildRoad (from, to)) return true;
			retry_num --;
			Warn ("build road piece", AIError.GetLastErrorString());
			switch (AIError.GetLastError()) {
					/* ignore these errors */
				case AIError.ERR_NONE:
				case AIError.ERR_ALREADY_BUILT:
					return true;
				case AIError.ERR_NOT_ENOUGH_CASH:
					if (AIVehicleList().IsEmpty()) return false;
				case AIError.ERR_VEHICLE_IN_THE_WAY:
				case AIRoad.ERR_ROAD_WORKS_IN_PROGRESS:
					AIController.Sleep (max(retry_num * 3, 1));
					break;
				case AIError.ERR_AREA_NOT_CLEAR:
					if (!AIRoad.IsRoadTile (to)) {
						if (XTile.IsMyTile (to) || !AITile.DemolishTile (to)) retry_num -= 25;
						Warn ("demolishing", AIError.GetLastErrorString());
					}
					break;
				case AIError.ERR_FLAT_LAND_REQUIRED:
				case AIError.ERR_LAND_SLOPED_WRONG:
					AITile.LevelTiles (from, to);
					retry_num -= 10;
					break;
				case AIError.ERR_PRECONDITION_FAILED:
				case AIRoad.ERR_ROAD_ONE_WAY_ROADS_CANNOT_HAVE_JUNCTIONS:
				case AITunnel.ERR_TUNNEL_CANNOT_BUILD_ON_WATER:
				case AIError.ERR_OWNED_BY_ANOTHER_COMPANY:
					return false;
				default:
					::Debug.Say(["un-handled:", AIError.GetLastErrorString()], 2);
					Debug.Halt (from);
					retry_num = 0;
					break;
			}
			local tmp = from;
			from = to;
			to = tmp;
		}
		return false;
	}

	function BuildDepot (tile, area) {
		Info ("Building new RoadDepot");
		area.Valuate(AIMap.DistanceManhattan, tile);
		area.KeepBetweenValue(3, 20);
		if (area.IsEmpty()) return -1;
		local path = XRoad.FindPath(area.GetItemArray(), [tile], []);
		if (path == null) return -1;
		local est_cost = path.GetCost() + AIRoad.GetBuildCost(AIRoad.GetCurrentRoadType(), AIRoad.BT_DEPOT);
		Info ("Est. Cost", est_cost);
		if (!Money.Get(est_cost)) return -1;
		local tiles = AyPath.GetStartTiles(path);
		XRoad.BuildRoute(path, [tiles[1]], [tile], [], 4);
		AITile.DemolishTile(tiles[0]);
		if (AIRoad.BuildRoadDepot(tiles[0], tiles[1])) {
			return tiles[0];
		}
		return -1;
	}

	function IsConnectedTo(tile1, tile2) {
		foreach (idx, tilea in tile1) {
			foreach (idx, tileb in tile2) {
				if (AIRoad.AreRoadTilesConnected(tilea, tileb)) return true;
			}
		}
		local pf =  Road_PT();
		pf.InitializePath (tile1, tile2, []);
		return (typeof pf.FindPath (-1)) == "instance";
	}

	function FindPath(start, finish, ignored) {
		local pf = Road_PF();
		pf.InitializePath (start, finish, ignored);
		return pf.FindPath(-1);
	}

	function BuildRoute (path, start, finish, ignore, num) {
		if (num < 1) return false;
		num--;
		if (path == null) {
			path = XRoad.FindPath(start, finish, ignore);
			if (path == null) return false;
		}

		Info ("Start building", path.GetLength(), "tiles on", num, "try");
		if (!Money.Get(path.GetCost())) {
			Warn ("However the money isn't enough now");
			return false;
		}
		local last_node = path.GetTile();
		local next = path.GetParent();
		while (next) {			
			local next_node = next.GetTile();
			if (AIMap.DistanceManhattan (last_node, next_node) > 1) {
				if (!XTile.IsBridgeTunnel (last_node)) {
					/* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
					if (AIRoad.IsRoadTile (last_node)) AITile.DemolishTile (last_node);
					if (AITunnel.GetOtherTunnelEnd (last_node) == next_node) {
						Info("Build a tunnel");
						if (!AITunnel.BuildTunnel (AIVehicle.VT_ROAD, last_node)) {
							/* An error occured while building a tunnel. TODO: handle it. */
							Warn ("Build tunnel error: ", AIError.GetLastErrorString());
							ignore.push(next_node);
							//Debug.Halt(last_node);
							return XRoad.BuildRoute (null, start, finish, ignore, num);
						}
					} else {
						Info("Build a bridge");
						local bridge_list = AIBridgeList_Length (AIMap.DistanceManhattan (last_node, next_node) +1);
						bridge_list.Valuate (AIBridge.GetMaxSpeed);
						if (!AIBridge.BuildBridge (AIVehicle.VT_ROAD, bridge_list.Begin(), last_node, next_node)) {
							/* An error occured while building a bridge. TODO: handle it. */
							Warn ("Build bridge error: ", AIError.GetLastErrorString());
							if (AIError.GetLastError() == AIBridge.ERR_BRIDGE_HEADS_NOT_ON_SAME_HEIGHT) {
								ignore.push(next_node);
							}
							//Debug.Halt(last_node);
							return XRoad.BuildRoute (null, start, finish, ignore, num);
						}
					}
				}
				Info ("bridge/tunnel should have been built");
			} else {
				Debug.Sign(last_node, next.GetCost());
				//build a long straight tile
				// credit to : zuu (CluelessPlus)
				Info ("build a road piece");
				while(next.GetParent()) {
					 local future_node = next.GetParent().GetTile();
					 if (AIMap.DistanceManhattan(next_node, future_node) > 1) break;
					 if (!XTile.IsStraight (last_node, future_node)) break;
					 next_node = future_node;
					 next = next.GetParent();
				}
				if (!XRoad.BuildStraight (last_node, next_node)) {
					/* An error occured while building a piece of road. TODO: handle it.
					 * Note that is can also be the case that the road was already build. */
					 //Debug.Halt(last_node);
					 //ignore.push(next_node);
					return XRoad.BuildRoute (null, start, finish, ignore, num);
				}
			}
			last_node = next_node;
			next = next.GetParent();
		}
		return XRoad.IsConnectedTo(start, finish);
	}

	/**
	 * Can we build from cur to next and prev to cur
	 */
	function CanExit(prev, cur, next) {
		if (AIRoad.AreRoadTilesConnected(prev, cur) && AIRoad.AreRoadTilesConnected(cur, next)) return true;
		return (AIRoad.CanBuildConnectedRoadPartsHere(cur, prev, next) > 0);
	}
}
