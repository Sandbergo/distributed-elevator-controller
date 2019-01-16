package main

import (
    . "fmt"
    "runtime"
)

// Control signals
const (
	GetNumber = iota
	Exit
)

func number_server(add_number <-chan int, control <-chan int, number chan<- int) {
	var i = 0

	// This for-select pattern is one you will become familiar with if you're using go "correctly".
	for {
		select {
			case num:= <-add_number:
				i += num
			case control:= <-control:
			
			case <-number:
				number <- i
			// TODO: receive different messages and handle them correctly
			// You will at least need to update the number and handle control signals.
		}
	}
}

func incrementing(add_number chan<-int, finished chan<- bool) {
	for j := 0; j<1000000; j++ {
		add_number <- 1
	}
	finished <-true
	//TODO: signal that the goroutine is finished
}

func decrementing(add_number chan<- int, finished chan<- bool) {
	for j := 0; j<1000000; j++ {
		add_number <- -1
	}
	//TODO: signal that the goroutine is finished
	finished <- true
}

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())

	// TODO: Construct the required channels
	control := make(chan int)
	finished := make(chan bool)
	add_number := make(chan int)
	number := make(chan int)

	// TODO: Spawn the required goroutines
	go number_server()
	go incrementing()
	go decrementing()

	// TODO: block on finished from both "worker" goroutines

	control<-GetNumber
	Println("The magic number is:", <-number)
	control<-Exit
}

