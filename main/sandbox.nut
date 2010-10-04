// =======================================
// 9:10 AM Wednesday, February 04, 2009
// sandbox.nut
// =======================================
function CargoID_Of(CClass) {
// =======================================
    local cargos = AICargoList();
    cargos.Valuate(AICargo.HasCargoClass,CClass);
    cargos.KeepValue(1);
    return cargos.Begin();
}

function IsCargoFit(engine, cargo)
{return (AIEngine.GetCargoType(engine) == cargo) || AIEngine.CanRefitCargo(engine, cargo);}

// =======================================
function HighPriceCargos() {
// =======================================
    local cargos = AICargoList();
    cargos.Valuate(AICargo.GetCargoIncome,20,200);
    return cargos;
}

function NonStopOrder(addition) {
// =======================================
    if (addition == null) return AIOrder.AIOF_NON_STOP_INTERMEDIATE;
    return AIOrder.AIOF_NON_STOP_INTERMEDIATE | addition;
}
// =======================================
function HandleClosingIndustry(id, main)
{
  local station_list = Tiles.StationOn(AIIndustry.GetLocation(id));
  if (station_list.Count() == 0) return;
  //todo : handle it !
  local ind_type = AIIndustry.GetIndustryType(id);
  foreach (sta, val in station_list) {
    foreach (vhc, val in AIVehicleList_Station(sta)) {
        foreach (cargo, val in AIIndustryType.GetProducedCargo(ind_type).AddList(AIIndustryType.GetAcceptedCargo(ind_type))) {
            AIController.Sleep(1);
            if (Vehicles.CargoType(vhc) == cargo) main.old_vehicle.push(vhc);
        }
    }
  }
}

// ===================================
function NotOnWater(anIndustry) {
// ===================================
    anIndustry.Valuate(AIIndustry.IsBuiltOnWater);
    anIndustry.RemoveValue(1);
    return anIndustry;
}


function FrontMore(body, head, num =1)
{
  if (Tiles.NE_Of(body) == head) return Tiles.NE_Of(head, num);
  if (Tiles.NW_Of(body) == head) return Tiles.NW_Of(head, num);
  if (Tiles.SE_Of(body) == head) return Tiles.SE_Of(head, num);
  if (Tiles.SW_Of(body) == head) return Tiles.SW_Of(head, num);
}
// =======================================
// Force to Allocate an area of "tiles"
function AllocateLand(tiles) {
// =======================================
    local done=true;
    local sum = 0;
    foreach(tile, val in tiles) {
        sum += AITile.GetHeight(tile);
    }
    local avg = (sum / tiles.Count()).tointeger();
    AILog.Info("Done = " + done);
    local tile1 = -1, tile2 = -1;
    Hi_Lo_List(tiles, tile1, tile2);
    while (AITile.GetHeight(tile1) < avg) {
        break;
    }
    AITile.LevelTiles(tile1, tile2);
}

// =======================================
// Get Hi-Lo value of "list"
function Hi_Lo_List(list, highest, lowest) {
    list.Sort(AIAbstractList.SORT_BY_ITEM, true);
    lowest = list.Begin();
    local cpl = list;
    cpl.KeepBottom(1);
    highest = cpl.Begin();
    AILog.Info("list=" + list.Count() + " Hi= "+ highest + " Lo=" +lowest);
}


