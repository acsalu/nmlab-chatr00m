class Client:
    next_client_id = 1
    c_list = {}

    def __init__(self, socket, address, name):
        self.socket = socket
        self.client_id = Client.next_client_id
        Client.c_list[self.client_id] = self
        Client.next_client_id += 1
        self.address = address
        self.name = name
        self.join_list = [0]

    def set_name(self, name):
        self.name = name

    def get_name(self):
        return self.name

    def get_id(self):
        return self.client_id

    def enter_room(self, roomid):
        self.join_list.append(roomid)
    
    def leave_room(self, roomid):
        self.join_list.remove(roomid)
