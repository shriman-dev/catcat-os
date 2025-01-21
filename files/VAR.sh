#!/bin/bash
DATESTAMP="$(date "+%Y%m%d")"
TIMESTAMP="$(TZ="Asia/Kolkata" date "+%H%M%S")"
AH_DATE=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)
MAJOR_VERSION=41
DEFAULT_TAG="latest"
