
# python fo.py

from threading import Thread
from threading import Lock

# Potentially useful thing:
#   In Python you "import" a global variable, instead of "export"ing it when you declare it
#   (This is probably an effort to make you feel bad about typing the word "global")
i = 0
lock = Lock()

def incrementingFunction():
    global i, lock
    # TODO: increment i 1_000_000 times
    for j in range(1000000):
	lock.acquire()
	i+=1
	lock.release()

    

def decrementingFunction():
    global i, lock
    # TODO: decrement i 1_000_000 times
    for j in range(1000000):
	lock.acquire()
	i-=1
	lock.release()



def main():
    global i

    incrementing = Thread(target = incrementingFunction, args = (),)
    decrementing = Thread(target = decrementingFunction, args = (),)
    
    # TODO: Start both threads
    incrementing.start()
    decrementing.start() 

    incrementing.join()
    decrementing.join()
    
    print("The magic number is %d" % (i))


main()
