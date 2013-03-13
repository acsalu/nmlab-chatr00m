#!/usr/bin/python3

import socket
import select
import sys
import threading
import sys
import codecs

HOST = ''
PORT = 10627

class Client(threading.Thread):
    def __init__(self, conn, addr):
        print("client from " + addr[0] + " is connected...")
        self.conn = conn
        self.addr = addr
        self.size = 1024

    def run(self):
        running = 1
        while running:
            data = self.conn.recv(self.size)
            if data:
                print(type(data))
                print(self.addr[0]+ ": " + data.decode('UTF-8'))
                #print(self.addr[0]+ ": " + unicode(data, "ISO-8859-1"))
            #else:
            #    self.conn.close()
            #    runnging = 0


class Server:
	def __init__(self):
		self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		#self.s.setblocking(0)
	
	def serve(self):
		self.s.bind((HOST, PORT))
		self.s.listen(1)
		while True:
			conn, addr = self.s.accept()
			conn.send('今天'.encode('utf-8'))
			c = Client(conn, addr)
			c.run()
		conn.close()


if __name__ == '__main__':
	PORT = int(input('PORT = '))
	server = Server()
	server.serve()