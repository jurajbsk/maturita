module sdc.distribute;
import core.sys.windows.windows;
import core.sys.windows.winsock2;
import lib.io;
import lib.memory.alloc;
import sdc.compile;

pragma(lib, "ws2_32.lib");
enum PORT = 5505;

void openServer(ushort port = PORT) {
	WSADATA wsaData;
	WSAStartup(0x202, &wsaData);

    sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(port);

	SOCKET listenSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	bind(listenSocket, cast(sockaddr*)&serverAddr, serverAddr.sizeof);
	listen(listenSocket, 1);
    SOCKET clientSocket = accept(listenSocket, null, null);

	writeln("Connected");

    ulong len;
	uint received;

    while (received < len.sizeof) {
        received += recv(clientSocket, &len+received, cast(int)len.sizeof-received, 0);
    }

	char[] buffer = malloc!char(len);
	received = 0;
	while (received < len*buffer[0].sizeof) {
        received += recv(clientSocket, buffer.ptr+received, cast(int)(buffer.length*buffer[0].sizeof-received), 0);
    }
    
    //long[] resultArray = foo(array, arrayLength, &resultLength);
	ubyte[] backData = cast(ubyte[])compile(buffer.ptr);
    
	ulong sent;
	len = backData.length;
	while (sent < ulong.sizeof) {
        sent += send(clientSocket, cast(char*)&len+sent, cast(int)(long.sizeof - sent), 0);
    }

	sent = 0;
	while (sent < len*backData[0].sizeof) {
        sent += send(clientSocket, cast(char*)backData.ptr+sent, cast(int)(backData.length*backData[0].sizeof - sent), 0);
    }
    
    closesocket(clientSocket);
}

struct sockaddr_in
{
    short sin_family = AF_INET;
    ushort sin_port;
    in_addr sin_addr;
    ubyte[8] sin_zero;
}

void sendToServer(string array, string ipAddress, ushort port = PORT) {
	WSADATA wsaData;
	WSAStartup(0x202, &wsaData);

    SOCKET clientSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    serverAddr.sin_addr.s_addr = inet_addr(ipAddress.ptr);

    int c = connect(clientSocket, cast(sockaddr*)&serverAddr, serverAddr.sizeof);
	assert(c == 0);

	ulong len;
	ulong sent;
	len = array.length;
	while (sent < ulong.sizeof) {
        sent += send(clientSocket, cast(char*)&len+sent, cast(int)(long.sizeof - sent), 0);
    }

	sent = 0;
	while (sent < len*array[0].sizeof) {
        int x = send(clientSocket, cast(char*)array.ptr+sent, cast(int)(array.length*array[0].sizeof - sent), 0);
		sent += (x >= 0)? x : 0;
    }
	
	len = 0;
	uint received;

    while (received < len.sizeof) {
        received += recv(clientSocket, &len+received, cast(int)len.sizeof-received, 0);
    }

	ubyte[] buffer = malloc!ubyte(len);
	received = 0;
	while (received < len*buffer[0].sizeof) {
        received += recv(clientSocket, buffer.ptr+received, cast(int)(buffer.length*buffer[0].sizeof-received), 0);
    }
	void* file = CreateFileA("object.o", 0x80000000, 0x00000001, null, 3, 128, null);
	writeA(file, cast(string)buffer);

    closesocket(clientSocket);
    return;
}