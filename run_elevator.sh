#!/bin/bash

epmd -daemon # fix erlang issue. Import pack of inet_tcp

# run
iex -S mix run -e Overseer.main