/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Saving events into queue before save occurs
 * @note is now allowed to use do command
 */
class Task.Events extends DailyTask
{
	_allowed = null;		///< Determine if executing DoCommand is allowed

	constructor() {
		::DailyTask.constructor("Events Check", 1);
		_allowed = false;
	}

	function On_Start() {
		_allowed = true;
		On_Save();
		_allowed = false;

		while (Service.Data.Events.len()) {
			local item = Service.Data.Events.pop();

			switch (item[0]) {
				case AIEvent.AI_ET_SUBSIDY_OFFER:
					Info("New Subsidy offered");
					My._Subsidies.AddItem(item[1], 0);
					break;

				case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:
					Info("SubsidyID", item[1],  "offer expired");
					My._Subsidies.RemoveItem(item[1]);
					break ;

				case AIEvent.AI_ET_SUBSIDY_EXPIRED:
					Info("SubsidyID ", item[1], " expired");
					My._Subsidies.RemoveItem(item[1]);
					break;

				case AIEvent.AI_ET_SUBSIDY_AWARDED:
					local id = item[1];
					local comp_id = AISubsidy.GetAwardedTo(id);
					Info("SubsidyID ", id, " awarded to", AICompany.GetName(comp_id));
					if (comp_id != My.ID) My._Subsidies.RemoveItem(id);
					break;

				case AIEvent.AI_ET_ENGINE_PREVIEW:
					Info("Preview offer for Vehicle ", item[1], "was", item[2]);
					break;

				case AIEvent.AI_ET_COMPANY_ASK_MERGER:
					Info("Merger offer with ", AICompany.GetName(item[1]), "worth", item[2], "was", item[3]);
					break;

				case AIEvent.AI_ET_COMPANY_NEW:
					local name = AICompany.GetName(item[1]);
					Warn("Welcome " + name);
					break;

				case AIEvent.AI_ET_COMPANY_MERGER:
					Info("And now come, the merger between ", AICompany.GetName(item[1]), "<->", AICompany.GetName(item[2]));
					break;

				case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
					if (My.ID == item[1]) {
						Warn("Going to sleep");
						foreach(vhcs, _ in AIVehicleList()) XVehicle.TryToSend(vhcs);
					}
					Warn(AICompany.GetName(item[1]), " is in trouble. Would you help him?");
					break;

				case AIEvent.AI_ET_COMPANY_BANKRUPT:
					if (My.ID == item[1]) Warn("Going to die") else Warn("Good bye ", AICompany.GetName(item[1]));
					break;

				case AIEvent.AI_ET_VEHICLE_CRASHED:
					local vhc = item[1];
					local tile = item[2];
					local si = "";

					switch (item[3]) {
						case AIEventVehicleCrashed.CRASH_TRAIN :
							si = "two trains collided";
							break;
						case AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING :
							si = "road vehicle got under a train";
							break;
						case AIEventVehicleCrashed.CRASH_RV_UFO :
							si = "road vehicle got under a landing ufo";
							break;
						case AIEventVehicleCrashed.CRASH_PLANE_LANDING :
							si = "on landing";
							break;
						case AIEventVehicleCrashed.CRASH_AIRCRAFT_NO_AIRPORT:
							si = "found not a single airport for landing";
							break;
						case AIEventVehicleCrashed.CRASH_FLOODED :
							si = "flooded";
							break;
						default :
							si = "unknown reason";
					}
					Warn(AIVehicle.GetName(vhc), "was crashed due to", si, "at", CLString.Tile(tile), "God Damned :'(");
					break;

				case AIEvent.AI_ET_VEHICLE_LOST:
					Info("Vehicle lost ", AIVehicle.GetName(item[1]));
					break;

				case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
					Info(AIVehicle.GetName(item[1]), " is waiting");
					break;

				case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
					Info(AIVehicle.GetName(item[1]), " is unprofitable");
					My._No_Profit_Vhc.AddItem(item[1], 0);
					break;

				case AIEvent.AI_ET_INDUSTRY_OPEN:
					Info("Congratulation on grand opening ", AIIndustry.GetName(item[1]));
					break;

				case AIEvent.AI_ET_INDUSTRY_CLOSE:
					local name = AIIndustry.GetName(item[1]);
					if (name) {
						Info("Sadly enough, Good bye ", name);
					} else {
						Info("an industry was closed, but we are too late to catch it");
					}
					break;

				case AIEvent.AI_ET_ENGINE_AVAILABLE:
					Info(AIEngine.GetName(item[1]), " Available");
					break;

				case AIEvent.AI_ET_STATION_FIRST_VEHICLE:
					/*
					 * local me = .Convert(e);
					 * Info("");
					 * me.
					 */
					break;

				case AIEvent.AI_ET_DISASTER_ZEPPELINER_CRASHED:
					/*
					 * local me = .Convert(e);
					 * Info("");
					 * me.
					 */
					break;

				case AIEvent.AI_ET_DISASTER_ZEPPELINER_CLEARED:
					/*
					* local me = .Convert(e);
					* Info("");
					* me.
					*/
					break;
			}
		}
		Info("No more event on queue");
	}
	
