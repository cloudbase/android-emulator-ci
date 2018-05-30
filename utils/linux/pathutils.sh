#!/bin/bash

function ensure_dir_empty () {
    rm -rf $1
    mkdir -p $1
}
