class AIAirport {
    static AT_INTERCON = 0;
    static AT_INTERNATIONAL = 1;
    static AT_METROPOLITAN = 2;
    static AT_CITY = 3;
    static AT_LARGE = 4;
    static AT_COMMUTER = 5;
    static AT_SMALL = 6;
    static AT_HELISTATION = 7;
    static AT_HELIDEPOT = 8;
    static AT_HELIPORT = 9;
    static AT_INVALID = 255;

    static PT_BIG_PLANE = 0;
    static PT_SMALL_PLANE = 1;
    static PT_HELICOPTER = 2;
}

class AIStation {
    static STATION_TRAIN = 0;
    static STATION_TRUCK_STOP = 1;
    static STATION_BUS_STOP = 2;
    static STATION_AIRPORT = 3;
    static STATION_DOCK = 4;
}

class AILog {
    static function Info(msg) { print("INFO: " + msg + "\n"); }
    static function Warning(msg) { print("WARNING: " + msg + "\n"); }
    static function Error(msg) { print("ERROR: " + msg + "\n"); }
}

function assert(condition, message = "Assertion failed") {
    if (!condition) {
        throw message;
    }
}
