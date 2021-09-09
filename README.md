# cs341-redis

## Student should implement below

### Server
#### Data Type

- String: https://redis.io/topics/data-types

#### Command

- PING: https://redis.io/commands/ping
- GET: https://redis.io/commands/get
- SET: https://redis.io/commands/set
- STRLEN: https://redis.io/commands/strlen
- DEL: https://redis.io/commands/del
- EXISTS: https://redis.io/commands/exists


### Client

- redis-cli, the Redis command line interface`: https://redis.io/topics/rediscli
- `man redis-cli`: https://www.mankier.com/1/redis-cli

#### STDIN/STDOUT

See "Getting input from other programs" section in https://redis.io/topics/rediscli .

You don't need to implement inline command (e.g. `redis-cli redis_command`).

#### Options

- `-h`: hostname
- `--raw`: raw output mode (you don't need to implement `no-raw` mode)


## Source Codes:

See [src/README.md](src/README.md).


## Testing

We use [Docker](https://www.docker.com) for testing. Install Docker before testing.


### Build Docker Container Image

```bash
$ ./scripts/build-container.sh
```

### Test Server

```bash
$ ./scripts/test.sh
```

### Test Real Redis Server

```bash
$ SERVER_IMAGE=redis ./scripts/test.sh
```

### Test Client

```bash
$ SERVER_IMAGE=redis CLIENT_IMAGE=student-redis ./scripts/test.sh
```

### Test Real Redis Client

```bash
$ SERVER_IMAGE=redis CLIENT_IMAGE=redis ./scripts/test.sh
```
