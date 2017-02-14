GRLIB=../..
TOP=leon3mp
BOARD=mini-spartan6p
DESIGN=leon3-MiniSpartan6p
include $(GRLIB)/boards/$(BOARD)/Makefile.inc
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
UCF=$(GRLIB)/boards/$(BOARD)/default.ucf
UCF_PLANAHEAD=$(UCF)
EFFORT=high
XSTOPT=-uc leon3mp.xcf
SYNPOPT="set_option -pipe 1; set_option -retiming 1; set_option -write_apr_constraint 0"


VHDLOPTSYNFILES = sdctrl16.vhd config.vhd leon3mp.vhd

VHDLSIMFILES=mt48lc16m16a2.vhd testbench.vhd

SIMTOP=testbench
BITGEN=$(GRLIB)/boards/$(BOARD)/default.ut

TECHLIBS = unisim

LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip hynix ihp gleichmann  usbhc  opencores fmf ftlib gsi

DIRSKIP = b1553 pcif leon2 leon2ft crypto satcan ddr usb ata i2c \
	pci grusbhc haps slink ascs can pwm greth coremp7 ac97 atf \
	grlfpc

FILESKIP = i2cmst.vhd \
	mtie_maps.vhd \
	ftsrctrlc.vhd \
	ftsdctrl.vhd \
	ftsrctrl8.vhd \
	ftmctrl.vhd \
	ftsdctrl64.vhd \
	ftahbram.vhd \
	ftahbram2.vhd \
	sramft.vhd \
	nandfctrlx.vhd

include $(GRLIB)/bin/Makefile

##################  project specific targets ##########################

leon3mp.bit:$(VHDLSIMFILES)
	$(MAKE) ise

load-ram:leon3mp.bit
	xc3sprog -c ftdi -p0 leon3mp.bit

load-flash:leon3mp.bit
	xc3sprog -c ftdi -p0 $(GRLIB)/boards/$(BOARD)/bscan_spi_s6lx25_ftg256.bit
	xc3sprog -c ftdi -I leon3mp.bit
