import queue

ROOM_TYPE_MESSAGE = 2
ROOM_TYPE_PUBLIC = 1
ROOM_TYPE_PRIVATE = 0

class Room:
    def __init__(self, room_id, name, room_type):
        self.id = room_id
        self.name = name
        self.type = room_type
        self.client_list = []
        self.msg_queue = queue.Queue()

    def get_num_of_client(self):
        return len(self.client_list)

    def add_client(self, client):
        if client not in self.client_list:
            self.client_list.append(client)
            return 1
        else:
            return 0

    # def add_client_list(self, client_list):
    #     self.client_list.extend(client_list)

    def remove_client(self, client):
        if client in self.client_list:
            self.client_list.remove(client)
        if self.get_num_of_client() == 0 and self.id != 0:
            return 0
            
    def get_clients_info(self):
        user_list = []
        for c in self.client_list:
            user_list.append( (c.id, c.name , c.picture) )
        return user_list

    def put_message(self, message):
        self.msg_queue.put(message)


    def get_the_other_client(self, client):
        if self.type != ROOM_TYPE_MESSAGE:
            return None
        else:
            for c in self.client_list:
                if c != client:
                    return c
            # bug 
            return None
