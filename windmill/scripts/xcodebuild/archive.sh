#!/bin/bash
set -e

PROJECT_NAME=$1
RESOURCES_ROOT=$2


xcodebuild -scheme $PROJECT_NAME -configuration Release clean build archive -derivedDataPath build -archivePath build/$PROJECT_NAME.xcarchive
xcodebuild -exportArchive -archivePath build/$PROJECT_NAME.xcarchive -exportOptionsPlist $RESOURCES_ROOT/exportOptions.plist -exportPath build