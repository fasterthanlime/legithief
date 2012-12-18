OOCFLAGS?=-v -g

all:
	rock $(OOCFLAGS)

editor:
	rock $(OOCFLAGS) --sourcepath=source editor

clean:
	rock -x

.PHONY: all clean editor
