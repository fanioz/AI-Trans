/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Clearing events routine before save occurs
 * @note is now allowed to use do command
 */
class Task.Events extends DailyTask
{
	constructor() {
		::DailyTask.constructor("Events Check", 1);
	}

	function On_Start() {
		while (AIEventController.IsEventWaiting()) {
			local e = AIEventController.GetNextEvent();
			local si = null;

			switch (e.GetEventType()) {
				case AIEvent.AI_ET_SUBSIDY_OFFER:
					si = AIEventSubsidyOffer.Convert(e);
					Info("New Subsidy offered");
					My._Subsidies.AddItem(si.GetSubsidyID(), 0);
					break;

				case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:
					si = AIEventSubsidyOfferExpired.Convert(e);
					Info("SubsidyID", si.GetSubsidyID(),  "offer expired");
					My._Subsidies.RemoveItem(si.GetSubsidyID());
					break ;

				case AIEvent.AI_ET_SUBSIDY_EXPIRED:
					si = AIEventSubsidyExpired.Convert(e);
					Info("SubsidyID ", si.GetSubsidyID(), " expired");
					My._Subsidies.RemoveItem(si.GetSubsidyID());
					break;

				case AIEvent.AI_ET_SUBSIDY_AWARDED:
					si = AIEventSubsidyAwarded.Convert(e);
					local id = si.GetSubsidyID();
					local comp_id = AISubsidy.GetAwardedTo(id);
					Info("SubsidyID ", id, " awarded to", AICompany.GetName(comp_id));
					if (comp_id != My.ID) My._Subsidies.RemoveItem(si.GetSubsidyID());
					break;

				case AIEvent.AI_ET_TEST:
					Info("Undocumented event!");
					break;

				case AIEvent.AI_ET_ENGINE_PREVIEW:
					local me = AIEventEnginePreview.Convert(e);
					si = "accepted";
					if (!me.AcceptPreview()) si = "not " + si;
					Info("Preview offer for Vehicle ", me.GetName(), si);
					break;


				case AIEvent.AI_ET_COMPANY_ASK_MERGER:
					local me = AIEventCompanyAskMerger.Convert(e);
					si = "realized";
					if (!me.AcceptMerger()) si = "not " + si;
					Info("Merger offer with ", AICompany.GetName(me.GetCompanyID()), "was", si);
					break;

				case AIEvent.AI_ET_COMPANY_NEW:
					local me = AIEventCompanyNew.Convert(e);
					si = me.GetCompanyID();
					Warn("Welcome " + AICompany.GetName(si));
					break;

				case AIEvent.AI_ET_COMPANY_MERGER:
					local me = AIEventCompanyMerger.Convert(e);
					Info("And now come, the merger between ", AICompany.GetName(me.GetOldCompanyID()), "<->", AICompany.GetName(me.GetNewCompanyID()));
					break;

				case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
					local me = AIEventCompanyInTrouble.Convert(e);
					si = me.GetCompanyID();
					if (My.ID == si) Warn("Going to sleep");
					Info(AICompany.GetName(si), " is in trouble. Would you help him?");
					break;

				case AIEvent.AI_ET_COMPANY_BANKRUPT:
					local me = AIEventCompanyBankrupt.Convert(e);
					si = me.GetCompanyID();
					if (My.ID == si) Warn("Going to die") else Info("Good bye ", AICompany.GetName(si));
					break;

				case AIEvent.AI_ET_VEHICLE_CRASHED:
					local me = AIEventVehicleCrashed.Convert(e);
					local vhc = me.GetVehicleID();
					local tile = me.GetCrashSite();
					switch (me.GetCrashReason()) {
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
					Warn(AIVehicle.GetName(vhc), "was crashed due to", si, "at", XTile.ToString(tile), "God Damned :'(");
					break;

				case AIEvent.AI_ET_VEHICLE_LOST:
					local me = AIEventVehicleLost.Convert(e);
					local vhc_ID = me.GetVehicleID();
					Info("Vehicle lost ", AIVehicle.GetName(vhc_ID));
					break;

				case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
					local me = AIEventVehicleWaitingInDepot.Convert(e);
					local vhc_ID = me.GetVehicleID();
					Info(AIVehicle.GetName(vhc_ID), " is waiting");
					break;

				case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
					local me = AIEventVehicleUnprofitable.Convert(e);
					local vhc_ID = me.GetVehicleID();
					Info(AIVehicle.GetName(vhc_ID), " is unprofitable");
					My._No_Profit_Vhc.AddItem(vhc_ID, 0);
					break;

				case AIEvent.AI_ET_INDUSTRY_OPEN:
					local me = AIEventIndustryOpen.Convert(e);
					si = me.GetIndustryID();
					Info("Congratulation on grand opening ", AIIndustry.GetName(si));
					break;

				case AIEvent.AI_ET_INDUSTRY_CLOSE:
					local me = AIEventIndustryClose.Convert(e);
					si = me.GetIndustryID();
					Info("Sadly enough, Good bye ", AIIndustry.GetName(si));
					if (AIIndustry.IsValidIndustry(si)) {
					}
					break;

				case AIEvent.AI_ET_ENGINE_AVAILABLE:
					local me = AIEventEngineAvailable.Convert(e);
					si = me.GetEngineID();
					Info(AIEngine.GetName(si), " Available");
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

				case AIEvent.AI_ET_INVALID:
					Info("Dunno why it is there");
					break;

				default :
					Debug.DontCallMe("Events");
			}
		}
		Info("No more events");
	}
}
