class Route
{
	railfinder = null;
	roadfinder = null;
	waterfinder = null;
	serv = null;

	constructor(ser)
	{
		assert(serv instanceof Services);
		railfinder = null;
		roadfinder = null;
		waterfinder = null;
	}

	function CheckRoad(from, to, track)
	{
	}

	function FindRoad(from, to, track)
	{
	}

	function CheckRail(from, to, track)
	{
	}

	function FindRail(from, to, track)
	{
	}

	function CheckWater(from, to)
	{
	}

	function FindWater(from, to)
	{
	}
}
