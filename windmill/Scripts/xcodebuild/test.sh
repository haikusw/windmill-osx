#!/bin/bash

# Requires the following variables to be set
# SCHEME_NAME

TEST_DEVICES_FOR_PROJECT=$1
SCHEME_NAME=$2
DERIVED_DATA_PATH_FOR_PROJECT=$3

PARSE="import sys, json; print json.load(open(\"${TEST_DEVICES_FOR_PROJECT}\"))[\"destination\"][\"udid\"]"

DESTINATION_ID=$(python -c "$PARSE")
xcodebuild test-without-building -scheme "${SCHEME_NAME}" -destination "platform=iOS Simulator,id=${DESTINATION_ID}" -derivedDataPath "${DERIVED_DATA_PATH_FOR_PROJECT}"

exit_code=$?
if [ $exit_code -eq 70 ] || [ $exit_code -eq 66 ]; then
xcodebuild test -scheme "${SCHEME_NAME}" -destination "platform=iOS Simulator,id=${DESTINATION_ID}" -derivedDataPath "${DERIVED_DATA_PATH_FOR_PROJECT}"

    exit_code=$?

    if [ $exit_code -eq 66 ]; then
    mv "${TEST_DEVICES_FOR_PROJECT}" "${TEST_DEVICES_FOR_PROJECT}.66"
    exit 0
    else
    exit $exit_code
    fi

else
exit $exit_code
fi

## Test
#
#    /**
#     Causes
#     
#     * "Test Suite \'(Selected|All) tests\' (failed)"
#     * xcodebuild: error: The project named "soldo" does not contain a scheme named "com.soldo.soldo". The "-list" option can be used to find the names of the schemes in the project.
#     
#     */
#one = 1
#failed = 65
#seventy = 70
#    
#    /**
#     
#     2017-06-30 21:39:20.591698+0100 xcodebuild[50470:15852836] [MT] DVTAssertions: ASSERTION FAILURE in /Library/Caches/com.apple.xbs/Sources/IDEFrameworks/IDEFrameworks-13158.29/IDEFoundation/Testing/IDETestRunSession.m:333
#     Details:  (testableSummaryFilePath) should not be nil.
#     
#     */
#assertionFailure = 134
