FROM ubuntu:focal AS build
WORKDIR /root
RUN apt-get update && apt-get install -y \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

COPY Makefile /root/
COPY common.hpp /root/
COPY redis-cli.cpp /root/
COPY redis-server.cpp /root/

RUN make

FROM ubuntu:focal

COPY --from=build /root/redis-cli /usr/local/bin/
COPY --from=build /root/redis-server /usr/local/bin/

CMD ["redis-server"] 