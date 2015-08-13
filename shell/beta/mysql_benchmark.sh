#!/bin/bash

INTERVAL=5
PREFIX="$INTERVAL"-sec-status
RUNFILE=~/benchmarks-running
mysql -e 'SHOW GLOBAL VARIABLES' >> mysql-variables