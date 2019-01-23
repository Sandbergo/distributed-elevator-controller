
import socket
import time

UDP_IP = "129.241.187.255"
UDP_PORT = 20001
MESSAGE1= "This is UDP server@IP:"
MESSAGE2=UDP_IP
MESSAGE3="@PORT:"
MESSAGE4=str(UDP_PORT)



print "UDP target IP", UDP_IP
print "UDP target port", UDP_PORT
print "Message: ", MESSAGE1,MESSAGE2,MESSAGE3,MESSAGE4



sock=socket.socket(socket.AF_INET, socket.SOCK_DGRAM) #internet, UDP

while True:
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST,1)

    sock.sendto(MESSAGE1, (UDP_IP,UDP_PORT))
    sock.sendto(MESSAGE2, (UDP_IP,UDP_PORT))
    sock.sendto(MESSAGE3, (UDP_IP,UDP_PORT))
    sock.sendto(MESSAGE4, (UDP_IP,UDP_PORT))
    time.sleep(3)
