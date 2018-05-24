/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Track doubler.
 * Build the second track for a specific route 
 */
class Task.TrackDoubler extends DailyTask
{
	dispObj = {};// key { PF, StepLeft, Line, BackPoint }
	constructor() {
		::DailyTask.constructor("Track Doubler", 15);
	}

	function On_Start() {
		if (!Service.Data.Projects.rawin("RouteBack")) return;
		local keep = [];
		while (Debug.Echo(Service.Data.Projects["RouteBack"].len(), "RouteBack count")) {
			local key = Service.Data.Projects["RouteBack"].pop();
			if (!Service.Data.Routes.rawin(key)) continue;
			Info("Processing", key);
			local t = Service.Data.Routes[key];
			if (t.RouteBackIsBuilt) continue; //no need to go further
			if (this.dispObj.rawin(key)) {
				local obj = this.dispObj[key];
				if (obj.Line) {
					Info("Line", key, obj.Line ? "Found" : "Not found");
					{
						local mode = AITestMode();
						local cost = AIAccounting();
						if (XRail.BuildRail(obj.Line)) {
							if (Money.Maximum() < cost.GetCosts()) {
								if (AICompany.GetQuarterlyIncome(My.ID, AICompany.CURRENT_QUARTER ) > 0) keep.push(key);
								continue;
							};
						} else {
							Info("Path building failed. Re-find");
							this.dispObj[key].PF.InitializePath([obj.Points[0]], [obj.Points[1]], []);
							this.dispObj[key].StepLeft = 10000;
							this.dispObj[key].Line = false;
							keep.push(key);
							continue;
						}
					}
					Money.Get(0);
					t.RouteBackIsBuilt = XRail.BuildRail(obj.Line);
					XRail.BuildSignal([obj.Points[1]], [obj.Points[0]], 10);
					Info("Done building", key); 
				} else {
					if (obj.StepLeft < 1) {
						Info("pathfinding time out");
						continue;
					}
					
					if (obj.Line == null) {
						Info("pathfinding failed");
						continue;
					}
					this.dispObj[key].Line = obj.PF.FindPath(1000);
					this.dispObj[key].StepLeft -= 1000;
					keep.push(key);
				}
			} else {
				Info("Initializing", key);
				local startEndBack = [];
				foreach (aPoints in [t.StartPoint, t.EndPoint]) 
					foreach (points in aPoints)
						if (AITile.IsBuildable(points[0])) startEndBack.push(points);
				
				if (startEndBack.len() < 2) {
					Info("Tile is not double track buildable");
					continue;
				}
				local pf = Rail_PF();
				pf.InitializePath([startEndBack[0]], [startEndBack[1]], []);
				this.dispObj.rawset(key, {PF = pf, StepLeft = 10000, Line = false, Points = startEndBack});
				keep.push(key);
			}			
		}
		Service.Data.Projects["RouteBack"].extend(keep)
	}
}
