#!/usr/bin/python3

import socket
import select
import sys
import threading
import sys
import codecs
import signal
import json

HOST = ''
PORT = 10627

ACTION_TALK = 'TALK'

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
                self.conn.send((self.addr[0]+ ": " + data.decode('UTF-8')).encode('UTF-8'))
                #print(self.addr[0]+ ": " + unicode(data, "ISO-8859-1"))
            #else:
            #    self.conn.close()
            #    runnging = 0


class Server:
    def __init__(self):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.clients = 0
        self.clientmap = {}
        self.outputs = []
        self.s.bind((HOST, PORT))
        print ("Start listen to port " + str(PORT))
        self.s.listen(1)
        
        
        signal.signal(signal.SIGINT, self.sighandler)
        
    def sighandler(self, signum, frame):
        #Close the server
        print ("\nShutting down server...")
        for o in self.outputs:
            o.close()
        self.s.close()    
    
    def getname(self, client):
        info = self.clientmap[client]
        host, name = info[0][0], info[1]
        return '@'.join((name, host))
    
    def serve(self):
        inputs = [self.s, sys.stdin]
        self.outputs = []
        running = 1
    
        while running:
            try:
                inputready,outputready,exceptready = select.select(inputs, self.outputs, [])
            except select.error as e:
                break
            except socket.error as e:
                break
                
            for s in inputready:
                if s == self.s:
                    # handle server socket
                    client, address = self.s.accept()
                    print ("server: Got connection %d from %s" % (client.fileno(), address))
                    # read client login name
                    #cname = receive(client).split('NAME: ')[1]
                    
                    
                    self.clients += 1
                    client.send(('CLIENT: ' + str(address[0])).encode('utf-8'))
                    inputs.append(client)
                    cname = address[0]
                    self.clientmap[client] = (address, cname)
                    
                    for o in self.outputs:
                        o.send(("\n(Connected: New client %d from %s)" % (self.clients, self.getname(client))).encode('utf-8'))
                    
                    self.outputs.append(client)
                    
                elif s == sys.stdin:
                    # handle standard input
                    junk = sys.stdin.readline()
                    running = 0
                else:
                    # handle all other sockets
                    
                    try:
                        data = s.recv(1024)
                        if data:
                            print("[" + self.getname(s) + "] " + data.decode('UTF-8'))
                            data = data.split(b'\0',1)[0]
                            msg = json.loads(data.decode('UTF-8'))
                            
                            if msg['action'] == ACTION_TALK:
                                for o in self.outputs:
                                    if o != self.s:
                                       o.send((self.getname(s) + ":" + msg['content']).encode('UTF-8'))
                        else:
                            print ('server: %d hung up' % s.fileno())
                            self.clients -= 1
                            s.close()
                            inputs.remove(s)
                            self.outputs.remove(s)
                            
                            msg = '\n(Hung up: Client from %s' % self.getname(s)
                            for o in self.outputs:
                                o.send(msg.encode('utf-8'))
                    except socket.error as e:
                        inputs.remove(s)
                        self.outputs.remove(s)
                    
        """
        conn, addr = self.s.accept()
        conn.send('Welcome to server\n'.encode('utf-8'))
        c = Client(conn, addr)
        c.run()
        """
        #conn.close()


if __name__ == '__main__':
    #PORT = int(input('PORT = '))
    server = Server()
    server.serve()