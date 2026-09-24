#!/usr/bin/env bash
test_int() {
    [[ "${1}" =~ ^[0-9]+$ ]]
}
