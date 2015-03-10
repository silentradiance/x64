# SPITBOL makefile using tcc
host?=unix_64
HOST=$(host)

DEBUG:=$(debug)

debug?=0

gas?=as
GAS:=$(gas)

nasm?=nasm
NASM:=$(nasm)

os?=unix
OS:=$(os)

ws?=64
WS=$(ws)

TARGET=$(OS)_$(WS)

ASM=asm

trc?=0
TRC:=$(trc)
ifneq ($(TRC),0)
TRCOPT:=:trc
TRCDEF:=-Dtrc_trace
endif

NMFLAGS:=-p
# basebol determines which spitbol to use to compile
spitbol?=./bin/spitbol.$(HOST)

BASEBOL:=$(spitbol)

cc?=gcc
CC:=$(cc)

ifeq	($(DEBUG),1)
GFLAG=-g
endif

ARCH=-D$(TARGET)  -m$(WS)

CCOPTS:= $(ARCH) $(ITDEF) $(GFLAG) 
LDOPTS:= -lm $(GFLAG) $(ARCH)
LMOPT:=-lm

GASOPTS= --$(WS)

ifeq ($(OS),unix)
ELF:=elf$(WS)
else
EL:F=macho$(WS)
endif

# spitbol source file

OSINT=./osint

# Assembler info -- Intel 32-bit syntax
ifeq	($(DEBUG),0)
NASMOPTS = -f $(ELF) -D$(TARGET) $(ITDEF)
ASMOPTS = -f $(ELF) -D$(TARGET) $(ITDEF)
else
NASMOPTS = -g -f $(ELF) -D$(TARGET) $(ITDEF)
ASMOPTS = -g -f $(ELF) -D$(TARGET) $(ITDEF)
endif

# tools for processing Minimal source file.
DEF=def.sbl
ERR=err.sbl
LEX=lex.sbl
MIN=min.sbl

# implicit rule for building objects from C files.
./%.o: %.c
#.c.o:
	$(CC)  $(CCOPTS) -c  -o$@ $(OSINT)/$*.c

# implicit rule for building objects from nasm assembly language files.
.asm.o:
	$(NASM) $(ASMOPTS) -l $*.lst -o$@ $*.asm

# c headers common to all versions and all source files of SPITBOL:
CHDRS =	$(OSINT)/osint.h $(OSINT)/port.h $(OSINT)/sproto.h $(OSINT)/spitio.h $(OSINT)/spitblks.h $(OSINT)/globals.h 

# c headers unique to this version of SPITBOL:
UHDRS=	$(OSINT)/systype.h $(OSINT)/extern32.h $(OSINT)/blocks32.h $(OSINT)/system.h

# headers common to all C files.
HDRS=	$(CHDRS) $(UHDRS)

COBJS=sysax.o sysbs.o sysbx.o syscm.o sysdc.o sysdt.o sysea.o \
	sysef.o sysej.o sysem.o sysen.o sysep.o sysex.o sysfc.o \
	sysgc.o syshs.o sysid.o sysif.o sysil.o sysin.o sysio.o \
	sysld.o sysmm.o sysmx.o sysou.o syspl.o syspp.o sysrw.o \
	sysst.o sysstdio.o systm.o systty.o sysul.o sysxi.o  \
	break.o checkfpu.o compress.o cpys2sc.o \
	doset.o dosys.o fakexit.o flush.o gethost.o getshell.o \
	arith.o lenfnm.o math.o optfile.o osclose.o \
	osopen.o ospipe.o osread.o oswait.o oswrite.o prompt.o rdenv.o \
	st2d.o stubs.o swcinp.o swcoup.o syslinux.o testty.o\
	trypath.o wrtaout.o zz.o getargs.o trc.o main.o 


# build spitbol using nasm, build spitbol using as.
# link asm spitbol with static linking
# use fake target asmobj which appears only when all .s files built
asm: 
# run lex to get min.lex
	$(BASEBOL) -u $(TARGET)_$(ASM) $(LEX)
# run preprocessor to get asm for nasm as target
	$(BASEBOL) -u A pre.sbl <min.sbl >min-asm.spt 
# run asm to get .s and .err files
	$(BASEBOL) -u $(TARGET)$(TRCOPT) min-asm.spt
# run err 
	$(BASEBOL) -u $(TARGET)_$(ASM) $(ERR)
# use preprocessor to make version of rewriter for asm
	$(BASEBOL) -u A pre.sbl <$(DEF) >def-asm.spt
# run preprocessor to get sys for nasm as target
	$(BASEBOL) -u A pre.sbl <sys >sys.asm.def
# run asm definer to resolve system dependencies in sys
	$(BASEBOL) -u $(TARGET)  def-asm.spt <sys.asm.def >sys.s
# combine sys.s,min.s, and err.s to get sincle assembler source file
	cat <sys.s >spitbol.s
	cat <sbl.s >>spitbol.s
	cat <err.s >>spitbol.s
