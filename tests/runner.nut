/*
 * Simple test runner for Squirrel tests
 */

// Load mocks
dofile("tests/openttd_mocks.nut");

// Load source code
dofile("utilities/debugger.nut");

// Load tests
dofile("tests/test_debugger.nut");

// Run tests
try {
	test_clear_err();
	::print("\nALL TESTS PASSED\n");
} catch (e) {
	::print("\nTEST FAILED: " + e + "\n");
	// Use throw to signal failure in a way that most Squirrel interpreters will catch
	throw e;
}
