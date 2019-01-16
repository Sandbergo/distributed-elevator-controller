# Reasons for concurrency and parallelism


To complete this exercise you will have to use git. Create one or several commits that adds answers to the following questions and push it to your groups repository to complete the task.

When answering the questions, remember to use all the resources at your disposal. Asking the internet isn't a form of "cheating", it's a way of learning.

 ### What is concurrency? What is parallelism? What's the difference?
 > Concurrency means that processes are executed at the same time, while parallelism means that the processes are run in parallel, 
 e.g. with two seperate CPUs, while for concurrency, it is sufficient for the processes to appear to be executed simultaneously.
 
 ### Why have machines become increasingly multicore in the past decade?
 > Increasing processing speed further after facing pracical restrictions in clock speed, heat generation, transistor size, pipelining etc. It is the new paradigm for following Moore's law. 
 
 ### What kinds of problems motivates the need for concurrent execution?
 (Or phrased differently: What problems do concurrency help in solving?)
 > Seperately executed processes to be executed simultaneously with spereate and/or shared resources.
 
 ### Does creating concurrent programs make the programmer's life easier? Harder? Maybe both?
 (Come back to this after you have worked on part 4 of this exercise)
 > Easier for some classes of problems (e.g. seperately executable processes, real-time processes), however it introduces a new set of possible issues, making the programmers life harder.
 
 ### What are the differences between processes, threads, green threads, and coroutines?
 > Process: OS-managed (scheduler) with own address space
 Threads: Independently executed processes (/part of a process) within the same (virtual) adress space. Multiple threads can be executed in parallel, or the threads can be managed by the scheduler on one CPU concurrently.    
 Green threads: user-managed threads with own (virtual) adress space, not OS-managed.
 Coroutines: "collaborative" thread. Only one coroutine is executed at any one time instance. It is a form of sequential, not concurrent, processing. 
 
 ### Which one of these do `pthread_create()` (C/POSIX), `threading.Thread()` (Python), `go` (Go) create?
 > `pthread_create()` creates a thread, `threading.Thread()` creates a thread,  `go` creates a "goroutine", which is a lightweight thread (small allocated virtual memory, some OS-thread functionality lacking) 
 
 ### How does pythons Global Interpreter Lock (GIL) influence the way a python Thread behaves?
 > The GIL prevents multiple threads from accesing python Bytecode at the same time, because CPython memory management is not thread safe.
 
 ### With this in mind: What is the workaround for the GIL (Hint: it's another module)?
 > The multiprocessing package, it utilizes subprocesses instead of threads. 
 
 ### What does `func GOMAXPROCS(n int) int` change? 
 > It increases the amount of CPUs that can be executing simultaniously in a Go program.