function sqrt(num)
{
  if (num == 0) return 0;
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

/**
  * Class for Map based on region radius 10
  *
  */
class MapBase
{
  _size_x = -1;
  _size_y = -1;
  constructor()
  {
    this._size_x = AIMap.GetMaxSizeX();
    this._size_y = AIMap.GetMaxSizeY();
  }
}
function MapBase::IsValid(base) {}
function MapBase::TileToBase(tile) {}
function MapBase::BaseTiles(base) {}
function MapBase::GetMaxX() {}
function MapBase::GetMaxY() {}
function MapBase::Count() {}

function CheckRail(path, new_tile)
{
    local new_cost = 0;
    local prev_tile = path.GetTile();
    local prev_prev = (path().GetParrent() == null) ? null : path().GetParrent().GetTile() ;
    if (!AIRail.AreTilesConnected(new_tile, prev_tile, path().GetParrent().GetTile())) new_cost = this._max_cost;
    return new_cost;
}

/**
 * General un categorized static functions to assist program
 */
class Assist
{
    /**
     * Check if this town can accept a cargo
     * @param id Town ID
     * @param cargo Cargo to check
     * @return True if this town can accept that cargo
     */
    static function TownCanAccept(id, cargo)
    {
        if (!AITown.IsValidTown(id)) return false;
        return Tiles.IsGoodAccept(AITown.GetLocation(id), cargo);
    }

    /**
     * Check if this town can produce a cargo
     * @param id Town ID
     * @param cargo Cargo to check
     * @return True if this town can produce that cargo
     */
    static function TownCanProduce(id, cargo)
    {
        if (!AITown.IsValidTown(id)) return false;
        return Tiles.IsGoodSource(AITown.GetLocation(id), cargo);
    }

    /**
     * Check if this industry can accept a cargo
     * @param id Industry ID
     * @param cargo Cargo to check
     * @return True if this industry can accept that cargo
     */
    static function IndustryCanAccept(id, cargo)
    {
        if (!AIIndustry.IsValidIndustry(id)) return false;
        local type = AIIndustry.GetIndustryType(id);
        if (!AIIndustryType.IsValidIndustryType(type)) return false;
        local list = AIIndustryType.GetAcceptedCargo(type);
        return list.HasItem(cargo);
    }

    /**
     * Check if this Industry can produce a cargo
     * @param id Industry ID
     * @param cargo Cargo to check
     * @return True if this Industry can produce that cargo
     */
    static function IndustryCanProduce(id, cargo)
    {
        if (!AIIndustry.IsValidIndustry(id)) return false;
        local type = AIIndustry.GetIndustryType(id);
        if (!AIIndustryType.IsValidIndustryType(type)) return false;
        local list = AIIndustryType.GetProducedCargo(type);
        return list.HasItem(cargo);
    }

    /**
     * Lead a number with zero
     * this will solve problem of '09' that displayed '9' only
     * @param integer_number to convert
     * @return number in string
     * @note only for number below 10
     */
    static function LeadZero(integer_number)
    {
        if (integer_number > 9) return integer_number.tostring();
        return "0" + integer_number.tostring();
    }

    /**
     * Convert date to it string representation in DD-MM-YYYY
     * @param date to convert
     * @return string representation in DD-MM-YYYY
     */
    static function DateStr(date)
    {
        return "" + AIDate.GetDayOfMonth(date) + "-" +   AIDate.GetMonth(date) + "-" + AIDate.GetYear(date);
    }

    /**
     * Hex to Decimal converter
     * @param Hex_number in string to convert
     * @return  number in integer
     * @note max number is 255 or FF
    */
    static function HexToDec(Hex_number)
    {
        if (Hex_number.length() > 2) return 0;
        local aSet = "0123456789ABCDEF";
        return aSet.find(Hex_number.slice(0,1)).tointeger() * 16 + aSet.find(Hex_number.slice(1,2)).tointeger();
    }

    /**
     * Push list to array
     */
    static function ListToArray(list)
    {
        local array = [];
        foreach(item, lst in list) array.push(item);
        return array;
    }

    /**
     * Make list from array
     */
    static function ArrayToList(array)
    {
        local list = AIList();
        foreach(idx, item in array) list.AddItem(item, 0);
        return list;
    }

    static function RoadDiscount(new_tile, prev_tile)
    {
        local new_cost = 0;
        if (AIBridge.IsBridgeTile(new_tile) && (AIBridge.GetOtherBridgeEnd(new_tile) == prev_tile)) {
            local b_id = AIBridge.GetBridgeID(new_tile);
            new_cost -= AIBridge.GetMaxSpeed(b_id)  + this._cost_bridge_per_tile;
        }
        if (AITunnel.IsTunnelTile(new_tile) && AITunnel.GetOtherTunnelEnd(new_tile) == prev_tile) {
            new_cost -= (this._cost_tile + this._cost_bridge_per_tile);
        }
        if (AIRoad.IsRoadTile(new_tile) && AIRoad.AreRoadTilesConnected(prev_tile, new_tile)) {
            new_cost -= this._cost_tile;
        }
        return new_cost * AIMap.DistanceManhattan(new_tile, prev_tile);
    }

    static function Connect_BackBone(main, serv)
    {
        AILog.Info("Try to connect backbone for id " + serv.ID);
        local _cost = 0;

        main.Rail.Path(serv, 1, true);
        main.State.TestMode = true;

        if (!main.Rail.Track(serv, 1)) {
            main.Rail.Path(serv, 1, true);
            if (!main.Rail.Track(serv, 1)) return false;
        }
        _cost += main.State.LastCost;
        main.Rail.Vehicle(serv);
        _cost += main.State.LastCost;
        main.Rail.Signal(serv, 0);
        _cost += main.State.LastCost;
        main.Rail.Signal(serv, 1);
        _cost += main.State.LastCost;
        if (!Bank.Get(_cost)) return false;

        main.State.TestMode = false;
        if (!main.Rail.Track(serv, 1)) {
            main.Rail.Path(serv, 1, true);
            if (!main.Rail.Track(serv, 1)) return false;
        }
        if (!main.Rail.Vehicle(serv)) return false;
        if (!main.Rail.Signal(serv, 0)) return false;
        if (!main.Rail.Signal(serv, 1)) return false;
        return true;
    }

    static function GetIDGroup(group_name)
    {
        return group_name.slice(2);
    }

    static function GetMiddleTile(_first, _end)
    {
    }

}

/**
 * Debug static functions class
 *
 */
class Debug
{
    /**
     * Evaluate expression, display message,  detect last error.
     * usable for in-line debugging
     * @param msg Message to be displayed
     * @param exp Expression to be displayed and returned
     * @return Value of expression
     */
    static function ResultOf(msg, exp)
    {
        if (AIError.GetLastError() == AIError.ERR_NONE) AILog.Info("" + msg + ":" + exp +" :Good Job");
        else AILog.Warning("" + msg + ":" + exp + ":" + AIError.GetLastErrorString().slice(4));
        /* no other methode found to clear last err */
        //AISign.RemoveSign(Debug.Sign(AIMap.GetTileIndex(2, 2), "debugger"));
        return exp;
    }

    /**
     * The function that should never called / passed by flow of code.
     * @param msg The message to be displayed
     */
    static function DontCallMe(msg, suspected = null)
    {
        /* I've said, don't call me. So why you call me ?
         * okay, I'll throw you out ! :-( */
        AILog.Warning("Should not come here! suspected --> " + suspected);
        throw (msg);
    }

    static function Sign(tile, txt)
    {
        if (1 == 1) return AISign.BuildSign(tile, txt);
    }
}

class Settings
{

    /* usage : AILog.Info(" you're run on " + Settings.Get(game.version)); */
    static function Get(setting_str)
    {
        return AIGameSettings.IsValid(setting_str) ? AIGameSettings.GetValue(setting_str) : null ;
    }
}

enum game {
    version = "version.version_string",
    subsidy_multiply = "difficulty.subsidy_multiplier",
    }


/**
 *  Depot & Station
 */
class Stations
{
    id = null;
    length = null;
    width = null;
    direction = null;
    platform = null;
    constructor()
    {
        this.id = -1;
        this.length = -1;
        this.width = -1;
        this.direction = -1;
        this.platform = {};
        this.platform[0] <- Platform();
    }

    static function RoadFor(cargo_id)
    {
        if (AICargo.HasCargoClass(cargo_id, AICargo.CC_PASSENGERS)) return AIRoad.ROADVEHTYPE_BUS;
        return AIRoad.ROADVEHTYPE_TRUCK;
    }

    static function RoadRadius() {return AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP );}
    static function RailRadius() {return AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);}

    function GetID() {return this.id;}
    function GetLength() {return this.length;}
    function GetWidth() {return this.width;}
    function GetDirection() {return this.direction;}
    function GetPlatform(idx) {return this.platform[idx];}
    function SetID(val) {this.id = val;}
    function SetLength(val) {this.length = val;}
    function SetWidth(val) {this.width = val;}
    function SetDirection(val) {this.direction = val;}
    function SetPlatform(idx, val) { this.platform[idx] <- val;}
    function SetupAllPlatform()
    {
        if (this.length < 2) return false;
        local func = null;
        local source = this.platform[0].GetBody();
        switch (this.direction) {
            case AIRail.RAILTRACK_NE_SW: func = Tiles.SE_Of; break;
            case AIRail.RAILTRACK_NW_SE: func = Tiles.SW_Of; break;
            //case 1: func = Tiles.SE_Of;
            //case 0: func = Tiles.SW_Of;
            default: Debug.DontCallMe("Setup Platform", this.direction);
        }
        for (local w = 1; w < this.length; w++) {
            local target = Platform();
            target.SetBody(func(source));
            target.SetHead(target.FindLastTile(this.direction, true, 1));
            target.SetBack(target.FindLastTile(this.direction, false));
            target.SetBackHead(target.FindLastTile(this.direction, false, 1));
            this.platform[w] <- target;
        }
    }

    function FindFree(platform_idx = 0)
    {
        local dtile = -1;
        local tile = this.platform[platform_idx].GetBody();
        switch (this.direction) {
            case AIRail.RAILTRACK_NE_SW:
                dtile = (AITile.IsBuildable(NE_Of(tile))) ? NE_Of(tile) : SW_Of(tile, this.length - 1);
                break;
            case AIRail.RAILTRACK_NW_SE:
                dtile = (AITile.IsBuildable(NW_Of(tile))) ? NW_Of(tile) : SE_Of(tile, this.length - 1);
                break;
            default: Debug.DontCallMe("FindFree", this.direction);
            break;
        }
        return dtile;
    }
}

