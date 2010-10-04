// =======================================
// 9:10 AM Wednesday, February 04, 2009
// misc.nut
// =======================================
class PosClass
{
  Body = null;
  Head = null;
  ID = null;
  constructor()
  {
    this.Body = -1;
    this.Head = -1;
    this.ID = -1;
  }
}
// Convert date to string D-M-Y
function DateStr(date) {
// =======================================
	return "" + AIDate.GetDayOfMonth(date) + "-" +	 AIDate.GetMonth(date) + "-" + AIDate.GetYear(date);
}
// =======================================
// Get Radius of Road Station
function RoadStationRadius(vhcType) {
// =======================================
	return AIStation.GetCoverageRadius((vhcType == AIRoad.ROADVEHTYPE_BUS) ? AIStation.STATION_BUS_STOP : AIStation.STATION_TRUCK_STOP );
}
// =======================================
// Get Radius of Rail Station
function RailStationRadius() {
// =======================================
	return AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
}
// =======================================
// return cargoID for cargo "class"
function CargoID_Of(CClass) {
// =======================================
	local cargos = AICargoList();
	cargos.Valuate(AICargo.HasCargoClass,CClass);
	cargos.RemoveValue(0);
	return cargos.Begin();
}
// =======================================
// Get tile of My station arround "base"
function MyStationTile(base) {
// =======================================
	local area = Tile.Radius(base,10);
	area.Valuate(Tile.IsMine);
	area.RemoveValue(0);
	area.Valuate(AITile.IsStationTile);
	area.RemoveValue(0);
  area.Valuate(AITile.GetDistanceManhattanToTile, base);
  area.Sort(AIAbstractList.SORT_BY_VALUE, true);
	return area;
}


// =======================================
// Push list to array
function ListToArray(list) {
// =======================================
	local array = [];
	foreach(item, lst in list) {
		array.push(item);
	}
	return array;
}
// =======================================
// Make list from array
function ArrayToList(array) {
// =======================================
	local list = AIList();
	foreach(item in array) {
		list.AddItem(item, 0);
	}
	return list;
}

// =======================================
function SpeedyRoadEngine() {
// =======================================
	local englst = AIEngineList(AIVehicle.VT_ROAD);
	englst.Valuate(AIEngine.IsArticulated);
	englst.KeepValue(0);
	englst.Valuate(AIEngine.GetRoadType);
	englst.KeepValue(AIRoad.ROADTYPE_ROAD);
	englst.Valuate(AIEngine.GetMaxSpeed);
	englst.Sort(AIAbstractList.SORT_BY_VALUE, false);
	return englst;
}
// =======================================
function HighPriceCargos() {
// =======================================
	local cargos = AICargoList();
	cargos.Valuate(AICargo.GetCargoIncome,20,200);
	return cargos;
}
// =======================================
function IsMyStation(tile) {
// =======================================
return AITile.IsStationTile(tile) && Tile.IsMine(tile);;
}
// =======================================
function NonStopOrder(addition) {
// =======================================
	if (addition == null) return AIOrder.AIOF_NON_STOP_INTERMEDIATE;
	return AIOrder.AIOF_NON_STOP_INTERMEDIATE | addition;
}
// =======================================
function HandleClosingIndustry(id)
{
  //todo : handle it !
}
// =======================================
function StartClonedVehicle(VhcID, DepotX, number) {
// =======================================
  local built = 0;
  AILog.Info("Try clone " + number + " Vehicle");
	for (local x = 0; x < number; x++) {
		if (AIVehicle.StartStopVehicle(AIVehicle.CloneVehicle (DepotX, VhcID, true))) built++;
	}
	return built;
}
// =======================================
function UpgradeVehicleEngine(engine_id_new) {
	AILog.Info("Try Upgrading Vehicle");
	local gl = AIGroupList();
  for(local ID_g = gl.Begin(); gl.HasNext() ; ID_g = gl.Next()) {
    local vl = AIVehicleList();
    vl.Valuate(AIVehicle.GetGroupID);
    vl.KeepValue(ID_g);
    local engine_id_old = AIVehicle.GetEngineType(vl.Begin());
    if ((AIEngine.GetCargoType(engine_id_new) == AIEngine.GetCargoType(engine_id_old)) &&
      (AIEngine.GetVehicleType(engine_id_new) == AIEngine.GetVehicleType(engine_id_old))) {
      AIGroup.SetAutoReplace(ID_g,	engine_id_old,	engine_id_new	);
      /* it slightly hard to replace also using .EngineCanRefitCargo without table*/
      ErrMessage("Upgrading " + AIEngine.GetName(engine_id_old) + " to " + AIEngine.GetName(engine_id_new));
    }
  }
}
// =======================================
function RoadStationOf(cargo) {
// =======================================
	return (AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS)) ? AIRoad.ROADVEHTYPE_BUS : AIRoad.ROADVEHTYPE_TRUCK;
}

