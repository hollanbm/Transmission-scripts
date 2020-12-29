#!/bin/bash

# Server string: "host:port --auth username:password"
SERVER="localhost:9091 --auth user:pass"

# Which torrent states should filebot process at 100% progress.
DONE_STATES=("Seeding" "Stopped" "Finished" "Idle")

# Get the final server string to use.
if [[ -n "$TRANSMISSION_SERVER" ]]; then
  echo -n "Using server string from the environment: "
  SERVER="$TRANSMISSION_SERVER"
elif [[ "$#" -gt 0 ]]; then
  echo -n "Using server string passed through parameters: "
  SERVER="$*"
else
  echo -n "Using hardcoded server string: "
fi
echo "${SERVER: : 10}(...)"  # Truncate to not print auth.

#regex path for movies
MOVIE_PATH_REGEX=".*(radarr|movie).*"
TV_PATH_REGEX=".*(sonarr|tv).*"
FILEBOT_ACTION=copy

#any extra arguments you want to run
EXTRA_ARGS="--conflict override --def excludeList=/home/hollanbm/Downloads/.amc_excludes.txt"

# Get the final server string to use.
if [[ -n "$TRANSMISSION_SERVER" ]]; then
  echo -n "Using server string from the environment: "
  SERVER="$TRANSMISSION_SERVER"
elif [[ "$#" -gt 0 ]]; then
  echo -n "Using server string passed through parameters: "
  SERVER="$*"
else
  echo -n "Using hardcoded server string: "
fi
echo "${SERVER: : 10}(...)"  # Truncate to not print auth.

# Use transmission-remote to get the torrent list from transmission-remote.
TORRENT_LIST=$(transmission-remote $SERVER --list | sed -e '1d' -e '$d' | awk '{print $1}' | sed -e 's/[^0-9]*//g')

# Iterate through the torrents.
for TORRENT_ID in $TORRENT_LIST
do
  INFO=$(transmission-remote $SERVER --torrent "$TORRENT_ID" --info)
  #echo -e "Processing #$TORRENT_ID: \"$(echo "$INFO" | sed -n 's/.*Name: \(.*\)/\1/p')\"..."
  # To see the full torrent info, uncomment the following line.
  #echo "$INFO"
  NAME="$(echo "$INFO" | sed -n 's/.*Name:\s\+\(.*\)/\1/p')"
  #echo $NAME
  PROGRESS=$(echo "$INFO" | sed -n 's/.*Percent Done:\s\+\(.*\)%.*/\1/p')
  STATE=$(echo "$INFO" | sed -n 's/.*State:\s\+\(.*\)/\1/p')
  LOCATION=$(echo "$INFO" | sed -n 's/.*Location:\s\+\(.*\)/\1/p')
  LOCATION="${LOCATION/\/downloads/$HOME/Downloads}" #replace container path, with actual path

  
  if [[ $LOCATION =~ $MOVIE_PATH_REGEX ]]; then
    LABEL="--def ut_label=Movies"
  elif [[ $LOCATION =~ $TV_PATH_REGEX ]]; then
    LABEL="--def ut_label=TV"
  fi

  
  #If the torrent is 100% done and the state is one of the done states.
  if [[ "$PROGRESS" == "100" ]] && [[ "${DONE_STATES[@]}" =~ "$STATE" ]]; then
    filebot @/home/hollanbm/.filebot/args.txt --action $FILEBOT_ACTION "$LOCATION/$NAME" $EXTRA_ARGS $LABEL
  fi
done
