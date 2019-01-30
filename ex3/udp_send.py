
import socket
import time


UDP_IP = "10.100.23.242"
UDP_PORT = 20007
MESSAGE= "Hello! This is UDP server, IP: " + UDP_IP + " on port: " + str(UDP_PORT) + \
"\n\n please approve group 26, Lars Sandberg, Sjur Wroldsen, Magnus Ramsfjell"


print("UDP target IP", UDP_IP)
print("UDP target port", UDP_PORT)
print("Message: ", MESSAGE)



sock=socket.socket(socket.AF_INET, socket.SOCK_DGRAM) #internet, UDP

while True:
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST,1)

    sock.sendto(MESSAGE, (UDP_IP,UDP_PORT))
    time.sleep(3)
