#!/usr/bin/env bash

# Fail on any errors
set -e

# Delete build directory
if [ -d "./build" ]; then
  rm -rf ./build
fi

# Delete dist directory
if [ -d "./dist" ]; then
  rm -rf ./dist
fi

# Make build dir
mkdir ./build

# Make install curator
echo ""
echo "****************************** "
echo "Installing elasticsearch-curator"
echo ""
pip3 install elasticsearch-curator -t ./build

# Make install aws auth to authenticate requests to elastic search
echo ""
echo "****************************** "
echo "Installing requests-aws4auth"
echo ""
pip3 install requests-aws4auth -t ./build

# Copy over script and config
echo ""
echo "****************************** "
echo "Copying script and config"
echo ""
cp serverlesscurator.py serverless-curator.yaml ./build/

# Package into zip file in dist
echo ""
echo "****************************** "
echo "Building distribution"
echo ""
pushd build
zip -r elasticsearch-curator.zip *
mkdir ../dist
mv elasticsearch-curator.zip ../dist

echo ""
echo "****************************** "
echo "Build successful"
echo "Distribution created in dist/elasticsearch-curator.zip"
echo "Done "

popd
