#!/bin/bash

# Fixes Erlang issue
epmd -daemon 

# Runs from entry point Overseer.main
iex -S mix run -e Overseer.main 