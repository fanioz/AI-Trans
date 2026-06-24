/*
 * Test for XMarine.GetWaterSide
 */

// Mock dependencies
dofile("tests/mock_ai.nut");
dofile("ext/xmarine.nut");

function test_GetWaterSide() {
	local xm = XMarine();
	local tile = 100;
	
	// Test Case 1: First adjacent is water
	XTile._adjacents[tile] <- [101, 102, 103, 104];
	AITile._water_tiles = { [101] = true };
	local result = xm.GetWaterSide(tile);
	assert(result == 101);
	::print("Test Case 1 Passed\n");

	// Test Case 2: Third adjacent is water
	AITile._water_tiles = { [103] = true };
	result = xm.GetWaterSide(tile);
	assert(result == 103);
	::print("Test Case 2 Passed\n");

	// Test Case 3: No adjacent is water
	AITile._water_tiles = { [105] = true };
	result = xm.GetWaterSide(tile);
	assert(result == -1);
	::print("Test Case 3 Passed\n");

	// Test Case 4: Multiple water tiles, should return first
	AITile._water_tiles = { [102] = true, [103] = true };
	result = xm.GetWaterSide(tile);
	assert(result == 102);
	::print("Test Case 4 Passed\n");
}

try {
	test_GetWaterSide();
	::print("All tests for XMarine.GetWaterSide passed!\n");
} catch (e) {
	::print("Test failed: " + e + "\n");
}
