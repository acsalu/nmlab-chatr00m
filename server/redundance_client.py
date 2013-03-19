import threading

class Client(threading.Thread):
    def __init__(self, conn, addr):
        print("client from " + addr[0] + " is connected...")
        self.conn = conn
        self.addr = addr
        self.size = 1024

    def run(self):
        running = 1
        while running:
            data = self.conn.recv(self.size)
            if data:
                print(type(data))
                print(self.addr[0]+ ": " + data.decode('UTF-8'))
                self.conn.send((self.addr[0]+ ": " + data.decode('UTF-8')).encode('UTF-8'))
                #print(self.addr[0]+ ": " + unicode(data, "ISO-8859-1"))
            #else:
            #    self.conn.close()
            #    runnging = 0
