#! /bin/bash
cd /exchange

if ! test -d ".corona-settings"; then
    mkdir .corona-settings
    echo -1 > .corona-settings/lastcolumn
fi

if pgrep -f "carbon-feeder.py" &>/dev/null; then
  echo "carbon-feeder it is already running" > test
else
  #bash -c "./carbon-feeder.py > /exchange/carbon-feeder.output"
  #nohup bash -c "./carbon-feeder.py > /exchange/carbon-feeder.output" &>/dev/null &
  ./carbon-feeder.py > carbon-feeder.output &
fi