// ===================================
// print "msg" following error
function ErrMessage(msg) {
// ====================================
	if (AIError.GetLastError()==AIError.ERR_NONE) AILog.Info("" + msg + " -> Good Job :-D");
		else AILog.Warning("" + msg + "->" + AIError.GetLastErrorString().slice(4));
}
// usage :
// done = MsgResult("Build x", AIBuild.X);
// evaluate exp, display msg, optionally detect err
function MsgResult(msg, exp)
{
  ErrMessage("" + msg + "->" + exp);
  return exp;
}
// ===================================
function RailStationDirection(sta, Obj) {
// ===================================
	local diffx = AIMap.GetTileX(Obj) - AIMap.GetTileX(sta);
	local diffy = AIMap.GetTileY(Obj) - AIMap.GetTileY(sta);
	if (AIMap.GetTileX(Obj) > AIMap.GetTileX(sta)) return AIRail.RAILTRACK_NE_SW;
	if (AIMap.GetTileY(Obj) > AIMap.GetTileY(sta)) return AIRail.RAILTRACK_NW_SE;
	if (diffx < 1) return AIRail.RAILTRACK_NE_SW;
	if (diffy < 1) return AIRail.RAILTRACK_NW_SE;
	if (diffx < 3 && diffy > 3) return AIRail.RAILTRACK_NW_SE;
	
	// I cant make decision here
	return AIRail.RAILTRACK_NE_SW;
}
// ===================================
function DirectionTile(dir,tile) {
// ===================================
	local dtile = -1;
	switch (dir) {
		case AIRail.RAILTRACK_NE_SW:
		dtile = (AITile.IsBuildable(NE_Of(tile))) ? NE_Of(tile) : SW_Of(tile,3);
		break;
		case AIRail.RAILTRACK_NW_SE:
		dtile = (AITile.IsBuildable(NW_Of(tile))) ? NW_Of(tile) : SE_Of(tile,3);
		break;
		default:
		break;
	}
	return dtile;
}
// ===================================
function NotOnWater(anIndustry) {
// ===================================
	anIndustry.Valuate(AIIndustry.IsBuiltOnWater);
	anIndustry.RemoveValue(1);
	return anIndustry;
}
// ===================================
//return the NE of station if NE_SW direction
// return the NW of station if NW_SE direction
function GetRailStationFrontTile(st_tile, num = 1) {
// ===================================
	if (!AIRail.IsRailStationTile(st_tile)) return -1;
	local dir = AIRail.GetRailStationDirection(st_tile);
	if (dir == 0) return Tile.NE_Of(st_tile, num);
  if (dir == 1)	return Tile.NW_Of(st_tile, num);
  return -1;
}
// ===================================
//return the SW of station if NE_SW direction
// return the SE of station if NW_SE direction
function GetRailStationBackTile(st_tile, num = 1) {
// ===================================
if (!AIRail.IsRailStationTile(st_tile)) return -1;
  local count = 1;
  local dir = AIRail.GetRailStationDirection(st_tile);
	if (dir == 0){
		while (count < num || AIRail.IsRailStationTile(st_tile)) {
		  if (!AIRail.IsRailStationTile(st_tile)) count++;
			st_tile = Tile.SW_Of(st_tile);
		}
    return st_tile;
	}
  if (dir == 1) {
		while (count < num || AIRail.IsRailStationTile(st_tile)) {
		  if (!AIRail.IsRailStationTile(st_tile)) count++;
			st_tile = Tile.SE_Of(st_tile); 
		}
		return st_tile;
  }
		return -1;
}
// ===================================

