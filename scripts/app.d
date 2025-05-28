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
   ushort register;
   ushort count = 1;
   ubyte server;

   GetoptResult opt = getopt(
         args,
         "ip", &ip,
         "f", &fc,
         "a", &server,
         "r", &register,
         "c", &count
         );
   if (opt.helpWanted) {
      writeln("usage: cli [OPTIONS]");
      writeln();
      writeln("Arguments");
      writeln("-ip\thost ip address");
      writeln("-a\tserver address");
      writeln("-r\tregister");
      writeln("-c\tnumber of value to read, or value to write");
      writeln("-f\tfunction code");
      writeln("\t1 read coil");
      writeln("\t2 read discrete input");
      writeln("\t3 read holding register");
      writeln("\t4 read input register");
      writeln("\t5 write single coil");
      writeln("\t6 write single register");
      return;
   }

   enum PORT = 502;

   Address addr = parseAddress(ip, PORT);
   socket.connect(addr);
   scope (exit) {
      socket.close();
      writeln("さよなら");
   }


   const(ubyte)[] msg;
   switch (fc) {
      case 1:
         msg = packReadCoil(42, server, register, count);
         break;
      case 2:
         msg = packReadDiscrete(42, server, register, count);
         break;
      case 3:
         msg = packReadHolding(42, server, register, count);
         break;
      case 4:
         msg = packReadInput(42, server, register, count);
         break;
      case 5:
         msg = packWriteCoil(42, server, register, count > 0 ? 0xff00 : 0);
         break;
      case 6:
         msg = packWriteRegister(42, server, register, count);
         break;
      default:
         assert(false);
   }

   socket.send(msg);
   writefln("send: %(0x%x,%)", msg);
   writeln();


    // Leggi risposta
    ubyte[1024] buffer;
    long received = socket.receive(buffer);
    if (received > 0) {
       if (fc < 3) {
          writeln("todo");
       } else if (fc < 5) {
          writefln("recv: %(0x%x, %)", buffer[0..received]);
          const(ushort)[] data = unpackWord(buffer[0..received]);
          foreach (i,d; data) {
             writefln("%d: %d (0x%x)", register + i, d,d);
          }
       } else {
          writefln("recv: %(0x%x, %)", buffer[0..received]);
          writeln("done!");
       }
    } else {
       writeln("no reply!");
    }
}
