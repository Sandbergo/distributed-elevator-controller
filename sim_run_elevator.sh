#!/bin/bash

epmd -daemon # fix erlang issue

# start server
pkill SimElevatorServer # kill last instance of server
cd simulator
gnome-terminal -x ./SimElevatorServer  & disown 
cd ..

# compile
mix compile

# run 
iex -S mix run -e Overseer.test
