#!/bin/bash

epmd -daemon # fix erlang issue

# start server
pkill ElevatorServer # kill last instance of server
cd ~/Documents/gr25/TTK4145  # change to TTK4145 directory
gnome-terminal -x ~/.cargo/bin/ElevatorServer & disown 

# compile
mix compile

# run
iex -S mix run -e Overseer.test