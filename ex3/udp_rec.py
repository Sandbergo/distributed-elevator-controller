import socket
    
UDP_IP = "10.100.23.185"
UDP_PORT = 20010
   
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM,0)
sock.bind((UDP_IP, UDP_PORT))
   
while True:
    print("sjur")
    data, addr = sock.recvfrom(1024)
    print("received message:", data)