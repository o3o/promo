/**
 * Creates a modbus packet for TCP/IP transport as described on page 4 of
 * modbus_messagging_implementation_guide_v1_ob.pdf
 *
 * MBAP (Modbus Application Protocol) header is:
 * ```
 * | field          | len | description                        |
 * | ---            | --- | ---                                |
 * | transaction id | 2   | Transaction identifier             |
 * | Protocol id    | 2   | Protocol Identifier (set to 00 00) |
 * | length         | 2   | Length                             |
 * | unit id        | 1   | Unit Identifier                    |
 * ```
 *
 * Followed by:
 * ```
 * | field         | len | description   |
 * | ---           | --- | ---           |
 * | function code | 1   | function code |
 * | data          | n   | payload       |
 * ```
 *
 * Authors: Orfeo Da Vià
 */
module promo;

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
   import std.array: empty;

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
