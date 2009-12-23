#!/bin/sh

NAME=GlovePod

rm -rf release
cp -a package release
cp ${NAME}.dylib release/Library/MobileSubstrate/DynamicLibraries/
find release -iname .svn -exec rm -rf {} \;
find release -iname .gitignore -exec rm -rf {} \;
sudo chgrp -R wheel release
sudo chown -R root release
sudo dpkg-deb -b release
sudo rm -rf release
