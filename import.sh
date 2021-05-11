#!/bin/bash

echo "Downloading content ..."
./download-content.py https://dash.akamaized.net/WAVE/vectors/database.json content

echo ""
echo "Importing DPCTF tests ..."
git clone https://github.com/cta-wave/dpctf-tests dpctf
mv dpctf/generated/* tests
mv dpctf/test-config.json .
rm -rf dpctf
