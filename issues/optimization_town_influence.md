# Town Influence Area Optimization Opportunity

## The Problem
In `manager/townmanager.nut`, the `ValidateArea` function calculates the town's area of influence by starting at a radius of 20 and iteratively expanding it by 1:

```squirrel
local rad = 20;
local num = -1;
while (num < _Area[0].Count()) {
	AIController.Sleep(1);
	num = _Area[0].Count();
	_Area[0].Clear();
	rad++;
	_Area[0].AddList(XTile.Radius(tile_s, rad, rad));
	_Area[0].Valuate(AITile.IsWithinTownInfluence, GetID());
	_Area[0].RemoveValue(0);
}
```

This brute-force approach recalculates the entire area `(2*rad + 1)^2` times for each iteration. For a town extending to radius 50, it performs 30 iterations, doing massive redundant work on the same inner tiles.

## The Proposed Solution
Increase the radius increment from `1` to a larger value, such as `5`, or use a binary search-like approach along the axes to find the bounding box of influence before querying all tiles.

By checking every 5th radius, the number of expensive list creations and valuations (`IsWithinTownInfluence`) is reduced by 80%. Town influence is contiguous, so skipping intermediate radii is safe for determining the maximum extent.

## Expected Impact
- Reduces the loop iterations from O(N) to O(N/k) where N is the distance to the edge of influence and k is the step size.
- Significantly lowers CPU time spent in `ValidateArea` during the AI's area recalculation phase (every 360 days).
- Makes the AI play much smoother on large maps with sprawling cities.