# Mutex and Channel basics

### What is an atomic operation?
> An completely independent operation, completed in a single step relative to other threads and, consequently, independent of the other threads. This can mean that it is a single CPU-operation, or that it is made atomic through synchronization methods. 

### What is a semaphore?
> A variable used to control access to a common resource between threads, used to avoid race conditions. 

### What is a mutex?
> MUTualEXclusion is a part of concurrency control which prevents race conditions, 
meaning no two threads accesses a critical section at the same time.

### What is the difference between a mutex and a binary semaphore?
> A mutex can only be released from the thread that aquired it, while a binary semaphore can be signaled from any other thread.
Binary semaphore are useful for synchronization problems. 

### What is a critical section?
> A part of a program where a thread accesseses shared resources, meaning a synchronization method must be implemented to avoid a race condition.

### What is the difference between race conditions and data races?
 > A data race is two different threads writing to the same data location at (almost) the same time, a race condition is a fault in timing that lead to erronous program behavior.

### List some advantages of using message passing over lock-based synchronization primitives.
> * it is easier to do right, less room for programmer error
> * complexity does not increase exponentially with more threads

### List some advantages of using lock-based synchronization primitives over message passing.
> * better performance
> * does not need to allocate message objects
