I2C bus characteristics
Uses only 2 wires (named "SDA" and "SCL") in addition to power and ground
Can support over 100 devices on the same bus (each device on the bus has an address to be individually accessible)
Multi-master (for example, two CPUs can easily share the same I2C devices)
Industry standard (developed by Philips, adopted by many other manufacturers)
Used everywhere (TVs, PCs...)
but
Relatively slow (100Kbps base speed, with extensions up to 3.4Mbps)
Not plug-and-play
How it works
An I2C bus needs at a minimum an I2C master and an I2C slave.

The I2C master is a transaction initiator (a master can write-to or read-from a slave).
The I2C slave is a transaction recipient (a slave can be written-to or read-from a master).

An I2C transaction begins with a "start" condition, followed by the address of the device we wish to speak to, a bit to indicate if we want to read or write, the data written or read, and finally a "stop".
There are other details, like the need to have an "acknowledge" bit after each byte transmitted
