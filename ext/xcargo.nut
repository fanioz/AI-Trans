/*  10.02.27 - cargo.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XCargo class 
 * an AICargo eXtension
 */
class XCargo
{
	static Pax_ID = -1;
	static Mail_ID = -1;
	static TownEffect = CLList();
	static TownStd = CLList();
	static Label = {};

	function Init(ccargo) {
		local t = AITownList();
		t.Valuate (AITown.GetPopulation);
		local biggest = t.Begin();
		local lst = CLList(AICargoList());
		ccargo.Label[-1] <- "invalid cargo!";
		Info ("Known cargo type");
		foreach (cargo, cls in lst) {
			local label = AICargo.GetCargoLabel (cargo);
			ccargo.Label[cargo] <- label;
			if (!XCargo.HasTownEffect (cargo)) continue;
			if (AICargo.HasCargoClass (cargo, AICargo.CC_PASSENGERS) && XTown.CanAccept (biggest, cargo)) {
				ccargo.Pax_ID <- cargo
				Info ("Pax:", ccargo.Pax_ID, "as", label);
				ccargo.TownStd.AddItem (cargo, 0);
			} else if (AICargo.HasCargoClass (cargo, AICargo.CC_MAIL)) {
				ccargo.Mail_ID <- cargo
				Info ("Mail:", ccargo.Mail_ID, "as", label);
				ccargo.TownStd.AddItem (cargo, 0);
			} else {
				ccargo.TownEffect.AddItem (cargo, 0);
				Info ("TE:", cargo, "as", label);
			}
		}
	}

	function IsAcceptedTown(cargo, twn) {
		return XTown.CanAccept (twn, cargo);
	}

	/**
	 * Check if this cargo has effect on a town.
	 * @param cargo The cargo to check on.
	 * @return True if and only if the cargo has effect on a town.
	 */
	function HasTownEffect(cargo) {
		switch (AICargo.GetTownEffect (cargo)) {
			case AICargo.TE_PASSENGERS:
			case AICargo.TE_MAIL:
			case AICargo.TE_GOODS:
			case AICargo.TE_FOOD:
				return true;
			default :
				return false;
		}
	}

	/**
	* Check if this tile can accept a cargo
	* @param tile Tile Index
	* @param cargo Cargo to check
	* @return True if this tile can accept that cargo
	*/
	function TileCanAccept(tile, cargo) {
		return AITile.GetCargoAcceptance (tile, cargo, 1, 1, 3) > 7;
	}

	/**
	 * Check if this tile can accept a cargo
	 * @param tile Tile Index
	 * @param cargo Cargo to check
	 * @return True if this tile can accept that cargo
	 */
	function TileCanProduce(tile, cargo) {
		return AITile.GetCargoProduction (tile, cargo, 1, 1, 3) > 7;
	}

	/**
	 * Creates a list of town that can produce a given cargo.
	 * @param cargo The cargo this town should produce.
	 * @return AITownList that produce a given cargo.
	 */
	function TownList_Producing(cargo) {
		local tl = CLList(AITownList());
		tl.Valuate (AITown.GetLastMonthProduction, cargo);
		tl.RemoveBelowValue (1);
		return tl;
	}

	/**
	 * Creates a list of town that accepts a given cargo.
	 * @param cargo The cargo this town should accept.
	 * @return AITownList that accepts a given cargo.
	 */
	function TownList_Accepting(cargo) {
		local tl = CLList(AITownList());
		tl.Valuate (XTown.CanAccept, cargo);
		tl.RemoveValue (0);
		return tl;
	}
	
	function VehicleCapacity(cargo, vhc) {
		return AIVehicle.GetCapacity (vhc, cargo);
	}
	function OfVehicle(vhc) {
		/*
		if (AIVehicle.GetVehicleType(vhc) == AIVehicle.VT_RAIL) {
			local eng = AIVehicle.GetWagonEngineType(vhc, 0);
			return AIEngine.GetCargoType(eng);
		}
		*/
		local c = AICargoList();
		c.Valuate (XCargo.VehicleCapacity, vhc);
		c.RemoveBelowValue (1);
		if (c.Count()) return c.Begin();
		return -1;
	}
	function MatchSetting(cargo) {
		local is_pax = AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS);
		if (is_pax && Setting.AllowPax) return true;
		if (!is_pax && Setting.AllowFreight) return true;
		return false;
	}
	
	function GetCargoIncome(cargo_type, distance, days_in_transit) {
		local ret = AICargo.GetCargoIncome(cargo_type, distance, days_in_transit);
		if (cargo_type == XCargo.Pax_ID) ret *= 5;
		//if (cargo_type == XCargo.Mail_ID) ret *= 1.2;
		return ret.tointeger();
	}
}
