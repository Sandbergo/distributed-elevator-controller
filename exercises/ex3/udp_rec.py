import socket
    

UDP_IP = "" 
UDP_PORT = 30000
   
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM,0)
sock.bind((UDP_IP, UDP_PORT))
   
while True:
    data, addr = sock.recvfrom(1024)
    print("received message:", data)