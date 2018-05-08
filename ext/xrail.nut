/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XRail class
 * an AIRail eXtension
 */
class XRail
{
	function HasRail(tile, type) {
		return XTile.IsMyTile(tile) && AIRail.TrainHasPowerOnRail(type, AIRail.GetRailType(tile));
	}

	function IsMatchSignal(from, to) {
		return (AIRail.GetSignalType(from, to) == AIRail.SIGNALTYPE_NONE);
	}

	function IsReversableSignal(from, to) {
		return ((AIRail.GetSignalType(from, to) == AIRail.SIGNALTYPE_PBS) ||
				(AIRail.GetSignalType(from, to) >= AIRail.SIGNALTYPE_TWOWAY));
	}

	/**
	 * @see AIRail::Are::TileConnected Definition at line 231 of file ai_rail.cpp.
	 */
	function GetRailToTrack(prev, cur_node, next) {
		if (prev == next || AIMap.DistanceManhattan(prev, cur_node) != 1 || AIMap.DistanceManhattan(cur_node, next) != 1) return AIRail.RAILTRACK_INVALID;
		local from = prev, tile = cur_node, to = next;
		if (next < prev) {
			from = next;
			to = prev;
		}
		if (tile - from == 1) {
			if (to - tile == 1) return AIRail.RAILTRACK_NE_SW;
			if (to - tile == AIMap.GetMapSizeX()) return AIRail.RAILTRACK_NE_SE;
		} else if (tile - from == AIMap.GetMapSizeX()) {
			if (tile - to == 1) return AIRail.RAILTRACK_NW_NE;
			if (to - tile == 1) return AIRail.RAILTRACK_NW_SW;
			if (to - tile == AIMap.GetMapSizeX()) return AIRail.RAILTRACK_NW_SE;
		} else {
			return AIRail.RAILTRACK_SW_SE;
		}
	}
	
	function BuildRail(path) {
		local prev = null;
		local prevprev = null;
		while (path != null) {
			if (prevprev != null) {
				if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
					if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
						if (!Debug.ResultOf(AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev), "Build rail tunnel")) {
							return false;
						}
					} else {
						local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
						bridge_list.Valuate(AIBridge.GetMaxSpeed);
						bridge_list.Sort(CLList.SORT_BY_VALUE, false);
						if (!Debug.ResultOf(AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile()), "Build rail bridge")) {
							return false;
						}
					}
					prevprev = prev;
					prev = path.GetTile();
					path = path.GetParent();
				} else {
					if (!AIRail.BuildRail(prevprev, prev, path.GetTile())) return false;
				}
			}
			if (path != null) {
				prevprev = prev;
				prev = path.GetTile();
				path = path.GetParent();
			}
		}
		return true;
	}
	
	function BuildDepotOnRail(path) {
		local p1 = null;
		local p2 = null;
		local p3 = null;
		local p4 = null;
		local p5 = null;
		local count = path.len();
		while (count > 0 ) {
			if (p5 != null) {
				if (XTile.IsStraight(p5, p3) && XTile.IsStraight(p4, p2) && XTile.IsStraight(p3, p1)) {
					foreach (body in XTile.Adjacent(p3)) {
						if (AITile.GetMaxHeight(body) != AITile.GetMaxHeight(p3)) continue;
						local exist = false;
						if (AIRail.IsRailDepotTile(body)) {
							if (AIRail.GetRailDepotFrontTile(body) != p3) continue;
							exist = true;
						} else {
							local test = AITestMode();
							if (!AIRail.BuildRailDepot(body, p3)) continue;
						}
						//build entry
						if (!AIRail.AreTilesConnected(p2, p3, body) && !AIRail.BuildRail(p2, p3, body)) continue;
						if (!AIRail.AreTilesConnected(p4, p3, body) && !AIRail.BuildRail(p4, p3, body)) continue;
						if (exist || AIRail.BuildRailDepot(body, p3)) return body;
					}
				}
			}
			p5 = p4;
			p4 = p3;
			p3 = p2;
			p2 = p1;
			p1 = path[count-1];
			count--;
		}
		return -1;
	}
	
	function BuildSignal(before, after, each) {
		local start = AIRail.GetRailDepotFrontTile(before);
		local end = AIRail.GetRailDepotFrontTile(after);
		local pt = Rail_PT();
		pt.InitializePath([[start, before]],[[end, after]],[]);
		local path = pt.FindPath(10000);
		if (!path) return false;
		
		local prev = null;
		local prevprev = null;
		local c = 0;
		while (path != null) {
			c++;
			if (prevprev != null) {
				if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
					//
				} else {
					if (c % each == 0)
						if (!AIRail.BuildSignal(prev, path.GetTile(), AIRail.SIGNALTYPE_PBS)) c--; 
				}
			}
			if (path != null) {
				prevprev = prev;
				prev = path.GetTile();
				path = path.GetParent();
			}
		}
		return true;
	}
}