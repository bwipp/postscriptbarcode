#!/bin/bash

# Copyright (c) 2008, Michael Landers
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice, 
#     this list of conditions and the following disclaimer in the documentation 
#     and/or other materials provided with the distribution.
#   * The names of its contributors may not be used to endorse or promote 
#     products derived from this software without specific prior written 
#     permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

FILE=barcode.ps
OUTFILE=-
LIST=0
ES=""
BE="% --BEGIN ENCODER"
EE="% --END ENCODER"
BR="% --BEGIN RENDERER"
ER="% --END RENDERER"
ES=""
RS=""

elementInList() {
       e="$1"
       shift

       for i in $*
       do
               [ "$e" = "$i" ] && return 0
       done

       return 1
}

while getopts "f:o:le:" flag
do
       case ${flag} in
       f) FILE="${OPTARG}" ;;
       l) LIST=1 ;;
       o) OUTFILE="${OPTARG}" ;;
       e) ! elementInList "${OPTARG}" "${ES}" && ES="${ES} ${OPTARG}" ;;
       *) exit;
       esac
done

ELIST=$(sed -n "s/^${BE} \(.*\)--/\1/p" ${FILE} | sort)

[ "$LIST" -eq 1 ] && echo "Available Encoders: ${ELIST}" && exit
[ "$ES" = "" ] && echo "No encoders specified.  Nothing to do" && exit

for encoder in ${ES}
do
       ! elementInList $encoder ${ELIST} && echo "${encoder}: Invalid encoder" && exit
       renderer=$(sed -n "/^${BE} ${encoder}--/,/^${EE} ${encoder}/s/^% --RNDR: \(.*\)/\1/p" ${FILE}) 
       ! elementInList $renderer $RS && RS="$RS $renderer"
done

[ "x$OUTFILE" != "x-" ] && exec > $OUTFILE

sed -n '1,/^% --BEGIN TEMPLATE--/p' ${FILE}
for e in ${ES}
do
       echo
       sed -n "/^${BE} ${e}--/,/${EE} ${e}--/p" ${FILE}
done
for r in ${RS}
do
       echo
       sed -n "/^${BR} ${r}--/,/${ER} ${r}--/p" ${FILE}
done
echo
sed -n '/^% --BEGIN DISPATCHER--/,$p' ${FILE}

