
OBJS = xbmc_remote.o

CXX=g++
CC=g++

CFLAGS+=-isysroot /Developer/SDKs/MacOSX10.4u.sdk -mmacosx-version-min=10.4
CFLAGS+=-Wall -I/opt/local/include/SDL
LDFLAGS+=-framework OpenGL -framework IOKit -framework Cocoa -framework Carbon -framework QuickTime -framework AudioUnit

all: $(OBJS)
	$(CXX) -o xbmc_remote $(LDFLAGS) $(OBJS) /opt/local/lib/libSDLmain.a /opt/local/lib/libSDL.a

.cpp.o:
	$(CXX) -c $(CFLAGS) $(DEFINES) $(INCLUDES) $< -o ${<:.cpp=.o}

.c.o:
	$(CC) -c $(CFLAGS) $(DEFINES) $(INCLUDES) $< -o ${<:.c=.o}

clean:
	$(RM) -rf *.o xbmc_remote