class Platform
{
    body = null;
    head = null;
    back = null;
    backhead = null;
    constructor()
    {
        this.body = -1;
        this.head = -1;
        this.back = -1;
        this.backhead = -1;
    }
    function GetBody() { return this.body; }
    function GetHead() { return this.head; }
    function GetBack() { return this.back; }
    function GetBackHead() { return this.backhead;}
    function SetBody(val) { this.body = val; }
    function SetHead(val) { this.head = val; }
    function SetBack(val) { this.back = val; }
    function SetBackHead(val) { this.backhead = val; }
    function FindDirection(ind_object) {
    // ===================================
        // X + =  SW (left bottom) ; Y + =  SE (right bottom)
        local diffX = abs(AIMap.GetTileX(this.body) - AIMap.GetTileX(ind_object));
        local diffY = abs(AIMap.GetTileY(this.body) - AIMap.GetTileY(ind_object));
        local maxDiff = max(diffX, diffY);
        if (diffX < 0) return AIRail.RAILTRACK_NE_SW;
        if (diffY < 0) return AIRail.RAILTRACK_NW_SE;
        if (diffX < diffY) return AIRail.RAILTRACK_NW_SE;
        return AIRail.RAILTRACK_NE_SW;
    }

    // ===================================
    //return the NE of station if NE_SW direction
    // return the NW of station if NW_SE direction
    // ===================================
    //return the SW of station if NE_SW direction
    // return the SE of station if NW_SE direction
    function FindLastTile(dir, is_front = true, num = 0)
    {
        local tmp = this.body;
        if (!AIRail.IsRailStationTile(tmp)) return -1;
        local func = null;
        switch (dir)
        {
            case AIRail.RAILTRACK_NE_SW : func = is_front ? Tiles.NE_Of : Tiles.SW_Of; break;
            case AIRail.RAILTRACK_NW_SE : func = is_front ? Tiles.NW_Of : Tiles.SE_Of; break;
            default : Debug.DontCallMe("FindLastTile:" + is_front + " front", dir);
        }
        while (AIRail.IsRailStationTile(func(tmp))) tmp = func(tmp);
        if (num == 0) return tmp;
        return func(tmp, num);
    }

