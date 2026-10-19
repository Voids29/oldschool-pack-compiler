#!/bin/dash
# usage: studiomdl.sh <abs qc path>   (env: WINTF2DIR STUDIOMDL LOGDIR TAG)
qc=$1
rel=$(realpath --relative-to="$WINTF2DIR" "$qc")
case $STUDIOMDL in *.exe) set -- wine "$STUDIOMDL";; *) set -- "$STUDIOMDL";; esac
if ( cd "$WINTF2DIR" && WINEDEBUG=-all "$@" -nop4 -h -game ./tf "$rel" ) >>"$LOGDIR/$TAG.log" 2>&1
then echo "compiled $qc"
else echo "$qc" >>"$LOGDIR/$TAG.failed"; echo "FAILED $qc"; fi
