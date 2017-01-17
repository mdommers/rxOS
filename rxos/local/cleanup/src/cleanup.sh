#!/bin/sh

KiB=1  # Base unit is KiB
MiB=$(( 1024 * KiB ))
GiB=$(( 1024 * MiB ))

DLDIR=/mnt/internal
AVAIL="$(df -P "$DLDIR" | tail -n1 | awk '{print $4}')"  # KiB
MINFREE=$(( 400 * MiB ))  # 2x OTA update 200 MiB
NEEDS="$(( MINFREE - AVAIL ))"  # KiB
CALLBACK="/usr/bin/oncontentchange"
LOG="logger -t cleanup"


# first clean up the regularly updated dirs

# Weather jsons

# jsons older than 7 days
[ -d "/mnt/downloads/Weather/data/weather" ] && find /mnt/downloads/Weather/data/weather/*/*/* -type d -mtime +7 | xargs -r -I {} rm -rf "{}"

#  gribs older than 7 days
[ -d "/mnt/downloads/Weather/grib2/" ] && find "/mnt/downloads/Weather/grib2/" -type d -mtime +7 | xargs -r -I {} rm -rf "{}"

#  oscar older than latest
[ -d "/mnt/downloads/Weather/data/oscar" ] && find "/mnt/downloads/Weather/data/oscar" -type f |\
     grep "surface-currents-oscar-0.33.json" | sort | head -n -1 | xargs -r -I {} rm -f "{}"

# APRS files older than 3 days
[ -d "/mnt/downloads/Amateur Radio/APRS/APRSAT/" ] && find "/mnt/downloads/Amateur Radio/APRS/APRSAT/" -type f -mtime +5 | xargs -r -I {} rm -f "{}"

# News older than 7 days
[ -d "/mnt/downloads/News" ] && find "/mnt/downloads/News" -type f -mtime +7 | xargs -r -I {} rm -f "{}"

# Wikipedia files older than 60 days
[ -d "/mnt/downloads/Wikipedia" ] && find "/mnt/downloads/Wikipedia" -type f -mtime +60 | xargs -r -I {} rm -f "{}"

# Cache files not changed in 3 days
[ -d "/mnt/downloads/.cache" ] && find "/mnt/downloads/.cache" -type f -mtime +7 | grep -v index | xargs -r -I {} rm -f "{}"


if [ "$NEEDS" -le 0 ]; then
  $LOG "Needs $MINFREE KiB, but there is already $AVAIL KiB, nothing to do"
  exit 0
fi

$LOG "Cleanup needs to free $NEEDS KiB"

filestats() {
  find "$DLDIR" -type f -exec stat -c '%Y|%s|%n' "{}" +
}

sort_by_ts() {
  sort -n -t\| -k1
}

size_freed=0
count=0

filestats | sort_by_ts | while read file; do
  if [ "$size_freed" -ge "$NEEDS" ]; then
    sync
    $LOG "Removed $count files and freed $size_freed KiB"
    break
  fi

  size="$(echo "$file" | cut -d\| -f2)"
  size="$(( size / 1024 ))"
  path="$(echo "$file" | cut -d\| -f3)"

  rm -f "$path"
  $LOG "Removed '$path' to free $size KiB"
  size_freed="$(( size_freed + size ))"
  count="$(( count + 1 ))"
done

[ -x "$CALLBACK" ] && "$CALLBACK"
