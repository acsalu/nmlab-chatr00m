import queue

class Client:
    next_client_id = 1
    c_list = {}

    def __init__(self, socket, address):
        self.socket = socket
        self.id = Client.next_client_id
        Client.c_list[self.id] = self
        Client.next_client_id += 1
        self.address = address
        self.name = None
        self.picture = 1
        self.join_list = [0]
        self.msg_queue = queue.Queue()

    def enter_room(self, roomid):
        if roomid not in self.join_list:
            self.join_list.append(roomid)
    
    def leave_room(self, roomid):
        if roomid in self.join_list:
            self.join_list.remove(roomid)

    def put_message(self, message):
        self.msg_queue.put(message)

