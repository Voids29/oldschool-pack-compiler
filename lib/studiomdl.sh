#!/bin/dash
# usage: studiomdl.sh <abs qc path>   (env: STUDIOMDL GAMEDIR LOGDIR TAG)
if "$STUDIOMDL" -nop4 -h -game "$GAMEDIR" "$1" >>"$LOGDIR/$TAG.log" 2>&1
then echo "compiled $1"
else echo "$1" >>"$LOGDIR/$TAG.failed"; echo "FAILED $1"; fi
