#!/bin/dash
# usage: studiomdl.sh <abs qc path>   (env: WINTF2DIR LOGDIR TAG)
rel=$(realpath --relative-to="$WINTF2DIR" "$1")
if ( cd "$WINTF2DIR" && WINEDEBUG=-all wine ./bin/studiomdl.exe -nop4 -h -game ./tf "$rel" ) >>"$LOGDIR/$TAG.log" 2>&1
then echo "compiled $1"
else echo "$1" >>"$LOGDIR/$TAG.failed"; echo "FAILED $1"; fi
