#!/bin/bash
epmd -daemon # fix erlang issue


iex -S mix run -e Overseer.main