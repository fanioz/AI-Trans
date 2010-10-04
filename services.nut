/**
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
 * 
 * name: Services
 * @note class for store either town or industry handling in game
 */

class Services
{
  _current = null;					/// current itemID. Set by source + dest + cargo ID's
	_srcID = null;						/// ID of sources
	_dstID = null;						/// ID of destination
	_cargoID = null;					/// ID of cargo
	_srcIsTown = null; 			/// is source town ?
	_dstIsTown = null;			/// is destination town ?
	_srcStation = null;			/// Source station
	_dstStation = null;			/// Destination station
	_srcDepot = null;				/// Source depot
	_dstDepot = null;       /// Destination Depot
	_cargo_str = null;      /// cargo label
	_is_subsidy = null;     /// is Subsidy ?
	_cargo_freight = null;  /// is freight ?
	_src_tile = null;
	_dst_tile = null;
	_source_text = null;    /// source name
	_dest_text = null;      /// destination name
	_src_pos = null;        /// source location
	_dst_pos = null;         /// destination location
	_readable = null;       /// readable - debugable format
	_serviced = null;				/// Indicator if this is serviced
	_path1 = null;             /// the path used by this service
	_path2 = null;
	_path3 = null;
	_vhcType = null;        /// Type of Vehicle for sevice( use AIVehicle::VehicleType )
	_main_Vhc_ID = null;  /// the ID of main vehicle for this service (other is cloned)
	
	Info = null;							/// Use to gather info about service item
	
	constructor(srcid, dstid, cargoid)
	{
		this.Info = this.info(this);
		this._current = LeadZero(srcid) + ":" + LeadZero(dstid) + ":" + LeadZero(cargoid);
		this._srcID = srcid;
		this._dstID = dstid;
		this._cargoID = cargoid;
		this._srcIsTown = false;
		this._dstIsTown = false;
		this._srcStation = PosClass();
		this._dstStation = PosClass();
		this._srcDepot = PosClass();
		this._dstDepot = PosClass();
		this._src_tile = null;
	  this._dst_tile = null;
		this._cargo_str = "";
		this._cargo_freight = false;
		this._source_text = "";
		this._dest_text = "";
		this._src_pos = -1;
	  this._dst_pos = -1;	
	  this._readable = "";
		this._serviced = false;
		this._is_subsidy = false;
		this._path1 = false;
		this._path2 = false;
		this._path3 = false;
		this._vhcType = AIVehicle.VT_INVALID;
		this._main_Vhc_ID = -1;
  }
	/**
 	* 
 	* name: Update
 	* @note Update other value with API framework and
 	* @return  text for debugging
 	*/
  function Update();
  function OnSave();
  function OnLoad(tables);
}

function Services::Update()
{
  this._cargo_str = AICargo.GetCargoLabel(this._cargoID);
	this._cargo_freight = AICargo.IsFreight(this._cargoID);
	this._source_text = this._srcIsTown ? AITown.GetName(this._srcID) : AIIndustry.GetName(this._srcID);
	this._dest_text = this._dstIsTown ? AITown.GetName(this._dstID) : AIIndustry.GetName(this._dstID);
	this._src_pos = this._srcIsTown ? AITown.GetLocation(this._srcID) : AIIndustry.GetLocation(this._srcID);
	this._dst_pos = this._dstIsTown ? AITown.GetLocation(this._dstID) : AIIndustry.GetLocation(this._dstID);
	this._readable = "" + this._cargo_str + " from " + this._source_text + " to " + this._dest_text ;
	return this._readable;
}

function Services::OnSave(table_to_save, tables)
{
  //local serv = ServiceToSave();
  //foreach(val in table_to_save) {
    //serv.CurrentID = val.Info.CurrentID;
    //serv.SourceID = val.Info.SourceID;
    //serv.DestinationID = val.Info.DestinationID;
    //serv.CargoID = val.Info.CargoID;
    //serv.SourceIsTown = val.Info.SourceIsTown;
    //serv.DestinationIsTown = val.Info.DestinationIsTown;
    //tables <- serv;
  //}
  //return tables;
}

function Services::OnLoad(tables)
{
  
}
/**
 * 
 * name: Info
 * @note Sub class for handling info of service
 */
class Services.info {
	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "CurrentID"						    : 		this._main._current = val; break;
			case "SourceID"							  :			this._main._srcID = val; break;
			case "DestinationID"				    :			this._main._dstID = val; break;
			case "CargoID"							    :			this._main._cargoID = val; break;
			case "SourceIsTown"					:			this._main._srcIsTown = val; break;
			case "DestinationIsTown"		:			this._main._dstIsTown = val; break;
			case "SourceStation"			    :			this._main._srcStation = val; break;
			case "DestinationStation"	  :			this._main._dstStation = val; break;
			case "SourceDepot"					  :			this._main._srcDepot = val; break;
			case "DestinationDepot"		  :			this._main._dstDepot = val; break;
			case "Serviced"							  :			this._main._serviced = val; break;
			case "Is_Subsidy"               : this._main._is_subsidy = val; break;
			case "Path1"                      :     this._main._path1 = val; break;
			case "Path2"                      :     this._main._path2 = val; break;
			case "Path3"                      :     this._main._path3 = val; break;
			case "VehicleType"            :     this._main._vhcType = val; break;
			case "MainVhcID"              :     this._main._main_Vhc_ID = val; break;
			default : throw("the index '" + idx + "' does not exist");
		}
		return val;
	}

	function _get(idx)
	{
		local str = null;
		
		switch (idx) {
			case "CurrentID"						    : 		return this._main._current ; 
			case "SourceID"							  :			return this._main._srcID ; 
			case "DestinationID"				    :			return this._main._dstID ; 
			case "CargoID"							    :			return this._main._cargoID ; 
			case "SourceIsTown"					:			return this._main._srcIsTown ; 
			case "DestinationIsTown"		:			return this._main._dstIsTown ; 
			case "SourceStation"			    :			return this._main._srcStation ; 
			case "DestinationStation"	  :			return this._main._dstStation ; 
			case "SourceTile"              :    return this._main._src_tile;
			case "DestinationTile"         :    return this._main._dst_tile;
			case "SourceDepot"					   :		return this._main._srcDepot ; 
			case "DestinationDepot"			 :		return this._main._dstDepot ; 
			case "Serviced"							    :			return this._main._serviced ;
			case "Is_Subsidy"               : return this._main._is_subsidy;
			case "Path1"                      :     return this._main._path1 ;
			case "Path2"                      :     return this._main._path2 ;
			case "Path3"                      :     return this._main._path3 ;
			case "VehicleType"            :     return this._main._vhcType ;
			case "MainVhcID"              :     return this._main._main_Vhc_ID ;
			case "CargoStr"	                :   	return this._main._cargo_str;
			case "CargoIsFreight"         :     return this._main._cargo_freight;
			case "SourceText"	            :			return this._main._source_text;
			case "DestinationText"        :		return this._main._dest_text;
			case "SourcePos"	            : 		return this._main._src_pos;
			case "DestinationPos"         :	  	return this._main._dst_pos;
			case "Readable"                 :     return this._main._readable;
			default : throw("the index '" + idx + "' does not exist");
		}
		return val;	
	}
	
	
	constructor(main)
	{
		this._main = main;
	}
};

class ServiceToSave {
CurrentID = null;
SourceID = null;
DestinationID = null;
CargoID = null;
SourceIsTown = null;
DestinationIsTown = null;
constructor() {
  CurrentID = null;
  SourceID = null;
  DestinationID = null;
  CargoID = null;
  SourceIsTown = null;
  DestinationIsTown = null;
  }
}
