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

enum FC : ubyte {
   /**
    * Read from 1 to 2000 contiguous status of coils in a remote device.
    */
   readCoils = 0x01,
   /**
    * Read from 1 to 2000 contiguous status of discrete inputs in remote device.
    */
   readDiscreteInputs = 0x02,
   readHoldingRegisters = 0x03,
   readInputRegisters = 0x04,
   /**
    * Write a single output (coil) in a remote device
    */
   writeSingleCoil = 0x05,
   /**
    * Write a single holding register in a remote device
    */
   writeSingleRegister = 0x06
}

alias packReadCoil = pack!(FC.readCoils);
alias packReadDiscrete = pack!(FC.readDiscreteInputs);
alias packReadHolding = pack!(FC.readHoldingRegisters);
alias packReadInput = pack!(FC.readInputRegisters);
alias packWriteCoil = pack!(FC.writeSingleCoil);
alias packWriteRegister = pack!(FC.writeSingleRegister);

/**
 * Constructs a Modbus RTU request to read holding registers.
 *
 * This function creates a Modbus RTU request packet for the "ReadFC" operation,
 * used to retrieve values from one or more contiguous input registers of a Modbus slave device.
 *
 * Params:
 *   id       = An arbitrary identifier chosen by the caller, typically used to correlate requests with responses.
 *   unitId  = The Modbus unit address of the target device.
 *   register = The starting register address to read from.
 *   value    = The number of registers to read, or value to write
 *
 * Returns:
 *   A `const(ubyte)[]` representing the binary request packet ready to be sent over a Modbus RTU connection.
 *
 * Template Parameters:
 *   FC = A type that represents the Modbus function code to use. It must be `ReadFC`
 *
 * Examples:
 * ---
 * auto packet = packRead!(ReadFC.holding)(42, 1, 100, 2);
 * // `packet` now contains the Modbus RTU frame for reading 2 registers starting from register 100
 * // from slave unitId 1, with an application-level ID of 42.
 * ---
 *
 * See_Also:
 *   https://modbus.org/docs/Modbus_Application_Protocol_V1_1b3.pdf
 */
const(ubyte)[] pack(FC F)(in ushort id, in ubyte unitId, in ushort register, in ushort value) @safe pure {
   // non serve l'endian, di default e' bigendian
   import std.array : appender, Appender;
   import std.bitmanip : append;

   Appender!(const(ubyte)[]) buffer = appender!(const(ubyte)[])();
   // MBAP ModBus Application Protocol
   buffer.append!ushort(id); //identificativo casuale
   buffer.append!ubyte(0); // protocollo modbus
   buffer.append!ubyte(0);
   buffer.append!ubyte(0); // len
   buffer.append!ubyte(0x06); // addr + FC + register + value
   buffer.append!ubyte(unitId); // indirizzo del server

   // PDU Protocol Data Unit
   buffer.append!ubyte(F);
   buffer.append!ushort(register);
   buffer.append!ushort(value);

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

enum MBAP_LEN = 7; //
enum REPLY_FRAME_LEN = MBAP_LEN + 2; // MBAP_LEN(7bytes) + FC(1byte) + len(1bytes)
const(ubyte)[] unpackBit(const(ubyte)[] blob) @safe pure {
   return blob[REPLY_FRAME_LEN .. $];
}

ushort[] unpackWord(const(ubyte)[] blob) @safe pure {
   //data are in big-endian, which is the default in the read function
   //T read(T, Endian endianness = Endian.bigEndian, R)
   import std.bitmanip : read;
   import std.array: empty;

   const(ubyte)[] payload = blob[REPLY_FRAME_LEN .. $];
   ushort[] reply;
   while (!payload.empty) {
      reply ~= payload.read!ushort;
   }
   return reply;
}

@safe pure unittest {
  const(ubyte)[] blob = [
     0, 0x0f, 0, 0, 0, 0x5, 0x4, 0x3, 0x2,
     0x6, 0xa4 // 0x06a4
  ];
  ushort[] reply = unpackWord(blob);
  assert(reply.length == 1);
  assert(reply[0] == 1700);
}
