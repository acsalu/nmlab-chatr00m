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
ACTION_SETUSERNAME = "SETUP_USERNAME"
ACTION_NEWROOM = "NEW_ROOM"
ACTION_ENTERROOM = "ENTER_ROOM"
ACTION_LEAVEROOM = "LEAVE_ROOM"

ACTION_NEWUSER = "NEW_USER"
ACTION_GETROOMUSERINFO = "GET_ROOM_USER_INFO"

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
        
        self.room_list = {}
        self.room_list[0] = Room(0, "Lobby", ROOM_TYPE_PUBLIC)
        self.next_room_id += 1

    def sighandler(self, signum, frame):
        #Close the server
        print ("\nShutting down server...")
        # for o in outputs:
        #     o.close()
        # self.s.close()  

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
                    
                    self.client_num += 1
                    
                    inputs.append(new_socket)
                    new_client = Client(address, address[0])
                    self.client_map[new_socket] = new_client

                    outputs.append(new_socket)
                    lobby.add_client(new_client)
                    broadcast_msg = {"action" :ACTION_NEWUSER, 
                                     "content":{"name"     :new_client.get_name(),
                                                "client_id":new_client.get_id(),
                                                "message"  :"OH~ho~ho~ho~~new friend %s" % new_client.get_name()}}
                    lobby.put_message(json.dumps(broadcast_msg))

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
                                print (data["content"]["message"])
                                content = data["content"]
                                broadcast_msg = {"action" :ACTION_TALK, 
                                                 "content":{"room_id":content["room_id"],
                                                            "name"   :self.client_map[s].get_name(),
                                                            "message":content["message"]}}
                                r.put_message(json.dumps(broadcast_msg))

                            elif data["action"] == ACTION_SETUSERNAME:
                                c = self.client_map[s]
                                new_name = data["content"]["user_name"]
                                c.set_name(new_name)
                                broadcast_msg = {"action" :ACTION_SETUSERNAME, 
                                                 "content":{"user_name":new_name, 
                                                            "client_id":c.get_id()}}
                                # [Duty of client side]:change user's info in every rooms
                                lobby.put_message(json.dumps(broadcast_msg))

                            # put some data to msg_queue of room??
                            elif data["action"] == ACTION_NEWROOM:
                                new_room = Room(self.next_room_id, data["content"]["room_name"], data["content"]["room_type"])
                                self.room_list[self.next_room_id] = new_room
                                self.next_room_id += 1
                                broadcast_msg = {"action" :ACTION_NEWROOM, 
                                                 "content":{"room_id"  :new_room.get_id(), 
                                                            "room_name":new_room.get_name(),
                                                            "room_type":new_room.type}}

                                # [Duty of client side]:create new room in client side
                                lobby.put_message(json.dumps(broadcast_msg))
                                room_host = self.client_map[s]
                                new_room.add_client(room_host)
                                room_host.enter_room(new_room.get_id())
                                # new_client_list = data["content"]["client_list"]
                                # new_room.add_client_list(new_client_list)
                                # for c in new_client_list:
                                #     c.enter_room(new_room.get_id())
                                # broadcast to member of new room

                            elif data["action"] == ACTION_ENTERROOM:
                                r = self.room_list[data["content"]["room_id"]]
                                c = self.client_map[s]
                                r.add_client(c)
                                c.enter_room(r.get_id())

                                broadcast_msg = {"action" :ACTION_ENTERROOM, 
                                                 "content":{"room_id"  :r.get_id(),
                                                            "client_id":c.get_id()}}
                                r.put_message(json.dumps(broadcast_msg))

                            elif data["action"] == ACTION_LEAVEROOM:
                                r = self.room_list[data["content"]["room_id"]]
                                c = self.client_map[s]
                                r.remove_client(c)
                                c.leave_room(r.get_id)

                                broadcast_msg = {"action" :ACTION_ENTERROOM, 
                                                 "content":{"room_id"  :r.get_id(),
                                                            "client_id":c.get_id()}}
                                r.put_message(json.dumps(broadcast_msg))

                            elif data["action"] == ACTION_GETROOMUSERINFO:
                                r = self.room_list[data["content"]["room_id"]]

                                broadcast_msg = {"action" :ACTION_GETROOMUSERINFO, 
                                                 "content":{"room_id"         :r.get_id(),
                                                            "room_user_num"   :len(r.client_list),
                                                            "room_client_info":r.get_clients_info()}}
                                r.put_message(json.dumps(broadcast_msg))

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
