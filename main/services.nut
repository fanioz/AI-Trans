/*
 *      09.02.23
 *      services.nut
 *
 *      Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */

/**
 * Base Services class for store either town or industry handling in game
 */
class Services
{
    ID = null;
    Name = null;
    Location = null;
    IsTown = null;
    Area =  null;
    Stations = null;
    Depots = null;
    LastMonthTransported = null;

    constructor(id)
    {
        this.ID = id;
        this.Name = "";
        this.Location = -1;
        this.IsTown = false;
        this.Area =  AITileList();
        this.Stations = null;
        this.Depots = null;
        this.LastMonthTransported = null;
    }

    /**
     * Refresh information stored by this class.
     */
    function Refresh();
    function IsValid();

    /**
     * Make a new table of service
     * @param srcid Source ID of service
     * @param dstid Destination ID of service
     * @param cargoid Cargo ID of service
     * @return new table of service
     */
    static function NewTable(srcid, dstid, cargoid);

    /**
     * Update other value with API framework and
     * @param tabel the table to update
     * @return  new updated table
     */
    static function RefreshTable(tabel);

    /**
     * Make service ID
     * @param source Source ID
     * @param dest Destination ID
     * @param cargo Cargo ID
     * @return ID of service table
     */
    static function CreateID(source, dest, cargo)
    {
        return Assist.LeadZero(source) + ":" + Assist.LeadZero(dest) + ":" + Assist.LeadZero(cargo) ;
    }
}

/**
 * Inheritance of Services class for store town handling in game
 */
class TownServices extends Services
{
    constructor(id)
    {
        ::Services.constructor(id);
    }

    function Refresh()
    {
        this.Name = AITown.GetName(this.ID);
        this.Location = AITown.GetLocation(this.ID);
        this.IsTown = true;
        this.Area = Tiles.OfTown(this.ID, (Tiles.Radius(this.Location, 20)));
        this.LastMonthTransported = AITown.GetLastMonthTransported;
        ::Services.Refresh();
    }

    function IsValid() {return AITown.IsValidTown(this.ID);}

}

/**
 * Inheritance of Services class for store industry handling in game
 */
class IndustryServices extends Services
{
    constructor(id)
    {
        ::Services.constructor(id);
    }

    function Refresh()
    {
        this.Name = AIIndustry.GetName(this.ID);
        this.Location = AIIndustry.GetLocation(this.ID);
        this.Area =  AITileList_IndustryProducing(this.ID, 10);
        if (this.Area.IsEmpty()) this.Area = AITileList_IndustryAccepting(this.ID, 10);
        this.LastMonthTransported = AIIndustry.GetLastMonthTransported;
        ::Services.Refresh();
    }

    function IsValid() {return AIIndustry.IsValidIndustry(this.ID);}
}

function Services::NewTable(srcid, dstid, cargoid)
{
    local tabel = {
        ID = Services.CreateID(srcid, dstid, cargoid),
        Source = Assist.IndustryCanProduce(srcid, cargoid) ? IndustryServices(srcid) : TownServices(srcid) ,
        Destination = Assist.IndustryCanAccept(dstid, cargoid) ? IndustryServices(dstid) : TownServices(dstid),
        Cargo = cargoid
    }
    /*refresh*/
    tabel.Source.Refresh();
    tabel.Destination.Refresh();
    return tabel
}

function Services::RefreshTable(tabel)
{
    tabel.Source.Refresh();
    tabel.Destination.Refresh();
    tabel.Distance <- AIMap.DistanceManhattan(tabel.Source.Location, tabel.Destination.Location);
    local distmax = AIMap.DistanceMax(tabel.Source.Location, tabel.Destination.Location);
    if (tabel.Source.IsTown || tabel.Destination.IsTown || distmax < 20) {
        tabel.TrackType <- AIRoad.ROADTYPE_ROAD;
        tabel.VehicleType <- AIVehicle.VT_ROAD;
    } else {
        tabel.VehicleType <- AIVehicle.VT_RAIL;
        tabel.TrackType <- AIRailTypeList().Begin();
    }
    tabel.CargoStr  <- AICargo.GetCargoLabel(tabel.Cargo);
    tabel.CargoIsFreight <- AICargo.IsFreight(tabel.Cargo);
    tabel.MainVhcID <- -1;
    tabel.IsSubsidy <- false;
    tabel.IgnorePath <- AITileList();
    tabel.Readable <- tabel.CargoStr + " from " + tabel.Source.Name + " to " + tabel.Destination.Name;
    return tabel;
}
