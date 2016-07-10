# limiter

Rate limiter for Crystal. Memory and Redis based. Redis limiter is shared (unlike Memory limiter which is local for process), so it can be used across multiple processes.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  limiter:
    github: kostya/limiter
```


## Usage Memory Limiter


```crystal
require "../src/limiter"

limiter = Limiter::Memory.new
limiter.add_limit(2.seconds, 10) # allow 10 requests per 2.seconds
limiter.add_limit(1.hour, 1000)  # allow 1000 requests per 1.hour

record Result, val : Float64

def some_high_cost_action : Result
  # ...
  sleep 0.1
  # ...
  return Result.new(rand)
end

res = [] of Result
limited_count = 0

1000.times do
  case resp = limiter.request { some_high_cost_action }
  when Limiter::Result
    res << resp.value
  when Limiter::Error
    limited_count += 1
  end
end

p res.size
p limited_count
```

## Usage Redis Limiter

```crystal
require "redis" # https://github.com/stefanwille/crystal-redis
require "limiter/redis"

redis_client = Redis.new

limiter = Limiter::Redis.new(redis_client, "my_limiter1")
limiter.add_limit(2.seconds, 10) # allow 10 requests per 2.seconds
limiter.add_limit(1.hour, 1000)  # allow 1000 requests per 1.hour

record Result, val : Float64

def some_high_cost_action : Result
  # ...
  sleep 0.1
  # ...
  return Result.new(rand)
end

res = [] of Result
limited_count = 0

1000.times do
  case resp = limiter.request { some_high_cost_action }
  when Limiter::Result
    res << resp.value
  when Limiter::Error
    limited_count += 1
  end
end

p res.size
p limited_count
```
