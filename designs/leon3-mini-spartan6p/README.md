This LEON3 design is tailored to the Scarab Hardware [MiniSpartan6+](https://www.scarabhardware.com/minispartan6/) board.

Simulation and synthesis
------------------------

This design tries to use as much as possible free (as in freedom) tools and at least free (as in free beer) when impossible.


Note that the simulation doesn't work as expected yet.


To build the design:
```bash
make ise
```

To load into FPGA RAM:
```bash
make load-ram
```

To load into FPGA Flash:
```bash
make load-flash
```

Design specifics
----------------

* The AHB and processor is clocked from the 50 MHz clock.

* The SDRAM is working with the sdctrl16 memory controller taken from leon3-altera-de2-ep2c35 design.

* The Leon3 reset signal is connected to SW1 and active low.

* The UART DSU interface ie enabled and connected to interface B of ft2232H chip.
  Start GRMON with -uart /dev/ttyUSB1
  Note that the FT2232H chip interface B is configured as Asynchronous FIFO, to switch to UART mode
  type make config_USB_as_UART

* Alternatively you can connect through JTAG interface with grmon2.
  Start GRMON with -ftdi

* Output from GRMON2 should look similar to this:

```bash
  GRMON2 LEON debug monitor v2.0.80-beta 64-bit eval version

  Copyright (C) 2016 Cobham Gaisler - All rights reserved.
  For latest updates, go to http://www.gaisler.com/
  Comments or bug-reports to support@gaisler.com

  This eval version will expire on 18/04/2017

 JTAG chain (1): xc6slx25
  GRLIB build version: 4164
  Detected frequency:  50 MHz

  Component                            Vendor
  LEON3 SPARC V8 Processor             Cobham Gaisler
  AHB Debug UART                       Cobham Gaisler
  JTAG Debug Link                      Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  LEON3 Debug Support Unit             Cobham Gaisler
  PC133 SDRAM Controller               Cobham Gaisler
  Multi-processor Interrupt Ctrl.      Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler
  General Purpose I/O port             Cobham Gaisler

  Use command 'info sys' to print a detailed report of attached cores

grmon2>

```
