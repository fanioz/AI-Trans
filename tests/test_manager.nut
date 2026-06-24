/*
 * TaskManager Test
 */

// Mock necessary classes and globals before including TaskManager
class Base {
    _name = null;
    constructor(name) { _name = name; }
}

class DailyTask extends Base {
    constructor(name) { Base.constructor(name); }
}

// Mock for Task namespace
class Task {}

// Now include the production code
// Note: Relative path assumes execution from the repository root
try {
    dofile("task/manager.nut");
} catch (e) {
    print("Error loading task/manager.nut: " + e + "\n");
}

class OtherTask extends Base {
    constructor(name) { Base.constructor(name); }
}

function test_task_manager_validation() {
    print("Running TaskManager validation tests...\n");

    // Reset queue
    TaskManager.queue = [];

    // 1. Test valid task type
    try {
        local validTask = DailyTask("TestDailyTask");
        TaskManager.New(validTask);
        if (TaskManager.queue.len() == 1 && TaskManager.queue[0] == validTask) {
            print("[PASS] TaskManager.New accepted valid DailyTask instance.\n");
        } else {
            print("[FAIL] TaskManager.New did not add valid DailyTask instance to queue correctly.\n");
        }
    } catch (e) {
        print("[FAIL] TaskManager.New threw exception for valid DailyTask instance: " + e + "\n");
    }

    // 2. Test invalid task type (OtherTask)
    try {
        local invalidTask = OtherTask("TestOtherTask");
        TaskManager.New(invalidTask);
        print("[FAIL] TaskManager.New accepted invalid task type.\n");
    } catch (e) {
        if (e == "need an instance of DailyTask") {
            print("[PASS] TaskManager.New correctly threw exception for invalid task type: " + e + "\n");
        } else {
            print("[FAIL] TaskManager.New threw unexpected exception for invalid task type: " + e + "\n");
        }
    }

    // 3. Test invalid task type (non-object)
    try {
        TaskManager.New("not an object");
        print("[FAIL] TaskManager.New accepted non-object input.\n");
    } catch (e) {
        if (e == "need an instance of DailyTask") {
            print("[PASS] TaskManager.New correctly threw exception for non-object input: " + e + "\n");
        } else {
            print("[FAIL] TaskManager.New threw unexpected exception for non-object input: " + e + "\n");
        }
    }

    print("Finished TaskManager validation tests.\n");
}

test_task_manager_validation();
