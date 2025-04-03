import std.socket;
import std.stdio;
import core.time : dur;
import promo;
import std.getopt;

void main(string[] args) {

    // Crea un socket TCP
   TcpSocket socket = new TcpSocket();
   socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, dur!"msecs"(4_000));

   string ip = "192.168.222.220";
   ushort fc = 3;
   ushort reference;
   ushort count = 1;
   ubyte server;

   GetoptResult opt = getopt(
         args,
         "ip", &ip,
         "f", &fc,
         "a", &server,
         "r", &reference,
         "c", &count
         );
   if (opt.helpWanted) {
      writeln("usage: cli [OPTIONS]");
      writeln();
      writeln("Arguments");
      writeln("-ip\thost ip address");
      writeln("-r\tstart reference");
      writeln("-c\tnumber of value to read");
      writeln("-f\tfunction code");
      writeln("\t1 read coil");
      writeln("\t2 read discrete input");
      writeln("\t3 read holding register");
      writeln("\t4 read input register");
      return;
   }

   enum IP = "192.168.222.220";
   enum PORT = 502;

   Address addr = parseAddress(IP, PORT);
   socket.connect(addr);

   //const(ubyte)[] msg = packRead!(ReadFC.holding)(42, 4, 0xd119, 1);
   const(ubyte)[] msg;
   switch (fc) {
      case 1:
         msg = packRead!(ReadFC.coil)(42, server, reference, count);
         break;
      case 2:
         msg = packRead!(ReadFC.discrete)(42, server, reference, count);
         break;
      case 3:
         msg = packRead!(ReadFC.holding)(42, server, reference, count);
         break;
      case 4:
         msg = packRead!(ReadFC.input)(42, server, reference, count);
         break;
      default:
         assert(false);
   }

   socket.send(msg);
   writefln("send: %(0x%x,%)", msg);
   writeln();


    // Leggi risposta
    ubyte[1024] buffer;
    size_t received = socket.receive(buffer);
    writefln("recv: %(0x%x, %)", buffer[0..received]);
    const(ushort)[] data = unpackWord(buffer[0..received]);
    foreach (i,d; data) {
       writefln("0x%x: %d 0x%x", reference + i, d,d);
    }

    socket.close();
}
