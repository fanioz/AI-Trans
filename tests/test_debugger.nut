/*
 * Unit test for ClearErr
 */

function test_clear_err() {
	::print("Running test_clear_err...\n");
	
	// Set an error state
	AIError.SetLastError(AIError.ERR_UNKNOWN);
	if (AIError._last_error != AIError.ERR_UNKNOWN) {
		throw "Failed to set mock error state";
	}
	
	// Call ClearErr
	local debug = Debug();
	debug.ClearErr();
	
	// Verify error state is cleared
	// Note: Our mock GetLastError() returns the error AND clears it.
	// But ClearErr() already called it, so it should be ERR_NONE now.
	local current_err = AIError.GetLastError();
	if (current_err != AIError.ERR_NONE) {
		throw "ClearErr did not clear the error state. Expected ERR_NONE, got " + current_err;
	}
	
	::print("test_clear_err passed!\n");
}
