# TODO

### Short term checkpoints elevator
* [x] Implement Poller.button_polling and receive in OrderHandler
* [x] OrderHandler sends order to elevator
* [x] implement states in StateMachine
* [x] Stop on ordered floor
* [x] Implement order list 
* [x] StateMachine tells OrderHandler to delete order
* [x] Open/Close Doors on reached floor
* [x] Order lights
* [x] Fix OrderList in OrderHandler
* [x] One elevator has (close to) optimal performance
* [x] Bug in OrderHandler: resets every time? 
* [x] Fix elevator priority of order pressed 

### Short term checkpoints network
* [x] Minimum working Network Module
* [x] Network module broadcast self
* [x] Network module sets up cluster
* [x] Network module sync orders
* [ ] set up testing network from own PCs
* [x] Only non-cab orders shared
* [ ] Information about elevator states are considered
* [ ] Order is handled by best elevator
* [ ] Orders are deleted form active orders when executed by other elevator 


### Long term checkpoints
* [x] One elevator can perform one order correctly
* [x] One elevator can perform multiple orders correctly
* [x] StateMachine module finished v1.0
* [x] Network setup nodes
* [x] communication of data between nodes
* [x] single elevator optimal performance
* [x] elevator network reasonable performance
* [ ] elevator network spec performance
* [ ] implement watchdog v1.0
* [ ] handle packet loss (script)
* [ ] handle restart
* [ ] handle motor stop
* [ ] cleanup of all code 
* [ ] :heart: FAT :heart: 


### Remember to check out 
* Supervising