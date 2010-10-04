/*  09.05.10 - cargo.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA 02110-1301, USA.
 */

/**
 * Cargo class extend AICargo
 */
class Cargo
{
	/**
	 * Get list of ID for the cargo class
	 * @param CClass class of cargo
	 * @return AICargoList
	 */
	static function ListOfClass(CClass) {
		local cargos = AICargoList();
		cargos.Valuate(AICargo.HasCargoClass,CClass);
		cargos.KeepValue(1);
		return cargos;
	}

	/**
	 * Check to see if cargo is fit-able with engine
	 * @param engine to check
	 * @param cargo to check
	 * @return true if fit or fit-able
	 */
	static function IsFit(engine, cargo)
	{
		return (AIEngine.GetCargoType(engine) == cargo) ||
		AIEngine.CanRefitCargo(engine, cargo);
	}

	/**
	 * Sort cargo list by income
	 * @return Sorted AICargoList by price
	 */
	static function Sorted() {
		local cargos = AICargoList();
		cargos.Valuate(AICargo.GetCargoIncome,20,200);
		return cargos;
	}

	/**
	 * Check if this cargo has effect on a town.
	 * @param cargo The cargo to check on.
	 * @return True if and only if the cargo has effect on a town.
	 */
	static function HasTownEffect(cargo) {
		local te = AICargo.GetTownEffect(cargo);
		return (te == AICargo.TE_PASSENGERS ||
			te == AICargo.TE_MAIL ||
			te == AICargo.TE_GOODS ||
			te == AICargo.TE_WATER ||
			te == AICargo.TE_FOOD );
	}

	 /**
     * Check if this town can accept a cargo
     * @param id Town ID
     * @param cargo Cargo to check
     * @return True if this town can accept that cargo
     */
    static function TownCanAccept(id, cargo)
    {
        if (!AITown.IsValidTown(id)) return false;
		if (!Cargo.HasTownEffect(cargo)) return false;
        return AITile.GetCargoAcceptance(AITown.GetLocation(id), cargo, 1, 1, 5) > 7;
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
        return AITown.GetMaxProduction(id, cargo) > 0;
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
	 * Creates a list of town that can produce a given cargo.
	 * @param cargo The cargo this town should produce.
	 * @return AITownList that produce a given cargo.
	 */
	static function TownList_Producing(cargo)
	{
		local tl = AITownList();
		Assist.Valuate(tl, Cargo.TownCanProduce, cargo);
		tl.RemoveValue(0);
		return tl;
	}

	/**
	 * Creates a list of town that accepts a given cargo.
	 * @param cargo The cargo this town should accept.
	 * @return AITownList that accepts a given cargo.
	 */
	static function TownList_Accepting(cargo)
	{
		local tl = AITownList();
		Assist.Valuate(tl, Cargo.TownCanAccept, cargo);
		tl.RemoveValue(0);
		return tl;
	}
}
