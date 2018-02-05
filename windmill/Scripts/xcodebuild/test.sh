#!/bin/bash

# Requires the following variables to be set
# SCHEME_NAME

TEST_METADATA_FOR_PROJECT=$1
SCHEME_NAME=$2

PARSE="import sys, json; print json.load(open(\"${TEST_METADATA_FOR_PROJECT}\"))[\"destination\"][\"udid\"]"

DESTINATION_ID=$(python -c "$PARSE")
xcodebuild test-without-building -scheme "${SCHEME_NAME}" -destination "platform=iOS Simulator,id=${DESTINATION_ID}"

exit_code=$?
if [ $exit_code -eq 66 ]; then
exit 0
fi
exit $exit_code

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