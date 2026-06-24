/* Mock OpenTTD AI API */

class AIVehicle {
	static _start_stop_calls = [];
	static _return_value = true;

	static function StartStopVehicle(v) {
		AIVehicle._start_stop_calls.push(v);
		return AIVehicle._return_value;
	}

	static function Reset() {
		AIVehicle._start_stop_calls = [];
		AIVehicle._return_value = true;
	}
}

function Info(msg, ...) {}
function Warn(msg, ...) {}
function Error(msg, ...) {}

class Debug {
	static function ResultOf(val, msg) {
		return val;
	}
	static function Echo(val, msg) {
		return val;
	}
}

// Global table for My and Service if needed
My <- {
	_Vehicles = {}
};

Service <- {
	Data = {
		Routes = {}
	}
};

Assist <- {
	function HasBit(v, b) { return (v & b) != 0; }
};
