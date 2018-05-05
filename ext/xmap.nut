/**
 Project XMap for Buoys grid
*/

class XMap {
	static sizeX = 20;
	static sizeY = 20;
	/**
	* Generate Map Points, a grid X * Y
	
	function GenerateMapPoints() {
		local c = 0;				
		for (local x=1;x<AIMap.GetMapSizeX();x+=XMap.sizeX)
			for (local y=1;y<AIMap.GetMapSizeY();y+=XMap.sizeY) {
				local point = AIMap.GetTileIndex(x,y);
				if (!AIMap.IsValidTile(point)) continue;
				XMap.GetNeighbours(point);
				assert(XMap.TileIsPoint(point)); 
			}
		
		local tile = AIMap.GetTileIndex(35, 37);
		Debug.Sign(tile, "p");
		local point = XMap.GetPointIndex(tile);
		foreach(idx, val in XMap.GetBoundaries(tile)) Debug.Sign(idx, "M");
		Debug.Pause(-1,"");
	}
	*/
	
	/**
	*                                       |
	* Get Neighbours point of a point   --  P   --
	*                                       |
	*/
	function GetNeighbours(point) {
		assert(XMap.TileIsPoint(point));
		local list = CLList();
		list.AddTile(XTile.NE_Of(point, XMap.sizeX));
		list.AddTile(XTile.SW_Of(point, XMap.sizeX));
		list.AddTile(XTile.NW_Of(point, XMap.sizeY));
		list.AddTile(XTile.SE_Of(point, XMap.sizeY));
		return list;
	}
	
	/**
	* Check if a Tile is at Point
	*/
	function TileIsPoint(tile) {
		if (!AIMap.IsValidTile(tile)) return false;
		return (AIMap.GetTileX(tile) % XMap.sizeX == 1) && (AIMap.GetTileY(tile) % XMap.sizeY == 1);
	}
	
	/**
	* Check if a Tile is at Point
	*/
	function TileIsInGrid(tile) {
		if (!AIMap.IsValidTile(tile)) return false;
		return (AIMap.GetTileX(tile) % XMap.sizeX == 1) || (AIMap.GetTileY(tile) % XMap.sizeY == 1);
	}
	
	/**
	 * Get the index point of tile. That is the most North of area
	 */
	function GetPointIndex(tile) {
		if (XMap.TileIsPoint(tile)) return tile;
		if (!AIMap.IsValidTile(tile)) return -1;
		local pointX = (AIMap.GetTileX(tile) / XMap.sizeX).tointeger() * XMap.sizeX + 1;
		local pointY = (AIMap.GetTileY(tile) / XMap.sizeY).tointeger() * XMap.sizeY + 1;
		local point = AIMap.GetTileIndex(pointX, pointY);
		return point;
	}
	
	/**
	 * Get 4 point of Point from Point Index
	 */ 
	function GetBoundaries(tile) {
		local point = XMap.GetPointIndex(tile);
		local list = CLList();
		list.AddTile(point);
		list.AddTile(XTile.SW_Of(point, XMap.sizeX));
		list.AddTile(XTile.S_Of(point, XMap.sizeY));
		list.AddTile(XTile.SE_Of(point, XMap.sizeY));
		return list;
	}
	
	/**
	 * Get tiles of an area (inside boundaries)
	 */
	function GetTilesOfPoint(point) return XTile.MakeArea(point, XMap.sizeX, XMap.sizeY,0);
}