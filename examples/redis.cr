require "redis" # https://github.com/stefanwille/crystal-redis
require "../src/limiter/redis"

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
  if val = limiter.request? { some_high_cost_action }
    res << val
  else
    limited_count += 1
  end
end

p res.size
p limited_count
p limiter.stats
