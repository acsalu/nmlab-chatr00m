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
ACTION_LOGOUT = "LOGOUT"

ACTION_NEWUSER = "NEW_USER"
ACTION_GETONEROOMINFO = "GET_ONE_ROOM_INFO"
ACTION_ROOMLIST = "ROOM_LIST"

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
        self.socket_client_map = {}
        
        self.room_list = {}
        self.room_list[0] = Room(0, "Lobby", ROOM_TYPE_PUBLIC)
        self.next_room_id += 1

    def sighandler(self, signum, frame):
        #Close the server
        print ("\nShutting down server...")
        for s, c in self.socket_client_map.items():
            s.close()
        self.s.close()
        
    def serve(self):
        inputs = [self.s, sys.stdin]
        outputs = []
        running = 1
        lobby = self.room_list[0]
    
        while running:
            try:
                inputready, outputready, exceptready = select.select(inputs, outputs, [])
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
                    new_client = Client(new_socket, address, address[0])
                    self.socket_client_map[new_socket] = new_client

                    outputs.append(new_socket)
                    lobby.add_client(new_client)
                    broadcast_msg = {"action" :ACTION_NEWUSER, 
                                     "content":{"name"     :new_client.get_name(),
                                                "client_id":new_client.get_id(),
                                                "message"  :"OH~ho~ho~ho~~new friend %s" % new_client.get_name()}}
                    lobby.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                elif s == sys.stdin:
                    # handle standard input
                    junk = sys.stdin.readline()
                    running = 0
                else:
                    # handle all other sockets
                    try:
                        data = s.recv(1024)
                        if data:
                            print("[" + self.socket_client_map[s].get_name() + "] " + data.decode("UTF-8"))
                            data = data.split(b"\0",1)[0]
                            data = json.loads(data.decode("UTF-8"))
                            action = data["action"]
                            content = data["content"]

                            if action == ACTION_TALK:
                                r = self.room_list[content["room_id"]]
                                broadcast_msg = {"action" :action, 
                                                 "content":{"room_id":content["room_id"],
                                                            "name"   :self.socket_client_map[s].get_name(),
                                                            "message":content["message"]}}
                                r.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            elif action == ACTION_SETUSERNAME:
                                c = self.socket_client_map[s]
                                new_name = content["user_name"]
                                c.set_name(new_name)
                                broadcast_msg = {"action" :action, 
                                                 "content":{"client_name":new_name, 
                                                            "client_id"  :c.get_id()}}
                                # [Duty of client side]:change user's info in every rooms
                                lobby.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            # put some data to msg_queue of room??
                            elif action == ACTION_NEWROOM:
                                new_room = Room(self.next_room_id, content["room_name"], content["room_type"])
                                self.room_list[self.next_room_id] = new_room
                                self.next_room_id += 1
                                broadcast_msg = {"action" :action, 
                                                 "content":{"room_id"  :new_room.get_id(), 
                                                            "room_name":new_room.get_name(),
                                                            "room_type":new_room.type}}

                                room_host = self.socket_client_map[s]
                                new_room.add_client(room_host)
                                room_host.enter_room(new_room.get_id())
                                # new_client_list = data["content"]["client_list"]
                                # new_room.add_client_list(new_client_list)
                                # for c in new_client_list:
                                #     c.enter_room(new_room.get_id())
                                # broadcast to member of new room

                                # [Duty of client side]:create new room in client side
                                new_room.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                                sent_to_others = []
                                for r_id, room in self.room_list.items():
                                    sent_to_others.append({"room_id"      :r_id, 
                                                           "room_name"    :room.get_name(), 
                                                           "room_user_num":room.get_num_of_client()})

                                broadcast_msg = {"action" :ACTION_ROOMLIST, 
                                                 "content":{"room_list":sent_to_others}}
                                lobby.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                                
                            elif action == ACTION_ENTERROOM:
                                r = self.room_list[content["room_id"]]
                                c = self.socket_client_map[s]
                                r.add_client(c)
                                c.enter_room(r.get_id())

                                broadcast_msg = {"action" :action, 
                                                 "content":{"room_id"  :r.get_id(),
                                                            "client_id":c.get_id()}}
                                r.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            elif action == ACTION_LEAVEROOM:
                                r = self.room_list[content["room_id"]]
                                c = self.socket_client_map[s]
                                c.leave_room(r.get_id())
                                if r.remove_client(c) == -1:
                                    del self.room_list[content["room_id"]]
                                else:
                                    broadcast_msg = {"action" :action, 
                                                     "content":{"room_id"  :r.get_id(),
                                                                "client_id":c.get_id()}}
                                    r.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            elif action == ACTION_GETONEROOMINFO:
                                r = self.room_list[content["room_id"]]

                                broadcast_msg = {"action" :action, 
                                                 "content":{"room_id"         :r.get_id(),
                                                            "room_user_num"   :len(r.client_list),
                                                            "room_client_info":r.get_clients_info()}}
                                r.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            # elif action == ACTION_ROOMLIST:


                            else:
                                print ("unknown action!!!")

                        else:
                            print ("server: %d hung up" % s.fileno())
                            self.client_num -= 1
                            s.close()
                            inputs.remove(s)
                            outputs.remove(s)

                            c = self.socket_client_map[s]

                            for r_id in c.join_list:
                                r = self.room_list[r_id]
                                shounldDelRoom = r.remove_client(c)
                            broadcast_msg = {"action" :ACTION_LOGOUT, 
                                             "content":{"client_name":c.get_name(),
                                                        "client_id"  :c.get_id()}}
                            del self.socket_client_map[s]
                            if shounldDelRoom == -1:
                                del self.room_list[r_id]

                            lobby.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                    except socket.error as e:
                        inputs.remove(s)
                        outputs.remove(s)

            # for s in outputready:
            for r_id, room in self.room_list.items():
                if room.msg_queue.empty():
                    continue
                next_msg = room.msg_queue.get_nowait()
                for client in room.client_list:
                    if client.socket in outputready:
                        print (client.address)
                        client.socket.send(next_msg)
                    


if __name__ == "__main__":
    server = Server()
    server.serve()
