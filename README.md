Elevator project
===
Real Time Programming, NTNU Spring 2019 

Introduction
---

The complete code for the Elevator Project in TTK4145, Real Time Programming, NTNU Spring 2019.

The elevator project, specified in the [specification](SPECIFICATION.md), is to create a fault-tolerant distributed  system of multiple elevators cooperating to provide a seemless user experience, even with packet loss, power outages, crashes and loss of network connectivity.


How to run
---

Relies on Elixir 1.8.1 and Erlang/OTP 20. Clone the repository and run the bash scripts [./run_elevator.sh](run_elevator.sh) and [./sim_run_elevator](sim_run_elevator.sh). Changes in NetworkHandler for IP-adresses etc. may be needed for your system. The code can also be run directly with the command

`iex -S mix run -e Overseer.main`


Design
---

The code is written in Elixir and uses prominently the Node and GenServer libraries to communicate between the network and modules, respectively, as well as a Supervisor. The supervisor utilizes the :one_for_all strategy, restarting every module upon crash. The network is peer-to-peer based, and uses UDP for connecting to nodes and TCP for passing messages. The system consists of the modules DriverInterface, Poller, StateMachine, OrderHandler, WatchDog, Overseer and NetworkHandler. All communication between nodes is executed between their respective NetworkHandler modules.


Documentation
---

Documentation is compiled using HexDocs, and can be read on the following webpage:

`https://sandbergo.github.io/elevator-docs` 


Contributors
---
The Simulator and DriverInterface is given as part of the assignment, and some functions are courtesy of student assistant @jostlowe (thank you), this is mentioned in the documentation for the relevant functions. Everything else is written by us.
