/*  10.02.27 - Infrastructure.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */


/**
 * Infrastructure  station
 */
class Infrastructure extends CIDLocation {
    /* Use : AIVehicle::VehicleType
    * The type of a vehicle available in the game.
    * Trams for example are road vehicles, as maglev is a rail vehicle.
    * Enumerator:
    * VT_RAIL  Rail type vehicle.
    * VT_ROAD  Road type vehicle (bus / truck).
    * VT_WATER  Water type vehicle.
    * VT_AIR  Air type vehicle.
    * VT_INVALID  Invalid vehicle type.
    */
    _vtype = null; ///< Vehicle Type
    _cargo = null; ///cargo id
    /**
     * class constructor
     */
    constructor(id, loc) {
        CIDLocation.constructor(id, loc);
        _vtype = AIVehicle.VT_INVALID;
        _cargo = -1;
    }

    /**
     * Get Vehicle type
     */
    function GetVType() {
        return _vtype;
    }

    /**
     * Set Transport vehicle type
     */
    function SetVType(type) {
        _vtype = type;
    }
    /**
     * Get Cargo of infrastructure
     */
    function GetCargo() {
        return _cargo;
    }
    /*
     * Set Cargo of infrastructure
     */
    function SetCargo(c) {
        _cargo = c;
    }
}
