
Elevator project
===
Real Time Programming, NTNU Spring 2019 

Introduction
---

The complete code for the Elevator Project in TTK4145, Real Time Programming, NTNU Spring 2019, as well as solutions to the exercises. 

The elevator project, specified in the [specification](SPECIFICATION.md), is to create a fault-tolerant distributed  system of multiple elevators cooperating to provide a seemless user experience, even with packet loss, power outages, crashes and loss of network connectivity.


How to use
---

Clone the repo and run the bash scripts in /bin, [for elevator](run_elevator.sh) and [for simulator](sim_run_elevator.sh). Changes in NetworkHandler for IP-adresses etc. may be needed.


Design
---

The code is written in Elixir and uses prominently the Node and GenServer libraries to communicate between the network and modules, respectively. The network is peer-to-peer based, and uses UDP for connecting to nodes and TCP for passing messages. 


Documentation
---

Documentation is compiled using HexDocs, you can use a browser to read it, starting from the [main page](/doc/index.html)

Contributors
---
The Simulator and DriverInterface is given as part of the assignment, and some functions are courtesy of student assistant @jostlowe (thank you), this is mentioned in the documentation for the relevant functions. Everything else is written by us.
