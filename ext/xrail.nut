/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
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
		        AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev);
		      } else {
		        local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
		        bridge_list.Valuate(AIBridge.GetMaxSpeed);
		        bridge_list.Sort(CLList.SORT_BY_VALUE, false);
		        AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile());
		      }
		      prevprev = prev;
		      prev = path.GetTile();
		      path = path.GetParent();
		    } else {
		      AIRail.BuildRail(prevprev, prev, path.GetTile());
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
