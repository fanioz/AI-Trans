/*  09.02.06 - builder.nut
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
 * HeadQuarter builder.
 * Build my HQ on random suitable site if I haven't yet or
 * @return tile location
 */
class Task.HeadQuarter extends YieldTask
{
	constructor()
	{
		::YieldTask.constructor("HeadQuarter Builder Task");
		::YieldTask.SetRepeat(false);
		::YieldTask.SetKey(2);
	}

	function _exec()
	{
		::YieldTask._exec();
		local hq = AICompany.GetCompanyHQ(AICompany.COMPANY_SELF);
		if (AIMap.IsValidTile(hq)) {
			AILog.Info("I've already a Headquarter");
			return hq;
		}

		Bank.Get(0);
		local loc = AITownList();
		local tiles = null;
		local counter = 0;
		loc.Valuate(AITown.GetPopulation);
		loc.Sort(AIAbstractList.SORT_BY_VALUE, true);			
		for (local town = loc.Begin(); loc.HasNext(); town = loc.Next()) {
			counter++;
			if (counter % TransAI.Info.ID != 0) continue;
			tiles = Tiles.Flat(Tiles.OfTown(town, Tiles.Radius(AITown.GetLocation(town), 10, 10), 1));
			tiles.Valuate(AITile.IsBuildableRectangle, 2, 2);
			tiles.RemoveValue(0);
			foreach (location, val in tiles) {
				{
					local mode = AITestMode();
					if (AICompany.BuildCompanyHQ (location)) {
						this._execRail(location);
						this._execRoad(location);
						{
							local xmode = AIExecMode();
							AICompany.BuildCompanyHQ (location)
							AILog.Info("I've just build a Headquarter");					
		 					return location;
						}
					}
 				}
 				yield true;
			}
		}
	}

	function _execRail(tile_to_try)
	{
		local acc = AIAccounting();		
		local types = AIRailTypeList();
		/* rail */
		for (local rt = types.Begin(); types.HasNext(); rt = types.Next()) {
			AIRail.SetCurrentRailType(rt);
			if (!TransAI.Cost.Rail.rawin(rt)) {
				acc.ResetCosts();
				if (AIRail.BuildRailTrack(tile_to_try, AIRail.RAILTRACK_NW_SE)) {
					TransAI.Cost.Rail.rawset(rt, acc.GetCosts());
					//AILog.Info("Cost rail track:" + rt + "=" + acc.GetCosts());
				}
			}
		}
	}
				
	function _execRoad(tile_to_try)
	{
		local acc = AIAccounting();		
		local types = AIList();
		types.AddItem(AIRoad.ROADTYPE_ROAD, 0);
		types.AddItem(AIRoad.ROADTYPE_TRAM, 0);
		/* road */
		for (local rt = types.Begin(); types.HasNext(); rt = types.Next()) {
			AIRoad.SetCurrentRoadType(rt);
			foreach (head , val in Tiles.Adjacent(tile_to_try)) {
				if (!TransAI.Cost.Road.rawin(rt)) {
					acc.ResetCosts();
					if (AIRoad.BuildRoad(tile_to_try, head)) {
						TransAI.Cost.Road.rawset(rt, acc.GetCosts());
						//AILog.Info("Cost road track:" + rt + "=" + acc.GetCosts());
					}
				}				
			}
		}
	}
}
