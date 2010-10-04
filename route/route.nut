/*  09.04.03 - route.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * RouteSaver is still experimental.
 * It would try to recover information
 * from a vehicle, instead of saved game
 * thus, Trans doesn't to save anything.
 */
class RouteSaver extends Infrastructure
{
	_sst = null;
	_dst = null;
	_sstid = null;
	_dstid = null;
	_sdp = null;
	_ddp = null;
	_stype = null;
	_last_build = null;
	_track = null;
	_capacity = null;
	_max_speed = null;
	_validated = null;
	_src_id = null;
	_dst_id = null;
	_grp_id = null;
	_src_is_town = null;
	_dst_is_town = null;
	_engine = null;
	_key = null;
	constructor() {
		::Infrastructure.constructor (-1, -1);
		_sst = -1;
		_dst = -1;
		_sstid = -1;
		_dstid = -1;
		_grp_id = -1;
		_sdp = -1;
		_ddp = -1;
		_stype = -1;
		_last_build = 0;
		_track = -1;
		_capacity = 0;
		_max_speed = 0;
		_validated = false;
		_src_id = -1;
		_dst_id = -1;
		_src_is_town = false;
		_dst_is_town = false;
		_engine = -1;
		_key = "";
	}
	function GetSStation() { return _sst; }
	function GetDStation() { return _dst; }
	function GetSStationID() { return _sstid; }
	function GetDStationID() { return _dstid; }
	function GetSDepot() { return _sdp; }
	function GetDDepot() { return _ddp; }
	function GetSourceID() { return _src_id; }
	function GetDestinationID() { return _dst_id; }
	function SourceIsTown() { return _src_is_town; }
	function DestinationIsTown() { return _dst_is_town; }
	function SetLastBuild (dat) { _last_build = dat + 10; }
	function GetLastBuild() { return _last_build; }
	function GetTrack() { return _track; }
	function IsValidRoute() { return _validated; }
	function GetMaxSpeed() { return _max_speed; }
	function GetMinSpeed() { return (_max_speed / 2).tointeger(); }
	function GetEngine() { return _engine; }
	function GetCapacity() { return _capacity; }
	function GetGroupID() { return _grp_id; }
	function GetFriends() { return CLList(AIVehicleList_Group(_grp_id)); }
	function GetKey() { return _key;}
	function GetSType() { return _stype; }
	function Waiting() {
		return AIStation.GetCargoWaiting (GetSStationID(), GetCargo());
	}
	function GetProduction() {
		return (SourceIsTown() ? XTown : XIndustry).ProdValue (GetSourceID(), GetCargo());
	}
	function SourceIsProducing() {
		return GetProduction() > GetCapacity();
	}
	function Validate (idx) {
		_validated = false;
		if (!AIVehicle.IsValidVehicle (idx)) return;
		AIController.Sleep (1);
		SetID (idx);
		SetCargo (XCargo.OfVehicle (idx));
		SetVType (AIVehicle.GetVehicleType (idx));
		_sst = AIOrder.GetOrderDestination (idx, 0);
		_dst = AIOrder.GetOrderDestination (idx, 1);
		_ddp = AIOrder.GetOrderDestination (idx, 2);
		_sdp = AIOrder.GetOrderDestination (idx, 3);
		_sstid = AIStation.GetStationID (_sst);
		if (!AIStation.IsValidStation (_sstid)) return;
		_dstid = AIStation.GetStationID (_dst);
		if (!AIStation.IsValidStation (_dstid)) return;
		if (!AIOrder.IsGotoDepotOrder(idx, 2)) return;
		if (!AIOrder.IsGotoDepotOrder(idx, 3)) return;
		_key = Service.CreateKey (_sstid, _dstid, GetCargo(), GetVType());
		SetName (_key);
		_capacity = AIVehicle.GetCapacity (idx, GetCargo());
		if (XCargo.TownStd.HasItem (GetCargo())) {
			_src_id = XTown.GetID (_sst);
			_src_is_town = true;
		} else {
			_src_is_town = false;
			_src_id = XIndustry.GetID (_sst, true, GetCargo());
		}
		if (XCargo.HasTownEffect (GetCargo())) {
			_dst_id = XTown.GetID (_dst);
			_dst_is_town = true;
		} else {
			_dst_is_town = false;
			_dst_id = XIndustry.GetID (_dst, false, GetCargo());
		}
		_engine = AIVehicle.GetEngineType (idx);
		_max_speed = AIEngine.GetMaxSpeed (_engine);
		_stype = XStation.GetTipe (GetVType(), GetCargo());
		_track = XVehicle.GetTrack(idx);
		SetLastBuild (AIDate.GetCurrentDate());
		_validated = true;
		My._Vehicles[idx] <- this;
	}
	function AllowAdd() {
		Info ("Last build", Assist.DateStr (GetLastBuild()));
		Info ("Time to make clone");
		local label = XCargo.Label[GetCargo() ];
		local sname = AIStation.GetName (GetSStationID());
		if (_capacity > Debug.ResultOf (Waiting(), "at", sname, label, "waiting:")) return false;
		if (Debug.Echo (AIStation.GetCargoRating (GetSStationID(), GetCargo()), "at", sname, label, "rating:") > 60) return false;
		local friends = GetFriends ();
		friends.Valuate (AIVehicle.GetState);
		if (friends.CountIfKeepValue (AIVehicle.VS_AT_STATION)) {
			Info ("has vehicles in un/loading state");
			return false;
		}
		friends.KeepValue (AIVehicle.VS_RUNNING);
		friends.Valuate (XVehicle.IsLowSpeed);
		friends.KeepValue (1);
		if (friends.Count()) {
			Info (sname, "has vehicles in slow motion :D");
			return false;
		}
		local dstation = XStation.GetManager (GetDStationID(), _stype);
		if (!dstation.CanAddNow(GetCargo())) {
			Info ("is busy");
			return false;
		}
		if (dstation.GetOccupancy() > 99) {
			Info ("is out of space");
			return false;
		}
		return true;
	}
	/*
	 * Compare
	*/
	function IsEqual (other) {
		assert (other instanceof RouteSaver);
		if (GetSStationID() != other.GetSStationID()) return false;
		if (GetDStationID() != other.GetDStationID()) return false;
		if (_sdp != other._sdp) return false;
		if (GetCargo() != other.GetCargo()) return false;
		if (GetVType() != other.GetVType()) return false;
		return true;
	}
	
	function Merge(other) {
		assert (other instanceof RouteSaver);
		if (!other.IsValidRoute()) return;
		if (!IsEqual(other)) return;
		if (!AIVehicle.IsValidVehicle (GetID())) {
			Validate(other.GetID());
			return IsValidRoute();
		}
		_capacity = max(_capacity, other._capacity);
		if (AIEngine.GetDesignDate(_engine) < AIEngine.GetDesignDate(other._engine)) {
			AIGroup.SetAutoReplace(_grp_id, _engine, other._engine);
			_engine = other._engine;
		}
	}
	
	function CheckRoute() {
	}
	function CheckRoadRoute() {
		local route = Road_PT();
		local from = AIRoad.GetRoadStationFrontTile(GetSStation());
		local to = AIRoad.GetRoadStationFrontTile(GetDStation());
		route.InitializePath (from, to, []);
		local path = route.FindPath(-1);
		return path;
	}
	function CheckRailRoute() {
	}
	function CheckAirRoute() {
	}
	function CheckWaterRoute() {
	}
}
