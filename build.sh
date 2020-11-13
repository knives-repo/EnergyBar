#!/bin/bash
cd build/Xcode
xcodebuild -workspace EnergyBar.xcworkspace -scheme EnergyBar -configuration Release
app=$(find $HOME/Library/Developer/Xcode/DerivedData/EnergyBar*//Build/Products/Release -name EnergyBar.app)
killall EnergyBar
rm -rf /Applications/EnergyBar.app
cp -r $app /Applications/
sleep 1
open /Applications/EnergyBar.app
