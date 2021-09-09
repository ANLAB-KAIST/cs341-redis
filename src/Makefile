.PHONY: all clean

all: redis-server redis-cli

CPP_FLAGS=-std=c++17 -pthread

redis-server: redis-server.cpp common.hpp
	c++ ${CPP_FLAGS} -o redis-server redis-server.cpp

redis-cli: redis-cli.cpp common.hpp
	c++ ${CPP_FLAGS} -o redis-cli redis-cli.cpp

clean:
	rm -f redis-server redis-cli