// ===================================
// Get the front of tile station "tile" against "ind_object"
// It means "ind_object" should be behind "tile"
// behind mean back of road station or the widest part of rail station
// most used for industry
function FrontOf(tile, ind_object) {
// ===================================
// X + =  SW (left bottom) ; Y + =  SE (right bottom)
	local diffX = AIMap.GetTileX(tile) - AIMap.GetTileX(ind_object);
	local diffY = AIMap.GetTileY(tile) - AIMap.GetTileY(ind_object);
	local face = Tile.SW_Of(tile);
	if (diffX <= 0) face = Tile.NE_Of(tile);
	if (diffY <= 0) face = Tile.NW_Of(tile);	
	return face;
}
// =======================================
// Force to Allocate an area of "tiles"
function AllocateLand(tiles) {
// =======================================
	local done=true;
	foreach(tile in tiles) {
		done = done && AITile.DemolishTile(tile);
	}
	AILog.Info("Done = " + done);
	local tile1 = -1, tile2 = -1;
	Hi_Lo_List(tiles, tile1, tile2);
	AITile.LevelTiles(tile1,tile2);
}

// =======================================
// Get Hi-Lo value of "list"
function Hi_Lo_List(list, highest, lowest) {
	list.Sort(AIAbstractList.SORT_BY_VALUE,true);
	lowest = list.Begin();
	highest = lowest;
	while (list.HasNext()) {
		highest = list.Next();
	}
	AILog.Info("list=" + list.Count() + " Hi= "+ highest + " Lo=" +lowest);	
}


function sqrt(num)
{
  if (num == 0)	return 0;
  local n = (num / 2) + 1;
  local n1 = (n + (num / n)) / 2;
  while (n1 < n) {
		n = n1;
		n1 = (n + (num / n)) / 2;
  }
  return n;
}

function RPFCostBased(tile_cost)
{
	local Finder = RoadPathFinder();
	Bank.Get(null);
	Finder.cost.max_cost = Bank.Balance();
	AILog.Info("Tile Cost =" + tile_cost);
  Finder.cost.tile = tile_cost *0.1;
	Finder.cost.no_existing_road = tile_cost;
  Finder.cost.turn = tile_cost * 3;
	Finder.cost.slope = 2 * tile_cost;
  Finder.cost.bridge_per_tile = 6 * tile_cost;
	Finder.cost.tunnel_per_tile = 10 * tile_cost;
  Finder.cost.coast = 4 * tile_cost;
	Finder.cost.crossing = 12 * tile_cost;
  //Finder.cost.NonFreeTile = 5 * tile_cost;
	Finder.cost.demolition = 12 * tile_cost;
	return Finder;
}
// ===================================
// Try to build  drive thru station on "town" with "cargoID"
// this is the last option due to unable to build normal station.
// the articulated vehicle will need this type of station
function TownDTRS() {
// ===================================
	while (!done && rad < 20) {
	  ///local heads = Tile.Flat(Tile.Roads(Tile.Radius(service.Info.SourcePos, rad)));
	  /// use above if rail is ready
	  local heads = Tile.Flat(Tile.Radius(service.Info.SourcePos, rad));
	  heads = (service.Info.SourceIsTown) ? Tile.Roads(heads) : heads ;
	  local head = heads.Begin();	  
	  while (!done) {
	    local bodies = Tile.BodiesOf(head);
	    local body = bodies.Begin();
	    while (!done) {
	      if (AIMap.IsValidTile(head)) {
	        if (!Tile.IsMine(body)) AITile.DemolishTile(body);
	        done = AIRoad.BuildRoadStation (body, head, RoadStationOf(service.Info.CargoID), AIStation.STATION_JOIN_ADJACENT) ||
					AIRoad.BuildDriveThroughRoadStation (head, body, RoadStationOf(service.Info.CargoID), AIStation.STATION_JOIN_ADJACENT);
	        AISign.BuildSign(body,"b");
	        ErrMessage("Road Station at " + service.Info.SourceText);
				  if (done) {
				    AIRoad.BuildRoadFull(head,body);
				    service.Info.Depot = body;
				    return true;
				  }
				  AIController.Sleep(1);
				}
			if (!bodies.HasNext()) break;
			body = bodies.Next();
		}
		if (!heads.HasNext()) break;
		head = heads.Next();
    }ErrMessage("DTRS at " + AITown.GetName(town));
	return pos;
}

// ===================================
// build the initialized path if found
function Rail(path) {
// ===================================
	local prev = null;
	local prevprev = null;
	while (path != null) {
		 if (prevprev != null) {
		 	if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
		 		if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
		 			AITunnel.BuildTunnel(AIVehicle.VEHICLE_RAIL, prev);
		 		}
		 		else {
		 			local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
		 			bridge_list.Valuate(AIBridge.GetMaxSpeed);
		 			bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
		 			AIBridge.BuildBridge(AIVehicle.VEHICLE_RAIL, bridge_list.Begin(), prev, path.GetTile());
		 		}
		 		prevprev = prev;
		 		prev = path.GetTile();
		 		path = path.GetParent();
		 	}
		 	else {
		 		AIRail.BuildRail(prevprev, prev, path.GetTile());
		 	}
		 }
		 if (path != null) {
		 	prevprev = prev;
		 	prev = path.GetTile();
		 	path = path.GetParent();
		 }
	 }
}
}

