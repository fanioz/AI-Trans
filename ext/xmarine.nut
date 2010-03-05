/*  10.02.27 - XMarine.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XMarine class
 * an AIMarine eXtension
 */
class XMarine {
	function BuildDepot (tile, area) {
		Info ("Building new Water Depot");
		if (area.IsEmpty()) return -1;
		local ecost = AIMarine.GetBuildCost(AIMarine.BT_DEPOT);
		Info ("est. Cost", ecost);
		if (!Money.Get(ecost)) return -1;
		foreach (body, v in area) {
			if (body == tile) continue;
			foreach (head in XTile.Adjacent(body)) {
				if (!AITile.IsWaterTile(head)) continue;
				if (!AITile.IsWaterTile(XTile.NextTile(body, head))) continue;
				if (!XMarine.IsConnectedTo([head], [tile])) continue;
				if (AIMarine.BuildWaterDepot (body, head)) {
					Money.Pay();
					return body;
				}
			}
		}
		Money.Pay();
		return -1;
	}
	
	function FindPath(start, finish, ignored) {
		local pf = Water_PF();
		pf.InitializePath (start, finish, ignored);
		return pf.FindPath(-1);
	}
	function IsConnectedTo(tile1, tile2) {
		foreach (idx, tilea in tile1) {
			foreach (idx, tileb in tile2) {
				if (AIMarine.AreWaterTilesConnected(tilea, tileb)) return true;
			}
		}
		local pf =  Water_PT();
		pf.InitializePath (tile1, tile2, []);
		return (typeof pf.FindPath (-1)) == "instance";
	}
	
	function BuilderStation (tile, area) {
		local restriction = CLList();
		Info ("Building new Dock");
		if (area.IsEmpty()) return -1;
		foreach (body, v in area) {
			local head = XMarine.GetWaterSide(body);
			if (head == tile) continue; 
			local path = XMarine.FindPath([head], [tile], restriction.GetItemArray());
			if (path == null) continue;
			local ecost = AIMarine.GetBuildCost(AIMarine.BT_DOCK) + path.GetCost();
			Info ("est. Cost", ecost);
			if (!Money.Get(ecost)) continue;
			if (AIStation.IsValidStation(XMarine.BuildDock(body))) {
				Info ("we've just build a dock" );
				if (XMarine.IsConnectedTo([tile], [head])) return body;
				AIMarine.RemoveDock(body);
			}
		}
		Warn ("building dock failed");
		Money.Pay();
		return -1;
	}
	
	function BuildDock (tile)
	{
		local retry = 20;
		local st_id = XStation.FindIDNear (tile, 15);
		while (retry > 0) {
			retry--;
			local is_built = AIMarine.BuildDock (tile, st_id)
			if (is_built) {
				return AIStation.GetStationID(tile);
			} else {
				Warn("failed:" , AIError.GetLastErrorString());
				switch (AIError.GetLastError()) {
					case AIError.ERR_AREA_NOT_CLEAR:
						if (!AITile.DemolishTile (tile)) retry = 0;
					case AIError.ERR_SITE_UNSUITABLE:
						break;
					case AIError.ERR_VEHICLE_IN_THE_WAY:
						AIController.Sleep (5 * retry + 1);
						break;
					case AIError.ERR_STATION_TOO_SPREAD_OUT:
					case AIStation.ERR_STATION_TOO_CLOSE_TO_ANOTHER_STATION:
						st_id = XStation.FindIDNear (tile, 0);
						break;
					default:
						Debug.Say(["un-handled:" , AIError.GetLastErrorString()], 2);
						//Debug.Halt (tile);
						AIController.Sleep (5);
						retry = 0;
				}
			}
		}
		return -1;
	}
	
	function GetWaterSide(tile) {
		foreach (neigh in XTile.Adjacent(tile)) {
			if (AITile.IsWaterTile(neigh)) return neigh;
		}
		return -1;
	}
	
	function BuildPath(path) {
		Info ("Start building", path.GetLength(), "tiles");
		local last_node = path.GetTile();
		local next = path.GetParent();
		while (next) {			
			local next_node = next.GetTile();
			if (AIMap.DistanceManhattan (last_node, next_node) > 1) {
				Info ("bridge/tunnel should not been built");
			} else {
				Debug.Sign(last_node, next.GetCost());
				//build double straight tile
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
					 ignore.push(next_node);
					return XRoad.BuildRoute (null, start, finish, ignore, num);
				}
			}
			last_node = next_node;
			next = next.GetParent();
		}
		return XMarine.IsConnectedTo(start, finish);
	}
}
