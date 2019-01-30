import socket
import time


TCP_self_IP = "10.100.23.134"
TCP_server_IP = "10.100.23.242"
TCP_server_PORT = 33546


self_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
self_sock.connect((TCP_server_IP, TCP_server_PORT))

print("entering loop")

data, addr = self_sock.recvfrom(1024)
print("connection established with", addr, "data:", data)

while True:
    self_sock.send("Hello! This is UDP server, IP: " + TCP_self_IP  + " on port: " + str(TCP_server_PORT ) + \
    "\n\n please approve group 26, Lars Sandberg, Sjur Wroldsen, Magnus Ramsfjell\0")
    time.sleep(3)
