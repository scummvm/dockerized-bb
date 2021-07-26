ASFLAGS = -mno-extern-sdata -march=vr4300 -mtune=vr4300 
CFLAGS = -g -mno-extern-sdata -std=gnu99 -O2 -fomit-frame-pointer -march=vr4300 -mtune=vr4300
N64PREFIX = /opt/toolchains/mips64-n64/bin/mips64-
CC = $(N64PREFIX)gcc
AS = $(N64PREFIX)as
LD = $(N64PREFIX)ld
AR = $(N64PREFIX)ar

all: libn64.a libn64utils.a libromfs.a libpakfs.a libframfs.a

libn64.a: entrypoint.o inthandler.o crashhandler.o VI_font.o VI.o SI.o AI.o MI.o PI.o N64sys.o N64FlashRAM.o premain.o
	$(AR) -rcs -o libn64.a entrypoint.o inthandler.o crashhandler.o VI_font.o VI.o SI.o AI.o MI.o PI.o N64sys.o N64FlashRAM.o premain.o

libn64utils.a: n64utils_misc.o n64utils_audio.o n64utils_video.o
	$(AR) -rcs -o libn64utils.a n64utils_misc.o n64utils_audio.o n64utils_video.o

libromfs.a: romfs.o
	$(AR) -rcs -o libromfs.a romfs.o

libpakfs.a: pakfs.o
	$(AR) -rcs -o libpakfs.a pakfs.o

libframfs.a: framfs.o
	$(AR) -rcs -o libframfs.a framfs.o

AI.o: AI.c AI.h
VI.o: VI.c VI_font.c VI.h
SI.o: SI.c SI.h N64sys.h
N64sys.o: N64sys.c N64sys.h regs.S

n64utils.o: n64utils.c n64utils.h

clean:
	rm -f *.o *.a
