EXE     = dtmf2num
CFLAGS	+= -O2 -s
BINDIR	= $(PREFIX)/bin
LIBS	= -lm

all:
	$(CC) $(CFLAGS) -c dtmf2num.c
	$(CC) $(CFLAGS) -c dsp.c
	$(CC) $(CFLAGS) -c resample2.c
	$(CC) $(CFLAGS) -o $(EXE) dtmf2num.o dsp.o resample2.o $(LIBS)

clean:
	@rm -f *.o $(EXE)
	
.PHONY:
	install
