# promo
A minimal D library to build Modbus over TCP payloads.

This package implements the binary formatting of MODBUS requests and responses when transported over a MODBUS TCP/IP network.
It focuses solely on the creation of the data blob (including the MBAP header and PDU), without handling the transport layer (i.e., TCP socket communication).

For networking, the user is expected to rely on Phobos or any other library of choice.

## Features

- Encodes MODBUS TCP request/response payloads
- Supports MBAP header creation
- Stateless and lightweight
- Fully compatible with standard MODBUS TCP/IP devices
- Pure D implementation

## Installation

Add this package as a dependency in your `dub.sdl` or `dub.json` project file.

### `dub.sdl`

```sdl
dependency "promo" version="~>0.1.0"

```

### `dub.json`

```json
"dependencies": {
    "promo": "~>0.1.0"
}
```

## MBAP Header Structure

Each MODBUS TCP frame starts with a 7-byte MBAP (MODBUS Application Protocol) header:

| Field            | Size      | Description                                                                   |
| ---------------- | --------- | ----------------------------------------------------------------------------- |
| Transaction ID   | 2 bytes   | Identifier for pairing requests and responses                                 |
| Protocol ID      | 2 bytes   | Always `0` for MODBUS                                                         |
| Length           | 2 bytes   | Number of remaining bytes (Unit ID + PDU)                                     |
| Unit ID          | 1 byte    | Identifies the MODBUS slave device                                            |

This header is followed by the Protocol Data Unit (PDU), which includes the function code and associated data.

## Usage Example
See [cli](scripts/app.d).

## Notes

- This library does **not** implement TCP communication.
- You are expected to use `std.socket` or a similar transport layer to send and receive the data.
- Error handling and response parsing are also outside the scope of this package (for now).

## Contributing
Pull requests and issues are welcome. If you find a bug or want to add support for additional MODBUS function codes, feel free to contribute!

## License
MIT
