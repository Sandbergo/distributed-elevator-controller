
Elevator project
===
Real Time Programming, NTNU Spring 2019 

Introduction
---

The complete code for the Elevator Project in TTK4145, Real Time Programming, NTNU Spring 2019, as well as solutions to the exercises. 

The elevator project, specified in the [specification](SPECIFICATION.md), is to create a fault-tolerant distributed system of multiple elevators cooperating to provide a seemless user experience, even with packet loss, power outages, crashes and loss of network connectivity.


How to run
---

Relies on Elixir 1.8.1 and Erlang/OTP 20. Clone the repo and run the bash scripts, [for elevator](run_elevator.sh)and [for simulator](sim_run_elevator.sh). Changes in NetworkHandler for IP-adresses etc. may be needed.


Design
---

The code is written in Elixir and uses prominently the Node and GenServer libraries to communicate between the network and modules, respectively. Modules are implemented as GenServers with state info, and uses the GenServer abstraction of server-client interaction. The network is peer-to-peer based, and uses UDP for connecting to nodes and TCP for passing messages. The bash script used for running will restart after a crash after 5 seconds with any exit code except for 0, merging error modes and giving the programmer the opportunity to fix bugs on the go. 


Documentation
---

Documentation is compiled using HexDocs, you can use a browser to read it, starting from the [main page](/doc/index.html)


Contributors:
---
 - Lars Sandberg ([Sandbergo](https://github.com/sandbergo))
 - Sjur Wroldsen ([Sjurinho](https://github.com/sjurinho))