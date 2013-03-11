import socket

HOST = '140.112.18.220'    # The remote host
PORT = 10627              # The same port as used by the server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
while True:
        chat = input('> ')
            s.send(chat.encode('UTF-8'))
                #data = s.recv(1024)
                s.close()
                print('Received', repr(data))