    static function RailTemplateNE_SW(base)
    {
        local to_build = [1, 2, 3, 7, 14, 18, 19, 20];
        local nese = [2, 8];
        local nwsw = [13, 19];
        local signal = [[3, 2], [7, 8], [14, 15], [18, 19]];
        local door = [[1, 2], [20, 21]];
        local _tmp = -1;
        while (to_build.len() > 0) {
            local c = to_build.pop();
            local x = c % 11;
            local y = (c - x) / 11;
            AIRail.BuildRailTrack(base + AIMap.GetTileIndex(x, y), AIRail.RAILTRACK_NE_SW);
        }
        while (nese.len() > 0) {
            local c = nese.pop();
            local x = c % 11;
            local y = (c - x) / 11;
            AIRail.BuildRailTrack(base + AIMap.GetTileIndex(x, y), AIRail.RAILTRACK_NE_SE);
        }
        while (nwsw.len() > 0) {
            local c = nwsw.pop();
            local x = c % 11;
            local y = (c - x) / 11;
            AIRail.BuildRailTrack(base + AIMap.GetTileIndex(x, y), AIRail.RAILTRACK_NW_SW);
        }
        while (signal.len() > 0) {
            local c = signal.pop();
            local x = c[0] % 11;
            local y = (c[0] - x) / 11;
            local xf = c[1] % 11;
            local yf = (c[1] - xf) / 11;
            AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_EXIT_TWOWAY);
        }
        while (door.len() > 0) {
            local c = door.pop();
            local x = c[0] % 11;
            local y = (c[0] - x) / 11;
            local xf = c[1] % 11;
            local yf = (c[1] - xf) / 11;
            AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_ENTRY_TWOWAY);
        }
    }

    static function RailTemplateNW_SE(base)
    {
        local to_build = [3, 5, 6, 7, 14, 15, 16, 18];
        local swse = [4, 16];
        local nenw = [5, 17];
        local signal = [[6, 4], [7, 5], [14, 16], [15, 17]];
        local door = [[3, 5], [18, 16]];
        local _tmp = -1;
        while (to_build.len() > 0) {
            local c = to_build.pop();
            local x = c % 2;
            local y = (c - x) / 2;
            AIRail.BuildRailTrack(base + AIMap.GetTileIndex(x, y), AIRail.RAILTRACK_NW_SE);
        }
        while (nenw.len() > 0) {
            local c = nenw.pop();
            local x = c % 2;
            local y = (c - x) / 2;
            AIRail.BuildRailTrack(base + AIMap.GetTileIndex(x, y), AIRail.RAILTRACK_NW_NE);
        }
        while (swse.len() > 0) {
            local c = swse.pop();
            local x = c % 2;
            local y = (c - x) / 2;
            AIRail.BuildRailTrack(base + AIMap.GetTileIndex(x, y), AIRail.RAILTRACK_SW_SE);
        }
        while (signal.len() > 0) {
            local c = signal.pop();
            local x = c[0] % 2;
            local y = (c[0] - x) / 2;
            local xf = c[1] % 2;
            local yf = (c[1] - xf) / 2;
            AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_EXIT_TWOWAY);
        }
        while (door.len() > 0) {
            local c = door.pop();
            local x = c[0] % 2;
            local y = (c[0] - x) / 2;
            local xf = c[1] % 2;
            local yf = (c[1] - xf) / 2;
            AIRail.BuildSignal(base + AIMap.GetTileIndex(x, y), base + AIMap.GetTileIndex(xf, yf), AIRail.SIGNALTYPE_ENTRY_TWOWAY);
        }
    }
}
