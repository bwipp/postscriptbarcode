#!/bin/bash

START=$1
END=$2
FIELDWIDTH=$3
shift 3

CMD=$@

PROCS=`nproc`

WID=`echo "s=$START; e=$END; n=$PROCS; if ( (e-s+1)%n ) (e-s+1)/n+1 else (e-s+1)/n" | bc`

for i in `seq 1 $PROCS`; do

  S=`echo "($i-1)*$WID" | bc`
  E=`echo "e=($S+$WID-1); if (e>$END) $END else e" | bc`
  R=`echo "$E-$S+1" | bc`

  FILE="test_${CMD}_$i.txt"
  echo Part $i test of $CMD > $FILE
  nohup nice gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=nullpage -dSTART=$S -dROUNDS=$R -dFIELDWIDTH=$FIELDWIDTH $@ >>$FILE 2>&1 &

done

