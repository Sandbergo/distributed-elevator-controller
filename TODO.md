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

### Short term checkpoints network
* [x] Minimum working Network Module
* [x] Network module broadcast self
* [x] Network module sets up cluster
* [ ] Network module sync orders


### Long term checkpoints
* [x] One elevator can perform one order correctly
* [x] One elevator can perform multiple orders correctly
* [x] StateMachine module finished v1.0
* [x] Network setup nodes
* [ ] communication of data between nodes
* [ ] handle packet loss
* [ ] handle restart
* [ ] handle motor stop
* [ ] :heart: FAT :heart: 


### Remember to check out 
* better order priority in StateMachine?