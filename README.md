
Elevator project
===
Real Time Programming, NTNU Spring 2019 

Introduction
---

The complete code for the Elevator Project in TTK4145, Real Time Programming, NTNU Spring 2019.

The elevator project, specified in the [specification](SPECIFICATION.md), is to create a fault-tolerant distributed  system of multiple elevators cooperating to provide a seemless user experience, even with packet loss, power outages, crashes and loss of network connectivity.


How to run
---

Relies on Elixir 1.8.1 and Erlang/OTP 20. Clone the repo and run the bash scripts [./run_elevator.sh](run_elevator.sh) and [./sim_run_elevator](sim_run_elevator.sh). Changes in NetworkHandler for IP-adresses etc. may be needed. can also be run directly with

`iex -S mix run -e Overseer.main`


Design
---

The code is written in Elixir and uses prominently the Node and GenServer libraries to communicate between the network and modules, respectively. The network is peer-to-peer based, and uses UDP for connecting to nodes and TCP for passing messages. The system consists of the modules DriverInterface, Poller, StateMachine, OrderHandler, WatchDog, Overseer and NetworkHandler. All communication between nodes is executed in the NetworkHandler.


Documentation
---

Documentation is compiled using HexDocs, you can use a browser to read it, starting from the [main page](/doc/index.html)

Contributors
---
The Simulator and DriverInterface is given as part of the assignment, and some functions are courtesy of student assistant @jostlowe (thank you), this is mentioned in the documentation for the relevant functions. Everything else is written by us.
