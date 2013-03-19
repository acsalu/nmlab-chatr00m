#!/usr/bin/python3

import socket
import select
import sys
import codecs
import signal
import json
import queue

HOST = ""
PORT = 10627

room_ID_max = 0
ACTION_TALK = "TALK"

# class Client:
#     def __init__(self, s, name):
#         self.s = s
#         self.name = name

# class Room:
#     def __init__(self, ):
#         pass


class Server:
    def __init__(self):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.clients = 0
        self.client_map = {}
        self.outputs = []
        self.s.bind((HOST, PORT))
        print ("Start listen to port " + str(PORT))
        self.s.listen(1)
        
        signal.signal(signal.SIGINT, self.sighandler)
        
        self.message_queues = {}
        self.message_queues[self.s] = queue.Queue()
        # key   : int (0 is lobby) 
        # value : list of sockets
        self.room_list = {}
        self.room_list[0] = [self.s]


    def sighandler(self, signum, frame):
        #Close the server
        print ("\nShutting down server...")
        for o in self.outputs:
            o.close()
        self.s.close()    
    
    def getname(self, client):
        info = self.client_map[client]
        host, name = info[0][0], info[1]
        return "@".join((name, host))

    def add():
        pass
    
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
                    #cname = receive(client).split("NAME: ")[1]
                    
                    
                    self.clients += 1
                    client.send(("CLIENT: " + str(address[0])).encode("utf-8"))
                    inputs.append(client)
                    cname = address[0]
                    self.client_map[client] = (address, cname)
                    
                    for o in self.outputs:
                        o.send(("\n(Connected: New client %d from %s)" % (self.clients, self.getname(client))).encode("utf-8"))
                    
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
                            print("[" + self.getname(s) + "] " + data.decode("UTF-8"))
                            data = data.split(b"\0",1)[0]
                            msg = json.loads(data.decode("UTF-8"))
                            
                            if msg["action"] == ACTION_TALK:
                                for o in self.outputs:
                                    if o != self.s:
                                       o.send((self.getname(s) + ":" + msg["content"]).encode("UTF-8"))
                        else:
                            print ("server: %d hung up" % s.fileno())
                            self.clients -= 1
                            s.close()
                            inputs.remove(s)
                            self.outputs.remove(s)
                            
                            msg = "\n(Hung up: Client from %s" % self.getname(s)
                            for o in self.outputs:
                                o.send(msg.encode("utf-8"))
                    except socket.error as e:
                        inputs.remove(s)
                        self.outputs.remove(s)


if __name__ == "__main__":
    server = Server()
    server.serve()