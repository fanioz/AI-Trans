
class Rail_PT extends Rail_PF{
	
	constructor() {
		Rail_PF.constructor();
		SetName("Road Finder");
	}
	
	function _Neighbours(path, cur_node)
	{
		if (!AITile.HasTransportType(cur_node, AITile.TRANSPORT_RAIL)) return []; 
		if (!XTile.IsMyTile(cur_node)) return [];
		/* this._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
		if (path.GetLength() > this._max_len) return [];
		if (path.GetCost() >= this._max_cost) return [];
		Debug.SignPF(cur_node,"r")
		local tiles = [];
		local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
		                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	
		/* Check if the current tile is part of a bridge or tunnel. */
		if (XTile.IsBridgeOrTunnel(cur_node)) {
			local other_end = XTile.GetBridgeTunnelEnd(cur_node);
			local next = XTile.NextTile(other_end, cur_node);
			if (AIRail.AreTilesConnected(path.GetParent().GetTile(), cur_node, next)) {
				tiles.push([next, this._GetDirection(cur_node, next, other_end, false), 0]);
			}
			/* The other end of the bridge / tunnel is a neighbour. Exist thus 0 cost*/
			tiles.push([other_end, this._GetDirection(next, cur_node, next, true), 0]);
		} else if (path.GetParent() != null && AIMap.DistanceManhattan(cur_node, path.GetParent().GetTile()) > 1) {
			//
		} else {
			/* Check all tiles adjacent to the current tile. */
			foreach (offset in offsets) {
				local next_tile = cur_node + offset;
				/* Don't turn back */
				if (path.GetParent() != null && next_tile == path.GetParent().GetTile()) continue;
				/* Disallow 90 degree turns */
				if (path.GetParent() != null && path.GetParent().GetParent() != null &&
					next_tile - cur_node == path.GetParent().GetParent().GetTile() - path.GetParent().GetTile()) continue;
				if (path.GetParent() != null) { 
					if (AIRail.AreTilesConnected(path.GetParent().GetTile(), cur_node, next_tile)){
						tiles.push([next_tile, this._GetDirection(path.GetParent().GetTile(), cur_node, next_tile, false), 0]);
						continue;
					}
				} else {
					tiles.push([next_tile, this._GetDirection(null, cur_node, next_tile, false), buildCost]);
				}
				/* We add them to the to the neighbours-list if the rail exists there. */
			}
		}
		return tiles;
	}
}
