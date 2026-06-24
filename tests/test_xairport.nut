// Mock AI environment
dofile("tests/mock_ai.nut");

// Include the file to test
dofile("ext/xairport.nut");

function test_max_plane() {
    print("Testing XAirport.MaxPlane...\n");

    // Expected values based on cascading switch:
    // AT_INTERCON: 7
    // AT_INTERNATIONAL: 6
    // AT_METROPOLITAN: 5
    // AT_CITY: 5
    // AT_LARGE: 4
    // AT_COMMUTER: 3
    // AT_HELISTATION: 3
    // AT_SMALL: 2
    // AT_HELIDEPOT: 2
    // AT_HELIPORT: 1

    assert(XAirport.MaxPlane(AIAirport.AT_INTERCON) == 7, "AT_INTERCON should be 7");
    assert(XAirport.MaxPlane(AIAirport.AT_INTERNATIONAL) == 6, "AT_INTERNATIONAL should be 6");
    assert(XAirport.MaxPlane(AIAirport.AT_METROPOLITAN) == 5, "AT_METROPOLITAN should be 5");
    assert(XAirport.MaxPlane(AIAirport.AT_CITY) == 5, "AT_CITY should be 5");
    assert(XAirport.MaxPlane(AIAirport.AT_LARGE) == 4, "AT_LARGE should be 4");
    assert(XAirport.MaxPlane(AIAirport.AT_COMMUTER) == 3, "AT_COMMUTER should be 3");
    assert(XAirport.MaxPlane(AIAirport.AT_HELISTATION) == 3, "AT_HELISTATION should be 3");
    assert(XAirport.MaxPlane(AIAirport.AT_SMALL) == 2, "AT_SMALL should be 2");
    assert(XAirport.MaxPlane(AIAirport.AT_HELIDEPOT) == 2, "AT_HELIDEPOT should be 2");
    assert(XAirport.MaxPlane(AIAirport.AT_HELIPORT) == 1, "AT_HELIPORT should be 1");
    assert(XAirport.MaxPlane(AIAirport.AT_INVALID) == 0, "AT_INVALID should be 0");

    print("XAirport.MaxPlane tests passed!\n");
}

try {
    test_max_plane();
} catch (e) {
    print("TEST FAILED: " + e + "\n");
    exit(1);
}
