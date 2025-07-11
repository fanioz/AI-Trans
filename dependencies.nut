/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2025 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/*
 * Define all required files here.
 * 1 : use 'import' for files that is not included in distribution
 */

try
{
	import("AILib.Common", "CLCommon", 2);
	import("AILib.List", "CLList", 3);
	import("AILib.String", "CLString", 2);
} catch (idx)
{
	AILog.Warning("you would need to download the libraries which is needed to run this AI.");
	AILog.Warning("Please goto http://www.tt-forums.net/viewtopic.php?p=771764#p771764");
	AILog.Warning("and check the libraries required to run");
	throw "failed to import libraries";
}

/* ---------------- Own --------------- */
require("utilities/enum.nut");
/* base */
require("base/base.nut");
require("base/memory.nut");
require("base/location_id.nut");
require("base/servable.nut");
require("base/infrastructure.nut");
require("base/daily.nut");
require("base/connector.nut");

/* --linked library --*/
require("pathfinder/aystar.nut");
require("pathfinder/aypath.nut");
require("pathfinder/road_pt.nut");
require("pathfinder/road_pf.nut");
require("pathfinder/water_pt.nut");
require("pathfinder/rail_pf.nut");
require("pathfinder/rail_pt.nut");

/* builder */
require("builder/vehicle.nut");
require("builder/station.nut");

/* task */
require("task/manager.nut");
require("task/build_hq.nut");
require("task/cv.nut");
require("task/events.nut");
require("task/route_man.nut");
require("task/trackdoubler.nut");
require("task/cleanup.nut");

/* managers */
require("manager/stationmanager.nut");
require("manager/townmanager.nut");
require("manager/industrymanager.nut");
require("manager/airconnector.nut");
require("manager/roadconnector.nut");
require("manager/waterconnector.nut");
require("manager/railfirstconnector.nut");

/* extension */
require("ext/xairport.nut");
require("ext/xcargo.nut");
require("ext/xengine.nut");
require("ext/xindustry.nut");
require("ext/xmap.nut");
require("ext/xmarine.nut");
require("ext/xroad.nut");
require("ext/xrail.nut")
require("ext/xstation.nut");
require("ext/xtile.nut");
require("ext/xtown.nut");
require("ext/xvehicle.nut");

/* utilities */
require("utilities/debugger.nut");
require("utilities/const.nut");
require("utilities/money.nut");
require("utilities/sandbox.nut");
require("utilities/settings.nut");
require("utilities/service.nut");
//require("utilities/ticker.nut");
