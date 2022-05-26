#! /bin/bash
cd /exchange

if pgrep -f "carbon-feeder.py" &>/dev/null; then
  echo "carbon-feeder it is already running" > test
else
<<<<<<< HEAD
  #bash -c "./carbon-feeder.py > /exchange/carbon-feeder.output"
  #nohup bash -c "./carbon-feeder.py > /exchange/carbon-feeder.output" &>/dev/null &
  ./carbon-feeder.py > carbon-feeder.output &
fi
=======
  ./carbon-feeder.py > logs/carbon-feeder.output &
fi
>>>>>>> b441a4ac003d94da50f748c288c1eb98b250e1a1
