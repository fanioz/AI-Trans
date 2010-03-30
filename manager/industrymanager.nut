/*  10.02.27 - industrymanager.nut.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Class that handles industries.
 */
class IndustryManager extends Servable
{
	/**
	 * Constructor
	 */
	constructor (id) {
		assert (AIIndustry.IsValidIndustry (id));
		Servable.constructor (id, AIIndustry.GetLocation (id), AIIndustry.GetName (id));
		_Area[0].AddList(AITileList_IndustryAccepting(id, 5));
		_Area[0].AddList(AITileList_IndustryProducing(id, 5));
	}
	function GetRoadPoint() { 
		local list = GetArea();
		list.Valuate(XTile.IsRoadBuildable);
		list.KeepValue(1);
		list.Valuate(AIMap.DistanceMax, GetLocation());
		list.KeepBelowValue(AIStation.GetCoverageRadius (AIStation.STATION_TRUCK_STOP));
		list.SortValueAscending();
		return list; 
	}

	function ImproveRating () {
		// try to improve current rating until it is enough
		if (XTile.HasEnoughRating (GetLocation())) return true;
		local mgr = XTown.GetManager(AITile.GetClosestTown (tile));
		return mgr.ImproveRating ();
	}

	function HasCoast () {
		if (AIIndustry.IsBuiltOnWater(GetID())) return true;
		Servable.ValidateCoast();
		_Has_Coast[0].KeepBelowValue(AIStation.GetCoverageRadius (AIStation.STATION_DOCK));
		return Servable.HasCoast();
	}
		
	function GetExistingWaterStop (cargo, is_source) {
		if (AIIndustry.HasDock(GetID())) return AIIndustry.GetDockLocation(GetID());
		return Servable.GetExistingWaterStop(cargo, is_source);
	}
	
	function GetExistingAirport (plane_type, cargo) {
		if (AIIndustry.HasHeliport(GetID())) {
			if (plane_type != AIAirport.PT_HELICOPTER) return -1;
			return  AIIndustry.GetHeliportLocation(GetID());
		}
		return Servable.GetExistingAirport(plane_type, cargo);
	}
	
	function AllowTryAirport (type) {
		return false;
	}
	
	function TryBuildAirport (type, cargo, eng_cost) {
		Info ("can't build an airport");
		return -1;
	}
	
	function GetAreaForRoadStation(cargo, is_source) {
		local rad = AIStation.GetCoverageRadius (AIStation.STATION_TRUCK_STOP); 
		local list = CLList((is_source ? AITileList_IndustryProducing : AITileList_IndustryAccepting)(GetID(), rad));
		local fn = AITile[is_source ? "GetCargoProduction" : "GetCargoAcceptance"]; 
		list.Valuate (AITile.GetMinHeight);
		list.KeepAboveValue (0);
		list.Valuate (XTile.IsRoadBuildable);
		list.KeepValue (1);
		list.Valuate(AIRoad.IsDriveThroughRoadStationTile);
		list.KeepValue (0);
		list.Valuate (fn, cargo, 1, 1, rad);
		return list;
	}
	
	function GetAreaForRoadDepot() {
		local list = GetArea();
		list.Valuate (AITile.GetMinHeight);
		list.KeepAboveValue (0);
		assert(list.Count());
		list.Valuate (AITile.IsBuildable);
		list.KeepValue (1);
		assert(list.Count());
		list.Valuate(AIMap.DistanceManhattan, GetLocation ());
		return list;
	}
}
