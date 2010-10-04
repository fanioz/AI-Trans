/*  09.04.03 - dependencies.nut
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

/*
 * Define all required files here.
 * 1 : use 'import' for files that available on Bananas
 * 2 : use 'required' for own files or modified version of NoAI library.
 * In fact, the only required from Bananas right now is Aystar.6, and since AyStar.6 depend
 * on Binary Heap, that would be enough (auto-resolved dependencies)
 */

import("queue.fibonacci_heap", "FibonacciHeap", 2);
import("graph.aystar", "AyStar_6", 6);

require("pathfinder/aystar.nut");
require("pathfinder/rail.nut");
require("pathfinder/road.nut");
require("pathfinder/water.nut");
require("pathfinder/air.nut");

/* ---------------- Own --------------- */
require("base/storage.nut");
require("base/task.nut");
require("base/services.nut");
require("base/keylist.nut");

require("utilities/const.nut");
require("utilities/cargo.nut");
require("utilities/money.nut");
require("utilities/sandbox.nut");
require("utilities/generator.nut");

require("infrastructure/tile.nut");

require("manager/managers.nut");
require("manager/task.nut");
require("manager/company.nut");
require("manager/servable.nut");
require("manager/builder.nut");

require("build/building.nut");
require("build/road.nut");
require("build/rail.nut");
require("build/stations.nut");
require("build/vehicles.nut");
