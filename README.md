# promo

This package impements the encapsulation of a MODBUS request or response when it is
carried on a MODBUS TCP/IP network.


## MBAP Header description
The MBAP Header contains the following fields:

| Fields                 | Length  | Description                                                                    | Client                               | Server                                           |
| ---                    | ---     | ---                                                                            | ---                                  | ---                                              |
| Transaction identifier | 2 Bytes | Identification of a MODBUS Request / Response transaction.                     | Initialized by the client            | Recopied by the server from the received request |
| Protocol Identifier    | 2 Bytes | 0 = MODBUS protocol                                                            | Initialized by the client            | Recopied by the server from the received request |
| Length                 | 2 Bytes | Number of following bytes                                                      | Initialized by the client ( request) | Initialized by the server ( Response)            |
| Unit Identifier        | 1 Byte  | Identification of a remote slave connected on a serial line or on other buses. | Initialized by the client            | Recopied by the server from the received request |

The header is 7 bytes long:

* Transaction Identifier  - It is used for transaction pairing, the MODBUS server copies
in the response the transaction identifier of the request.
* Protocol Identifier  – It is used for intra-system multiplexing. The MODBUS protocol
is identified by the value 0.
* Length  - The length field is a byte count of the following fields, including the Unit
Identifier and data fields.


