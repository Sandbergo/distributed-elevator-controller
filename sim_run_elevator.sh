#!/bin/bash

epmd -daemon # fix erlang issue

# start server
pkill SimElevatorServer # kill last instance of server
gnome-terminal -x ./simulator/SimElevatorServer  & disown 

# compile
mix compile

# run 
iex -S mix run -e Overseer.start_link
