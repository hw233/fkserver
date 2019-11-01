CC = g++
CFLAGS = -O2 -fPIC -std=c++14
LUADIR = ../../../3rd/lua
TARGET = ../../luaclib/GameFishingDLL.so
INCLUDEOPTION = -I. -I$(LUADIR)
LIBDIROPTION = -L. -L$(LUADIR) -L/usr/lib/x86_64-linux-gnu
LIBOPT = -lm
LUALIBTARGET = $(LUADIR)/liblua.a

.PHONY : all clean

all : $(TARGET)

$(LUALIBTARGET):
	cd $(LUADIR) && $(MAKE) CC='gcc -O2 -fPIC -std=gnu99' linux

COMPILE = $(CC) $(CFLAGS) -c $(INCLUDEOPTION)
LINK = $(CC) -shared -o $@ $(LIBDIROPTION) $(LIBOPT)

$(foreach o, $(shell ls *.cpp|sed 's/\.cpp/\.o/g'),$(o)):
	$(COMPILE) $(shell echo $@|sed 's/\.o/\.cpp/g')

$(TARGET): $(foreach o, $(shell ls *.cpp|sed s/.cpp/.o/g),$(o)) $(LUALIBTARGET)
	$(LINK) $^

clean :
	rm -f $(TARGET)
	rm *.o