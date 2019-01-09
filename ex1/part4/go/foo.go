// Use `go run foo.go` to run your program

package main

import (
    . "fmt"
    "runtime"
    "time"
)

var i = 0

func incrementing() {
    for j := 0; j < 100000; j++ {
		    i++
	  } 
}

func decrementing() {
    for j := 0; j < 100000; j++ {
		    i++
    } 
}

func main() {
    runtime.GOMAXPROCS(runtime.NumCPU() - 1)    // I guess this is a hint to what GOMAXPROCS does...
	                                    // Try doing the exercise both with and without it!
    go incrementing()
    go decrementing()
	
    // We have no way to wait for the completion of a goroutine (without additional syncronization of some sort)
    // We'll come back to using channels in Exercise 2. For now: Sleep.
    time.Sleep(100*time.Millisecond)
    Println("The magic number is:", i)
}
