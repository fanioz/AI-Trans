dofile("tests/mock_ai.nut");
dofile("ext/xvehicle.nut");

function test_xvehicle_start() {
	local vehicle_id = 123;
	local xv = XVehicle();
	
	// Test case 1: Start vehicle success
	AIVehicle.Reset();
	AIVehicle._return_value = true;
	
	xv.Start(vehicle_id);
	
	if (AIVehicle._start_stop_calls.len() != 1) {
		print("FAIL: Expected 1 call to StartStopVehicle, got " + AIVehicle._start_stop_calls.len() + "\n");
		return;
	}
	if (AIVehicle._start_stop_calls[0] != vehicle_id) {
		print("FAIL: Expected StartStopVehicle with id " + vehicle_id + ", got " + AIVehicle._start_stop_calls[0] + "\n");
		return;
	}
	print("PASS: test_xvehicle_start success case\n");

	// Test case 2: Start vehicle failure (API returns false)
	AIVehicle.Reset();
	AIVehicle._return_value = false;
	
	xv.Start(vehicle_id);
	
	if (AIVehicle._start_stop_calls.len() != 1) {
		print("FAIL: Expected 1 call to StartStopVehicle (failure case), got " + AIVehicle._start_stop_calls.len() + "\n");
		return;
	}
	print("PASS: test_xvehicle_start failure case\n");
}

test_xvehicle_start();
