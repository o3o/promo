/**
 * Crea un pacchetto modbus per il trasporto in TCP/IP
 * come descritto a pag. 4 del documento modbus_messagging_implementation_guide_v1_ob.pdf
 *
 * Il MBAP (Modbus Application Protocol) header e'
 * ```
 * | field          | len | description                 |
 * | ---            | --- | ---                         |
 * | transaction id | 2   |                             |
 * | Protocol id    | 2   | impostare a 00 00           |
 * | length         | 2   | numero di bytes che seguono |
 * | unit id        | 1   | id dello slave remoto       |
 * ```
 *
 * Seguito da
 * ```
 * | field         | len | description     |
 * | ---           | --- | ---             |
 * | function code | 1   | codice funzione |
 * | data          | n   | dati            |
 * ```
 *
 * Authors: Orfeo Da Vià
 */
module promo;

import std.string;
import std.exception;
import std.variant;
import std.datetime;
import std.conv;

enum ReadFC : ubyte {
   coil = 0x01,
   discrete = 0x02,
   holding = 0x03,
   input = 0x04,
}
enum WriteFC : ubyte {
   coil = 0x05,
   holding = 0x06
}

const(ubyte)[] packRead(ReadFC FC)(in ushort id, in ubyte address, in ushort register, in ushort qty) @safe pure {
   // non serve l'endian, di default e' bigendian
   import std.array : appender, Appender;
   import std.bitmanip : append;

   Appender!(const(ubyte)[]) buffer = appender!(const(ubyte)[])();

   buffer.append!ushort(id); //identificativo casuale
   buffer.append!ubyte(0); // protocollo modbus
   buffer.append!ubyte(0);
   buffer.append!ubyte(0); // len
   buffer.append!ubyte(0x06);
   buffer.append!ubyte(address); // indirizzo del server
   buffer.append!ubyte(FC);

   //ubyte[2] r = nativeToBigEndian(register);
   buffer.append!ushort(register);
   buffer.append!ushort(qty);

   return buffer.data;
}

@safe pure unittest {
   const(ubyte)[] blob = packRead!(ReadFC.input)(42, 10, 0xd000, 1);
   assert(blob == [
         0, 0x2a,
         0, 0,
         0, 6,
         0xa, // addr
         4, // fc
         0xd0, 0,
         0, 1]
         );

   // pagina 12
   // legge 20 - 38

   const(ubyte)[] b01 = packRead!(ReadFC.coil)(42, 10, 0x13, 0x12);

   assert(b01 == [
         0, 0x2a, // 42
         0, 0, //
         0, 6, // len
         0xa, // addr
         1, // fc
         0, 0x13,
         0, 0x12]
         );


}

const(ubyte)[] unpackBit(const(ubyte)[] blob) @safe pure {
   return blob[9 .. $];
}

ushort[] unpackWord(const(ubyte)[] blob) @safe pure {
   import std.bitmanip : read;
   const(ubyte)[] payload = blob[9 .. $];
   ushort[] reply;
   while (!payload.empty) {
      reply ~= payload.read!ushort;
   }
   return reply;
}

@safe pure unittest {
  const(ubyte)[] blob = [0, 0x0f, 0, 0, 0, 0x5, 0x4, 0x3, 0x2, 0x6, 0xa4];
  ushort[] reply = unpackWord(blob);
  assert(reply.length == 1);
  assert(reply[0] == 1700);
}
