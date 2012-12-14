OOCFLAGS?=-v

all:
	rock $(OOCFLAGS)

clean:
	rock -x

.PHONY: all clean
