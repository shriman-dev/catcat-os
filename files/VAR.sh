#!/bin/bash
MAJOR_VERSION=42
DEFAULT_TAG="latest"
DATESTAMP="$(TZ="Asia/Kolkata" date "+%Y%m%d")"
TIMESTAMP="$(TZ="Asia/Kolkata" date "+%H%M%S")"
AH_DATE=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)
