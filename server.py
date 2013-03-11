import socket
import select
import sys
import threading

class Client(threading.Thread):
    def __init__(self, conn, addr):
        self.conn = conn
        self.addr = addr
        self.size = 1024

    def run(self):
        running = 1
        while running:
            data = self.conn.recv(self.size)
            if data:
                print(addr[0]+ ": " + data.decode('UTF-8'))
            else:
                self.conn.close()
                runnging = 0




host = ''
port = 10627

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
s.listen(1)
while True:
    conn, addr = s.accept()
    Client(conn, addr).run()
    #data = conn.recv(1024)
    #if not data: break
    #conn.sendall(data)
    #print(addr[0] + ": " + data.decode('UTF-8'))
conn.close()

"""
try:
    s.connect((host, port))
    s.shutdown(2)
    print("Success connecting to ")
    print(host, " on port: ", str(port))
except socket.error as e:
    print("Cannot connect to ")
    print(host, " on port: ", str(port))
    print(e)
"""

