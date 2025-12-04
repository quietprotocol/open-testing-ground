#!/bin/bash
echo "WARNING: UNAUTHENTICATED USERS CAN NOW FETCH *CERTIFICATES*. THIS IS RISKY"
mkdir -p share
cp tak/certs/files/*.zip share
cp tak/certs/files/*.p12 share
cd share
python3 -m http.server 12345

