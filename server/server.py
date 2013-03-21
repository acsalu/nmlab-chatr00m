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

ACTION_TALK = "TALK"
ACTION_SETUSERNAME = "SETUSERNAME"
ACTION_NEWROOM = "NEWROOM"
ACTION_ENTERROOM = "ENTERROOM"
ACTION_LEAVEROOM = "LEAVEROOM"

ROOM_TYPE_PUBLIC = "Public"
ROOM_TYPE_PRIVATE = "Private"

class Client:
    next_client_id = 1

    def __init__(self, address, name):
        self.client_id = Client.next_client_id
        Client.next_client_id += 1
        self.address = address
        self.name = name
        self.join_list = [0]

    def set_name(self, name):
        self.name = name

    def get_name(self):
        return self.name

    def enter_room(self, roomid):
        self.join_list.append(roomid)
    
    def leave_room(self, roomid):
        self.join_list.remove(roomid)

class Room:
    def __init__(self, room_id, name, type):
        self.room_id = room_id
        self.name = name
        self.type = ROOM_TYPE_PUBLIC
        self.client_list = []
        self.msg_queue = queue.Queue()

    def add_client(self, client):
        self.client_list.append(client)
        # client.enter_room(self.room_id)

    def add_client_list(self, client_list):
        self.client_list.extend(client_list)
        # for c in client_list:
        #     c.enter_room(self.room_id)  

    def remove_client(self, client):
        self.client_list.remove(client)
        # client.leave_room(self.room_id)
    
    def put_message(self, message):
        self.msg_queue.put(message)

    # def getClientList(self):
    #     return self.clients


class Server:
    def __init__(self):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.s.bind((HOST, PORT))
        print ("Start listen to port " + str(PORT))
        self.s.listen(1)
        signal.signal(signal.SIGINT, self.sighandler)
        
        self.client_num = 0
        self.next_room_id = 0
        self.client_map = {}
        
        # key   : int (0 is lobby) 
        # value : list of sockets
        self.room_list = {}
        self.room_list[0] = Room(0, "Lobby", ROOM_TYPE_PUBLIC)
        self.next_room_id += 1

    def sighandler(self, signum, frame):
        #Close the server
        print ("\nShutting down server...")
        for o in outputs:
            o.close()
        self.s.close()    
    
    def serve(self):
        inputs = [self.s, sys.stdin]
        outputs = []
        running = 1
        lobby = self.room_list[0]
    
        while running:
            try:
                inputready,outputready,exceptready = select.select(inputs, outputs, [])
            except select.error as e:
                break
            except socket.error as e:
                break
                
            for s in inputready:
                if s == self.s:
                    # handle server socket
                    new_socket, address = self.s.accept()
                    print ("server: Got connection %d from %s" % (new_socket.fileno(), address))
                    # read client login name
                    # cname = receive(client).split("NAME: ")[1]
                    
                    self.client_num += 1
                    new_socket.send(("CLIENT: " + str(address[0])).encode("utf-8"))
                    
                    inputs.append(new_socket)
                    self.client_map[new_socket] = Client(address, address[0])
                    
                    # the bellow should be modified (send according to room)
                    lobby.put_message(("\n(Connected: New client %s from %s)" % (self.client_map[new_socket].get_name(), address)))
                    outputs.append(new_socket)
                    # the above should be modified

                    lobby.add_client(new_socket)

                elif s == sys.stdin:
                    # handle standard input
                    junk = sys.stdin.readline()
                    running = 0
                else:
                    # handle all other sockets
                    try:
                        data = s.recv(1024)
                        if data:
                            print("[" + self.client_map[s].get_name() + "] " + data.decode("UTF-8"))
                            data = data.split(b"\0",1)[0]
                            msg = json.loads(data.decode("UTF-8"))
                            if msg["action"] == ACTION_TALK:
                                r = self.room_list[int(msg["content"]["room_id"])]
                                print (msg["content"]["message"])
                                r.put_message((self.client_map[s].get_name() + " : ")+(msg["content"]["message"]))
                                
                            elif msg["action"] == ACTION_SETUSERNAME:
                                pass
                                # self.client_map[]

                            # put some msg to msg_queue of room??
                            elif msg["action"] == ACTION_NEWROOM:
                                new_room = Room(next_room_id, "room"+str(next_room_id), ROOM_TYPE_PUBLIC)
                                self.client_map[next_room_id] = new_room
                                self.next_room_id += 1

                                # new_room.add_client_list(--)

                            elif msg["action"] == ACTION_ENTERROOM:
                                r = self.room_list[int(msg["content"]["room_id"])]
                                # r.add_client(--)
                            elif msg["action"] == ACTION_LEAVEROOM:
                                r = self.room_list[int(msg["content"]["room_id"])]
                                # r.remove_client(--)


                        else:
                            print ("server: %d hung up" % s.fileno())
                            self.client_num -= 1
                            s.close()
                            inputs.remove(s)
                            outputs.remove(s)
                            
                            # msg = "\n(Hung up: Client from %s" % self.getname(s)
                            # for o in outputs:
                            #     o.send(msg.encode("utf-8"))
                    except socket.error as e:
                        inputs.remove(s)
                        outputs.remove(s)

            # for s in outputready:
            for r_id, room in self.room_list.items():
                if room.msg_queue.empty():
                    continue
                next_msg = room.msg_queue.get_nowait()
                for client_socket in room.client_list:
                    if client_socket in outputs:
                        client_socket.send(next_msg.encode("UTF-8"))
                    


if __name__ == "__main__":
    server = Server()
    server.serve()
