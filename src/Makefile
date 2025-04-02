OS=$(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

unix:
	mkdir -p ../lib/linux
	$(CC) -c -O2 -Os -fPIC pico_ecs.c
	$(AR) rcs ../lib/linux/libpico_ecs.a pico_ecs.o
	rm *.o

darwin:
	mkdir -p ../lib/darwin
	$(CC) -arch x86_64 -c -O2 -Os -fPIC pico_ecs.c -o pico_ecs-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64 -c -O2 -Os -fPIC pico_ecs.c -o pico_ecs-arm64.o -mmacosx-version-min=10.12
	lipo -create pico_ecs-x86_64.o pico_ecs-arm64.o -output ../lib/darwin/libpico_ecs.a
	rm *.o