# assemble the translated file
	$(NASM) $(ASMOPTS) -ospitbol.o spitbol.s
# compile osint
	$(CC)  $(CCOPTS) -c  osint/*.c
# load objects
	$(CC) $(LDOPTS)  $(COBJS) spitbol.o $(LMOPT) -static -ospitbol

spitbol-dynamic: $(OBJS) $(AOBJS)
# link spitbol with dynamic linking
	$(CC) $(LDOPTS) $(OBJS) $(AOBJS) $(LMOPT)  -ospitbol 

gas:

# run lex to get min.lex
	$(BASEBOL) -u $(TARGET)_$(ASM) $(LEX)
# run preprocessor to get gas for ngas as target
	$(BASEBOL) -u G pre.sbl <min.sbl >min-gas.spt 
# run gas to get .s and .err files
	$(BASEBOL) -u $(TARGET):$(ITOPT) min-gas.spt
# run err 
	$(BASEBOL) -u $(TARGET)_gas $(ERR)
# use preprocessor to make version of rewriter for gas
	$(BASEBOL) -u G pre.sbl <$(DEF) >def-gas.spt
# run preprocessor to get sys for ngas as target
	$(BASEBOL) -u G pre.sbl <sys >sys.gas.def
# run gas definer to resolve system dependencies in sys
	$(BASEBOL) -u $(TARGET) def-gas.spt <sys.gas.def >sys.s
# combine sys.s,min.s, and err.s to get sincle assembler source file
	cat <sys.s >spitbol.s
	cat <sbl.s >>spitbol.s
	cat <err.s >>spitbol.s
# assemble the translated file
	$(NASM) $(ASMOPTS) -ogasbol.o spitbol.s
# compile osint
	$(CC)  $(CCOPTS) -c  osint/*.c
# load objects
	$(CC) $(LDOPTS)  $(COBJS) gasbol.o $(LMOPT) -static -ogasbol


ogas: 
# build gasbol, the asm variant  targeting gas format assembler
# link gasbol with static linking

# run preprocessor to get asm for nasm as target
	$(BASEBOL) -u G pre.sbl <asm.r >gas.spt 
# run lex to get s.lex
	$(BASEBOL) -u $(TARGET)_$(GAS) $(LEX)
# run gas to get .s and .err files
	$(BASEBOL) -u $(TARGET):$(ITOPT) gas.spt
# revise source .s 
	$(BASEBOL) -u $(TARGET) def.sbl <s.s >s.r
# run err 
	$(BASEBOL) -u $(TARGET)_gas $(ERR)
# revise gas file
	$(BASEBOL) -u $(TARGET) def.sbl <gas.gas >gas.r
# assemble the .gas file
	$(GAS) $(GASOPTS) -ogas.o gas.r
# compile osint
	$(CC)  $(CCOPTS) -c  osint/*.c
# load objects
	$(CC) $(LDOPTS)  $(COBJS) gas.o $(LMOPT) -static -ospitbol

gasbol-dynamic: $(OBJS) $(GOBJS) $(GOBJS)
# link gasbol with dynamic linking
	$(CC) $(LDOPTS) $(OBJS) $(GOBJS) $(LMOPT)  -ogasbol 

asm.spt:	asm
	$(BASEBOL) -u A -1=asm -2=asm.spt pre.sbl

gas.spt:	asm
	$(BASEBOL) -u G -1=asm -2=gas.spt pre.sbl

bootbol: 
# bootbol is for bootstrapping just link with what's at hand
#bootbol: $(OBJS)
# no dependencies so can link for osx bootstrap
	$(CC) $(LDOPTS)  $(OBJS) $(LMOPT) -obootbol

cobjs:
	cd bld
	$(CC) $(CCOPTS) -c ../osint/*.c
	touch cobjs
	cd ..

dic:
	nm -n s-nasm.o >s-nasm.nm
	spitbol test/map-$(WS).sbl <s-nasm.nm >s-nasm.dic
	spitbol it.sbl <ad >ae

# install binaries from ./bin as the system spitbol compilers
install:
	sudo cp ./bin/spitbol /usr/local/bin

s-gas.dic: s-gas.nm
	$(BASEBOL) test/map-$(WS).sbl <s-gas.nm >s-gas.dic

s-gas.nm: s-gas.o
	nm -n s-gas.o >s-gas.nm

trc-gas:	s-gas.dic trc.sbl
	$(BASEBOL) -u s-gas.dic trc.sbl <ad >ae

s-nasm.dic: s-nasm.nm
	$(BASEBOL) test/map-$(WS).sbl <s-nasm.nm >s-nasm.dic

s-nasm.nm: s-nasm.o
	nm $(NMFLAGS) s-nasm.o >s-nasm.nm

trc-nasm: s-nasm.dic it.sbl
	$(BASEBOL) -u s-nasm.dic trc.sbl <ad >ae

clean:
	rm -f *.spt *.[ors] *.def tbol* sbl.err sbl.lex sbl.equ ./asmbol ./gasbol ./spitbol 