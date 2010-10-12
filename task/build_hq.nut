/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * HeadQuarter builder.
 * Build my HQ on random suitable site if I haven't yet or
 * @return tile location
 */
class Task.BuildHQ extends TaskItem
{
	loc = CLList(AITownList());
	skip = CLList();
	constructor() {
		::TaskItem.constructor("HQ Builder", 5);
		loc.Valuate(AITown.GetPopulation);
		loc.SortValueAscending();
	}

	function On_Start() {
		local hq = AICompany.GetCompanyHQ(My.ID);
		if (AIMap.IsValidTile(hq)) {
			Info("I've already");
			SetRemovable(true);
			Money .Pay();
			return hq;
		}
		Money .Get(0);
		SetRemovable(false);
		local counter = 0;
		local mode = AITestMode();
		for (local town = loc.Begin(); loc.HasNext(); town = loc.Next()) {
			Info("finding#", (counter++));
			if (counter % My.ID != 0) continue;
			if (skip.HasItem(town)) continue;
			Info("found a spot at", AITown.GetName(town));
			local tl = AITown.GetLocation(town);
			local tiles = XTile.Radius(tl, 10, 10);
			//Debug.Say(["c=" + tiles.Count());
			local acc = AIAccounting();
			tiles.Valuate(AITile.IsBuildable);
			tiles.KeepValue(1);
			tiles.Valuate(AITile.GetSlope);
			tiles.KeepValue(0);
			tiles.SortValueAscending();
			tiles.DoValuate(function(id) : (acc) {
				acc.ResetCosts();
				if (!AICompany.BuildCompanyHQ(id)) return -1;
				return acc.GetCosts();
			}
						   );
			tiles.RemoveValue(-1);
			if (tiles.IsEmpty())  {
				skip.AddItem(town, 0);
				return;
			}
			tiles.SortValueAscending();
			{
				local mode = AIExecMode();
				return AICompany.BuildCompanyHQ(tiles.Begin());
			}
		}
	}
}
