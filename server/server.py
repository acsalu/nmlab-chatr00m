#!/usr/bin/python3

import socket
import select
import sys
import codecs
import signal
import json
import queue
from room import *
from client import *

HOST = ""
PORT = 10627

ACTION_TALK = "TALK"
ACTION_SETUSERNAME = "SETUSERNAME"
ACTION_NEWROOM = "NEWROOM"
ACTION_ENTERROOM = "ENTERROOM"
ACTION_LEAVEROOM = "LEAVEROOM"


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

                    # should broadcast new client info (client_id, name, ...)
                    lobby.put_message(("\n(Connected: New client %s from %s)" % (self.client_map[new_socket].get_name(), address)))
                    outputs.append(new_socket)

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
                            data = json.loads(data.decode("UTF-8"))

                            if data["action"] == ACTION_TALK:
                                r = self.room_list[data["content"]["room_id"]]
                                r.put_message((self.client_map[s].get_name() + " : ")+(data["content"]["message"]))
                                

                                r = self.room_list[data["content"]["room_id"]]
                                print (data["content"]["message"])
                                content = data["content"]
                                broadcast_msg = {"action" :ACTION_TALK, 
                                                 "content":{"room_id":content["room_id"],
                                                            "name":self.client_map[s].get_name(),
                                                            "message":content["message"]}}
                                r.put_message(json.dump(broadcast_msg))

                            elif data["action"] == ACTION_SETUSERNAME:
                                pass
                                c = self.client_map[s]
                                new_name = data["content"]["user_name"]
                                c.set_name(new_name)
                                broadcast_msg = {"action" :ACTION_SETUSERNAME, 
                                                 "content":{"user_name":new_name, 
                                                            "client_id":c.get_id()}}
                                # [Duty of client side]:change user's info in every rooms
                                lobby.put_message(json.dump(broadcast_msg))

                            # put some data to msg_queue of room??
                            elif data["action"] == ACTION_NEWROOM:
                                pass
                                new_room = Room(next_room_id, "room"+str(next_room_id), ROOM_TYPE_PUBLIC)
                                self.client_map[next_room_id] = new_room
                                self.next_room_id += 1

                                broadcast_msg = {"action" :ACTION_NEWROOM, 
                                                 "content":{"room_id"  :new_room.get_id(), 
                                                            "room_name":new_room.get_name()}
                                                            "room_type":new_room.type}

                                # [Duty of client side]:create new room in client side
                                lobby.put_message(json.dump(broadcast_msg))

                                new_client_list = data["content"]["client_list"]
                                new_room.add_client_list(new_client_list)
                                for c in new_client_list:
                                    c.enter_room(new_room.get_id())
                                # broadcast to member of new room

                            elif data["action"] == ACTION_ENTERROOM:
                                pass
                                r = self.room_list[data["content"]["room_id"]]
                                c = self.client_map[s]
                                r.add_client(c)
                                c.enter_room(r.get_id())

                                broadcast_msg = {"action" :ACTION_ENTERROOM, 
                                                 "content":{"room_id"  :r.get_id(),
                                                            "client_id":c.get_id()}}
                                r.put_message(json.dump(broadcast_msg))

                            elif data["action"] == ACTION_LEAVEROOM:
                                pass
                                r = self.room_list[data["content"]["room_id"]]
                                c = self.client_map[s]
                                r.remove_client(c)
                                c.leave_room(r.get_id)

                                broadcast_msg = {"action" :ACTION_ENTERROOM, 
                                                 "content":{"room_id"  :r.get_id(),
                                                            "client_id":c.get_id()}}
                                r.put_message(json.dump(broadcast_msg))

                            else:
                                print ("unknown action!!!")

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
