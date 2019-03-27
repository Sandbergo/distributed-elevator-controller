#!/bin/bash

epmd -daemon # fix erlang issue

# start server
pkill SimElevatorServer # kill last instance of server

gnome-terminal -x ./simulator/SimElevatorServer  & disown 


# run boy ruuuuuuun
iex -S mix run -e Overseer.main
