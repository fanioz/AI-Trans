#!/bin/bash
# Find Squirrel interpreter and run tests

for cmd in squirrel squirrel3 sq sq3 nut; do
  if command -v $cmd >/dev/null 2>&1; then
    echo "Using Squirrel interpreter: $cmd"
    $cmd tests/test_xvehicle.nut
    exit $?
  fi
done

echo "Error: No Squirrel interpreter found."
exit 1
