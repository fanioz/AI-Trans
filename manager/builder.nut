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
		::YieldTask.constructor("Build HeadQuarter Task");
		::YieldTask.SetRepeat(false);
		::YieldTask.SetKey(10);
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
			tiles = Tiles.Flat(Tiles.OfTown(town, Tiles.Radius(AITown.GetLocation(town), 10)));
			tiles.Valuate(AITile.IsBuildableRectangle, 2, 2);
			tiles.RemoveValue(0);
			foreach (location, val in tiles) {
				if (AICompany.BuildCompanyHQ (location)) {
					AILog.Info("I've just build a Headquarter");					
					return location;
				}
				AISign.RemoveSign(AISign.BuildSign(location,"here"));
				AILog.Info("I've not found a spot yet for Headquarter");
				yield location;
			}
		}
	}
}
