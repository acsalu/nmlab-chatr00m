import queue

ROOM_TYPE_PUBLIC = 1
ROOM_TYPE_PRIVATE = 0

class Room:
    def __init__(self, room_id, name, type):
        self.room_id = room_id
        self.name = name
        self.type = ROOM_TYPE_PUBLIC
        self.client_list = []
        self.msg_queue = queue.Queue()

    def get_id(self):
        return self.room_id

    def set_name(self, name):
        self.name = name

    def get_name(self):
        return self.name

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
  
    def get_clients_info(self):
        user_dic = {}
        for c in self.client_list:
            user_dic[c.get_id()] = c.get_name()
        return user_dic

    def put_message(self, message):
        self.msg_queue.put(message)

    # def getClientList(self):
    #     return self.clients