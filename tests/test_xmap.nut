dofile("tests/mock_ai.nut");
dofile("ext/xmap.nut");

function assert_equal(expected, actual, message) {
    if (expected != actual) {
        ::print("FAIL: " + message + " (Expected: " + expected + ", Actual: " + actual + ")");
        throw "Assertion failed: " + message;
    } else {
        ::print("PASS: " + message);
    }
}

function test_length() {
    local xmap = XMap();
    local start = AIMap.GetTileIndex(10, 10);
    local finish = AIMap.GetTileIndex(15, 20);
    assert_equal(15, xmap.Length(start, finish), "Length between (10,10) and (15,20)");
    
    assert_equal(0, xmap.Length(start, start), "Length between same tile");
}

function test_tile_is_point() {
    local xmap = XMap();
    assert_equal(true, xmap.TileIsPoint(AIMap.GetTileIndex(1, 1)), "Tile (1,1) is point");
    assert_equal(true, xmap.TileIsPoint(AIMap.GetTileIndex(21, 1)), "Tile (21,1) is point");
    assert_equal(true, xmap.TileIsPoint(AIMap.GetTileIndex(1, 21)), "Tile (1,21) is point");
    assert_equal(false, xmap.TileIsPoint(AIMap.GetTileIndex(2, 2)), "Tile (2,2) is not point");
}

function test_get_point_index() {
    local xmap = XMap();
    assert_equal(AIMap.GetTileIndex(1, 1), xmap.GetPointIndex(AIMap.GetTileIndex(5, 5)), "Point index for (5,5)");
    assert_equal(AIMap.GetTileIndex(21, 21), xmap.GetPointIndex(AIMap.GetTileIndex(25, 25)), "Point index for (25,25)");
}

function test_get_boundaries() {
    local xmap = XMap();
    local tile = AIMap.GetTileIndex(5, 5);
    local boundaries = xmap.GetBoundaries(tile);
    assert_equal(4, boundaries.Count(), "GetBoundaries count");
    
    local point = xmap.GetPointIndex(tile);
    local expected = [
        point,
        XTile.SW_Of(point, XMap.sizeX),
        XTile.S_Of(point, XMap.sizeY),
        XTile.SE_Of(point, XMap.sizeY)
    ];
    
    local idx = 0;
    foreach (val in boundaries) {
        assert_equal(expected[idx], val, "Boundary tile " + idx);
        idx++;
    }
}

function test_get_neighbours() {
    local xmap = XMap();
    local point = AIMap.GetTileIndex(1, 1);
    local neighbours = xmap.GetNeighbours(point);
    assert_equal(4, neighbours.Count(), "GetNeighbours count");
    
    local expected = [
        XTile.NE_Of(point, XMap.sizeX),
        XTile.SW_Of(point, XMap.sizeX),
        XTile.NW_Of(point, XMap.sizeY),
        XTile.SE_Of(point, XMap.sizeY)
    ];
    
    local idx = 0;
    foreach (val in neighbours) {
        assert_equal(expected[idx], val, "Neighbour tile " + idx);
        idx++;
    }
}

try {
    test_length();
    test_tile_is_point();
    test_get_point_index();
    test_get_boundaries();
    test_get_neighbours();
    ::print("ALL TESTS PASSED");
} catch (e) {
    ::print("TEST RUN FAILED: " + e);
    // In a real environment we might use exit(1) but here we just print
}
