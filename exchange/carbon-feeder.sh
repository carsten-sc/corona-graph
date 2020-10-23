#! /bin/bash

if ! test -d ".corona-settings"; then
    mkdir .corona-settings
    echo -1 > .corona-settings/lastcolumn
fi

if pgrep -f "carbon-feeder.py" &>/dev/null; then
  echo "carbon-feeder it is already running"
else
  python3 ./carbon-feeder.py
fi