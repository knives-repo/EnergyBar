#!/bin/bash
cd build/Xcode
xcodebuild -workspace EnergyBar.xcworkspace -scheme EnergyBar -configuration Release
app=$(find /Users/nbonamy/Library/Developer/Xcode/DerivedData/EnergyBar*//Build/Products/Release -name EnergyBar.app)
killall EnergyBar
rm -rf /Applications/EnergyBar.app
cp -r $app /Applications/
open /Applications/EnergyBar.app
