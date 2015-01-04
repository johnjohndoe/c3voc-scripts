#!/bin/bash
BASEDIR=$(dirname $0)
INTERVAL=180

file="$1"
outdir="$2"


LENGTH=$(ffprobe -loglevel quiet -print_format default -show_format "$file" | grep duration= | sed -e 's/duration=\([[:digit:]]*\).*/\1/g')

TMPDIR=$(mktemp -d /tmp/thumb.XXXXXX)

if [ -z "$outdir" ]; then
  outgif=${file%.*}.gif
  outjpg=${file%.*}.jpg
  outjpg_preview=${file%.*}_preview.jpg
else
  outgif=${outdir}/$(basename ${file%.*}.gif)
  outjpg=${outdir}/$(basename ${file%.*}.jpg)
  outjpg_preview=${outdir}/$(basename ${file%.*}_preview.jpg)
fi


# now extract candidates and convert to non-anamorphic images
#
# we use equidistant sampling, but skip parts of the file that might contain pre-/postroles
# also, use higher resolution sampling at the beginning, as there's usually some interesting stuff there


for POS in 20 30 40 $(seq 15 $INTERVAL $[ $LENGTH - 60 ])
do
	ffmpeg -loglevel error -ss $POS -i "$file"  -an -r 1 -filter:v 'scale=sar*iw:ih' -vframes 1 -f image2 -vcodec mjpeg -q:v 0 -y "$TMPDIR/$POS.jpg"
done

WINNER=$(python2 $BASEDIR/select.py $TMPDIR/*.jpg)
ffmpeg -loglevel error -i $WINNER -filter:v 'crop=ih*4/3:ih' -filter:v 'scale=192:-1' $outjpg
ffmpeg -loglevel error -i $WINNER -filter:v 'crop=ih*4/3:ih' -filter:v 'scale=640:-1' $outjpg_preview
