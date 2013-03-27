#!/usr/bin/python3

import socket
import select
import sys
import codecs
import signal
import json
import queue
import time
import threading
from room import *
from client import *

HOST = ""
PORT = 10627

JSON_HEADER = "#@$@#"

ACTION_TALK = "TALK"
ACTION_SETUSERNAME = "SET_USERNAME"
ACTION_SETUSERPIC = "SET_USERPIC"
ACTION_NEWROOM = "NEW_ROOM"
ACTION_INVITE = "INVITE"
ACTION_ENTERROOM = "ENTER_ROOM"
ACTION_LEAVEROOM = "LEAVE_ROOM"
ACTION_LOGOUT = "LOGOUT"
ACTION_NEWUSER = "NEW_USER"
ACTION_ONEROOMINFO = "ONE_ROOM_INFO"
ACTION_ROOMLIST = "ROOM_LIST"
ACTION_NEWMESSAGE = "NEW_MESSAGE"
ACTION_ASKTOSEND = "ASKTOSEND"
ACTION_AGREETORECEIVE = "AGREETORECEIVE"

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
        
        self.broadcast_timer = None
        self.broadcast_new_room_list()
        self.broadcast_new_clients_list()

    def sighandler(self, signum, frame):
        #Close the server
        print ("\nShutting down server...")
        for s, c in self.socket_client_map.items():
            s.close()
        self.s.close()
        self.timer_room_list.cancel()
        self.timer_clients_list.cancel()
        sys.exit()

    def broadcast_new_room_list(self):
        all_rooms_info = []
        for r_id, room in self.room_list.items():
            if room.type == ROOM_TYPE_PUBLIC:
                all_rooms_info.append({"room_id"      :r_id, 
                                       "room_name"    :room.name, 
                                       "room_user_num":room.get_num_of_client()})

        broadcast_msg = {"action" :ACTION_ROOMLIST, 
                         "content":{"room_list":all_rooms_info}}
        self.room_list[0].put_message(json.dumps(broadcast_msg).encode("UTF-8"))
        self.timer_room_list = threading.Timer(1.0, self.broadcast_new_room_list)
        self.timer_room_list.start()

    def broadcast_new_clients_list(self):
        for r_id, r in self.room_list.items():
            broadcast_msg = {"action" :ACTION_ONEROOMINFO, 
                             "content":{"room_id"         :r_id,
                                        "room_user_num"   :len(r.client_list),
                                        "room_client_info":r.get_clients_info()}}
            r.put_message(json.dumps(broadcast_msg).encode("UTF-8"))
        self.timer_clients_list = threading.Timer(2.0, self.broadcast_new_clients_list)
        self.timer_clients_list.start()
        
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
                    new_client = Client(new_socket, address)
                    self.socket_client_map[new_socket] = new_client

                    outputs.append(new_socket)
                    lobby.add_client(new_client)
                    broadcast_msg = {"action" :ACTION_NEWUSER, 
                                     "content":{"name"     :new_client.name,
                                                "client_id":new_client.id}}
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
                            print("[" + self.socket_client_map[s].address[0] + "] " + data.decode("UTF-8"))
                            data = data.split(b"\0",1)[0]
                            data = json.loads(data.decode("UTF-8"))
                            action = data["action"]
                            content = data["content"]

                            if action == ACTION_TALK:
                                r = self.room_list[content["room_id"]]
                                c = self.socket_client_map[s]
                                broadcast_msg = {"action" :ACTION_TALK, 
                                                 "content":{"room_id"    :content["room_id"],
                                                            "client_id"  :c.id,
                                                            "client_name":c.name,
                                                            "message"    :content["message"]}}
                                r.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            elif action == ACTION_SETUSERNAME:
                                c = self.socket_client_map[s]
                                new_name = content["user_name"]
                                c.name = new_name
                                msg = {"action" :ACTION_SETUSERNAME,
                                       "content":{"client_id" :c.id}}
                                c.put_message(json.dumps(msg).encode("UTF-8"))

                            elif action == ACTION_SETUSERPIC:
                                c = self.socket_client_map[s]
                                new_pic = content["image"]
                                c.picture = new_pic

                            elif action == ACTION_NEWROOM:
                                new_room = Room(self.next_room_id, content["room_name"], content["room_type"])
                                self.room_list[self.next_room_id] = new_room
                                self.next_room_id += 1
                                broadcast_msg = {"action" :ACTION_NEWROOM, 
                                                 "content":{"room_id"  :new_room.id, 
                                                            "room_name":new_room.name,
                                                            "room_type":new_room.type}}

                                room_creator = self.socket_client_map[s]
                                new_room.add_client(room_creator)
                                room_creator.enter_room(new_room.id)

                                new_room.put_message(json.dumps(broadcast_msg).encode("UTF-8"))
                              
                            elif action == ACTION_INVITE:
                                r = self.room_list[content["room_id"]]
                                c = Client.c_list[content["client_id"]]
                                if r.add_client(c) != 0:
                                    c.enter_room(r.id)

                                    broadcast_msg = {"action" :ACTION_ENTERROOM, 
                                                     "content":{"room_id"    :r.id,
                                                                "room_name"  :r.name,
                                                                "room_type"  :r.type}}
                                    c.put_message(json.dumps(broadcast_msg).encode("UTF-8"))


                            elif action == ACTION_ENTERROOM:
                                r = self.room_list[content["room_id"]]
                                c = self.socket_client_map[s]
                                if r.add_client(c) != 0:
                                    c.enter_room(r.id)

                                    broadcast_msg = {"action" :ACTION_ENTERROOM, 
                                                     "content":{"room_id"    :r.id,
                                                                "room_name"  :r.name,
                                                                "room_type"  :r.type}}
                                    c.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                            elif action == ACTION_LEAVEROOM:
                                r = self.room_list[content["room_id"]]
                                c = self.socket_client_map[s]
                                c.leave_room(r.id)
                                if r.remove_client(c) == 0:
                                    del self.room_list[content["room_id"]]

                            elif action == ACTION_NEWMESSAGE:
                                new_msg_room = Room(self.next_room_id, "message", ROOM_TYPE_MESSAGE)
                                self.room_list[self.next_room_id] = new_msg_room
                                self.next_room_id += 1
                                secret_msg = {"action" :ACTION_NEWMESSAGE, 
                                              "content":{"room_id"  :new_msg_room.id}}

                                room_creator = self.socket_client_map[s]
                                new_msg_room.add_client(room_creator)
                                room_creator.enter_room(new_msg_room.id)

                                the_other_client = Client.c_list[content["client_id"]]
                                new_msg_room.add_client(the_other_client)
                                the_other_client.enter_room(new_msg_room.id)

                                new_msg_room.put_message(json.dumps(secret_msg).encode("UTF-8"))
                           

                            elif action == ACTION_ASKTOSEND:
                                r = self.room_list[content["room_id"]]
                                sender = self.socket_client_map[s]
                                receiver = r.get_the_other_client(sender)

                                secret_msg = {"action" :ACTION_ASKTOSEND, 
                                              "content":{"room_id"    :r.id,
                                                         "file"       :content["file"],
                                                         "sender_IP"  :sender.address[0]}}
                                receiver.put_message(json.dumps(secret_msg).encode("UTF-8"))

                            elif action == ACTION_AGREETORECEIVE:
                                r = self.room_list[content["room_id"]]
                                receiver = self.socket_client_map[s]
                                sender = r.get_the_other_client(receiver)

                                secret_msg = {"action" :ACTION_AGREETORECEIVE, 
                                              "content":{"room_id"    :r.id,
                                                         "receiver_IP":receiver.address[0]}}
                                sender.put_message(json.dumps(secret_msg).encode("UTF-8"))

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
                                             "content":{"client_name":c.name,
                                                        "client_id"  :c.id}}
                            del self.socket_client_map[s]
                            if shounldDelRoom == 0:
                                del self.room_list[r_id]

                            lobby.put_message(json.dumps(broadcast_msg).encode("UTF-8"))

                    except socket.error as e:
                        inputs.remove(s)
                        outputs.remove(s)

                    except BaseException as e:
                        print (type(e))


            # for s in outputready:
            for r_id, room in self.room_list.items():
                if room.msg_queue.empty():
                    continue
                next_msg = room.msg_queue.get_nowait()
                for client in room.client_list:
                    if client.socket in outputready:
                        client.socket.send(next_msg)

            for s, c in self.socket_client_map.items():
                if c.msg_queue.empty():
                    continue
                next_msg = c.msg_queue.get_nowait()
                s.send(next_msg)
                    


if __name__ == "__main__":
    server = Server()
    server.serve()