/**
* Handle the lost vehicle, as AIEventController.InsertEvent can't be used ?
* 
* - Unshare the vehicle order
* - Remove all order still there
* - Give a try to send vehicle to depot
* @param vhc_ID The ID of vehicle to handle
*/
function HandleVehicleLost(vhc_ID)
{
  AIController.Sleep(10);
  AIOrder.UnshareOrders(vhc_ID);
  while (AIOrder.GetOrderCount(vhc_ID) > 1) AIOrder.RemoveOrder(vhc_ID, 0);
  local retry = 10;
	while (!AIVehicle.SendVehicleToDepot(vhc_ID) && retry > 0) {
    AIController.Sleep(retry * 10);
    ErrMessage("Sending vehicle to depot");
    if (AIVehicle.IsStoppedInDepot(vhc_ID)) return;
    retry --;
  }
}

/**
* Handle Un profitable vehicle
*
* @param vhc_ID The ID of vehicle to handle
*/
function HandleUnprofitable(vhc_ID)
{
  //if (AIVehicle.GetProfitLastYear(vhc_ID) > 0) return false;
  //if (AIVehicle.GetProfitThisYear(vhc_ID) > 0) return false;
  AILog.Info("It would be better if I sell " + vhc_ID + " anyway");
  /* But, I only delete your source station only and mark you as a loss vehicle :) */
  AIOrder.UnshareOrders(vhc_ID);
  /* AIOrder.SkipOrder(now available) */
  AIController.Sleep(10);
	if (AIOrder.ResolveOrderPosition(vhc_ID, AIOrder.ORDER_CURRENT) < 2) AIOrder.SkipToOrder(vhc_ID, 2);
  if (AIVehicle.GetCargoLoad(vhc_ID, VehicleCargo(vhc_ID)) == 0) HandleVehicleLost(vhc_ID);
} 	
/**
* Get cargo of vehicle by check it engine
* @param vhc_ID The ID of vehicle
* @return cargoID of that vehicle
*/
function VehicleCargo(vhc_ID)
{
 return AIEngine.GetCargoType(AIVehicle.GetEngineType(vhc_ID));
}

/**
* Lead a number with zero
* this will solve problem of '09' that displayed '9' only
* @param integer_number to convert
* @return number in string
* @note only for number below 10
*/
function LeadZero(integer_number)
{
  if (integer_number > 9) return integer_number.tostring();
  return "0" + integer_number.tostring();
}

/**
* Hex to Decimal converter
* @param Hex_number in string to convert
* @return  number in integer
* @note max number is 255 or FF
*/
function HexToDec(Hex_number)
{
  if (Hex_number.length() > 2) return 0;
  local aSet = "0123456789ABCDEF";
  return aSet.find(Hex_number.slice(0,1)).tointeger() * 16 + aSet.find(Hex_number.slice(1,2)).tointeger();
}

