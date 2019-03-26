#!/bin/bash

epmd -daemon # fix erlang issue

# run
iex -S mix run -e Overseer.test