	/**
	 * Call Automatically on Save occur
	 */
	function On_Save() {
		while (AIEventController.IsEventWaiting()) {
			local e = AIEventController.GetNextEvent();
			local item = [e.GetEventType()];

			switch (item[0]) {
				case AIEvent.AI_ET_COMPANY_ASK_MERGER:
					local me = AIEventCompanyAskMerger.Convert(e);
					item.push(me.GetCompanyID());
					item.push(me.GetValue());
					local si = false;

					if (_allowed) {
						if (Money.Get(item[2])) {
							si = me.AcceptMerger();
						}
					}

					item.push(si ? "accepted" : "rejected");
					break;

				case AIEvent.AI_ET_COMPANY_BANKRUPT:
					item.push(AIEventCompanyBankrupt.Convert(e).GetCompanyID());
					break;

				case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
					item.push(AIEventCompanyInTrouble.Convert(e).GetCompanyID());
					break;

				case AIEvent.AI_ET_COMPANY_MERGER:
					local me = AIEventCompanyMerger.Convert(e);
					item.push(me.GetOldCompanyID());
					item.push(me.GetNewCompanyID());
					break;

				case AIEvent.AI_ET_COMPANY_NEW:
					item.push(AIEventCompanyNew.Convert(e).GetCompanyID());
					break;

				case AIEvent.AI_ET_DISASTER_ZEPPELINER_CLEARED:
					item.push(AIEventDisasterZeppelinerCrashed.Convert(e).GetStationID());
					break;

				case AIEvent.AI_ET_DISASTER_ZEPPELINER_CRASHED:
					item.push(AIEventDisasterZeppelinerCrashed.Convert(e).GetStationID());
					break;

				case AIEvent.AI_ET_ENGINE_AVAILABLE:
					item.push(AIEventEngineAvailable.Convert(e).GetEngineID());
					break

				case AIEvent.AI_ET_ENGINE_PREVIEW:
					local me = AIEventEnginePreview.Convert(e);
					local si = false;
					if (_allowed) si = me.AcceptPreview();
					item.push(me.GetName());
					item.push(si ? "accepted" : "rejected");
					break;

				case AIEvent.AI_ET_SUBSIDY_OFFER:
					item.push(AIEventSubsidyOffer.Convert(e).GetSubsidyID());
					break;

				case AIEvent.AI_ET_INDUSTRY_CLOSE:
					item.push(AIEventIndustryClose.Convert(e).GetIndustryID());
					break;

				case AIEvent.AI_ET_INDUSTRY_OPEN:
					item.push(AIEventIndustryOpen.Convert(e).GetIndustryID());
					break;

				case AIEvent.AI_ET_SUBSIDY_AWARDED:
					item.push(AIEventSubsidyAwarded.Convert(e).GetSubsidyID());
					break;

				case AIEvent.AI_ET_SUBSIDY_EXPIRED:
					item.push(AIEventSubsidyExpired.Convert(e).GetSubsidyID());
					break;

				case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:
					item.push(AIEventSubsidyOfferExpired.Convert(e).GetSubsidyID());
					break ;

				case AIEvent.AI_ET_VEHICLE_CRASHED:
					local me = AIEventVehicleCrashed.Convert(e);
					item.push(me.GetVehicleID());
					item.push(me.GetCrashSite());
					item.push(me.GetCrashReason());
					break;

				case AIEvent.AI_ET_VEHICLE_LOST:
					item.push(AIEventVehicleLost.Convert(e).GetVehicleID());
					break;

				case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
					item.push(AIEventVehicleUnprofitable.Convert(e).GetVehicleID());
					break;

				case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
					item.push(AIEventVehicleWaitingInDepot.Convert(e).GetVehicleID());
					break;
			}

			Service.Data.Events.insert(0, clone item);
		}
		Info("No more event to save");
	}
}
