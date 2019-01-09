# Reasons for concurrency and parallelism


To complete this exercise you will have to use git. Create one or several commits that adds answers to the following questions and push it to your groups repository to complete the task.

When answering the questions, remember to use all the resources at your disposal. Asking the internet isn't a form of "cheating", it's a way of learning.

 ### What is concurrency? What is parallelism? What's the difference?
 > Concurrency means that processes are executed at the same time, while parallelism means that the processes are run in parallel, 
 e.g. with two seperate CPUs, while for concurrency, it is sufficient for the processes to appear to be executed simultaneously.
 
 ### Why have machines become increasingly multicore in the past decade?
 > Increasing processing speed further after facing pracical restrictions in clock speed, heat generation, transistor size, pipelining etc.
 
 ### What kinds of problems motivates the need for concurrent execution?
 (Or phrased differently: What problems do concurrency help in solving?)
 > Seperate and independent processes to be executed simultaneously
 
 ### Does creating concurrent programs make the programmer's life easier? Harder? Maybe both?
 (Come back to this after you have worked on part 4 of this exercise)
 > Easier for some classes of problems, however it introduces a new set of possible issues.
 
 ### What are the differences between processes, threads, green threads, and coroutines?
 > Process: OS-managed with own address space, threads are within the same adress space. Green threads are user-managed, not OS-managed.
 Coroutines are done sequentially (not parallel)
 
 ### Which one of these do `pthread_create()` (C/POSIX), `threading.Thread()` (Python), `go` (Go) create?
 > `pthread_create()` creates a thread, `threading.Thread()` creates a thread,  `go` creates a coroutine 
 
 ### How does pythons Global Interpreter Lock (GIL) influence the way a python Thread behaves?
 > The GIL prevents multiple threads from accesing python Bytecode at the same time, because CPython memory management is not thread safe.
 
 ### With this in mind: What is the workaround for the GIL (Hint: it's another module)?
 > The multiprocessing package, it utilizes subprecesses instead of threads. 
 
 ### What does `func GOMAXPROCS(n int) int` change? 
 > It increases the amount of allocated operating system threads in a Go program.
