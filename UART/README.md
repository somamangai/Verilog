UART

Also known as Serial Port, RS-232, COM Port, RS-485
This type of functionality has been referred to by many different names: Serial Port, RS-232 Interface, COM Port, but the correct name is actually UART (Universal Asynchronous Receiver Transmitter). A UART is one of the simplest methods of talking to your FPGA. It can be used to send commands from a computer to an FPGA and vice versa.

A UART is an interface that sends out usually a byte at a time over a single wire. It does not forward along a clock with the data, which is why it is called asynchronous as opposed to synchronous. UARTs can operate in either Half-Duplex (two transmitters sharing a line) or Full-Duplex (two transmitters each with their own line). UARTs have several parameters that can be set by the user. These are:

    Baud Rate            (9600, 19200, 115200, others)
    Number of Data Bits  (7, 8)
    Parity Bit           (On, Off)
    Stop Bits            (0, 1, 2)
    Flow Control         (None, On, Hardware)
These settings need to be the same on both sides of the interface (the receiver and transmitter) for communication to work correctly. When the settings are incorrect, strange and unusual characters can appear on the screen. Let’s look at each of these settings individually.

Baud Rate is the rate at which the serial data is transmitted. 9600 Baud means 9600 bits per second. Number of Data Bits is almost always set to eight. A Parity Bit can be appended after the data is sent. Parity is always computed by doing an XOR Operation on all of the data bits. A Stop Bit always set to 1, and there can be 0, 1, or 2 Stop Bits. Flow Control is not typically used in present day applications and will likely be set to None.

As mentioned previously, there is no clock that gets sent along with the data. In any interface that does not have a clock, the data must be sampled to recover it correctly. It needs to be sampled at least eight times faster than the rate of the data bits. This means that for an 115200 baud UART, the data needs to be sampled at at least 921.6 KHz (115200 baud * 8). A faster sampling clock can be used.
