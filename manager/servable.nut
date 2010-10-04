/*  09.05.27 - servable.nut
 *
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
 * Manager of servable object
 */
class ServableManager extends Manager
{
	constructor()
	{
		::Manager.constructor("Servable");
	}
	
	 /**
	 * Find an class ID using real ID
	 * @param id Real ID
	 * @return a valid class ID or null if not found
	 */
	function FindKey(id)
	{
		local key = this.FindID(id, true);
		if (key) return key;
		key = this.FindID(id, false);
		if (key) return key;
	}
	
	/**
	 * Find an ID using IsTown flag 
	 * @param id Real Town/Industry index
	 * @param istown Is this an ID of Town
	 * @return a valid ID or null if not found
	 */
	function FindID(id, istown)
	{
		local func = istown ? AITown : AIIndustry;
		local key = func.GetLocation(id);
		if (!AIMap.IsValidTile(key)) return;
		if (this.list.HasItem(key)) {
			foreach (idx, val in this.list)	if (key == idx) return idx;
		}
	}
	
	/**
	 * Scan map for servable object
	 */
	function ScanMap()
	{
		AILog.Info("Scanning Map:");
		AILog.Info("-> check validity of current list");
		foreach (idx, val in this.list) if (!this.Item(idx).IsValid()) this.RemoveItem(idx);
		
		AILog.Info("-> Update Town list");
		local temp = null;
		local lst = AITownList();
		lst.Valuate(AITown.GetLocation);
		foreach (idx, loc in lst) {
			if (this.list.HasItem(loc)) continue;
			temp = Servable.NewTown(idx);
			this.Insert(loc, idx, temp);
		}
		//AILog.Info(Assist.AIListToString(lst));
		
		AILog.Info("-> Update Industry list");
		lst = AIIndustryList();
		lst.Valuate(AIIndustry.GetLocation);
		foreach (idx, loc in lst) {
			if (this.list.HasItem(loc)) continue;
			temp = Servable.NewIndustry(idx);
			this.Insert(loc, idx, temp);
		}
		//AILog.Info(Assist.AIListToString(lst));
	}
}
