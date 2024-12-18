#!/bin/bash
curl -Lo /tmp/MControlCenter.tar.gz https://github.com/dmitry-s93/MControlCenter/releases/latest/download/MControlCenter-0.4.1-bin.tar.gz

mkdir -p /tmp/MControlCenter
tar -xf /tmp/MControlCenter.tar.gz -C /tmp/MControlCenter --strip-components=1

cd /tmp/MControlCenter
./install
cd -

