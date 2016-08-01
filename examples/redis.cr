require "redisoid" # https://github.com/kostya/redisoid
require "../src/limiter/redis"

redis_client = Redisoid.new

limiter = Limiter::Redis(Redisoid).new(redis_client, "my_limiter1")
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

50.times do
  if val = limiter.request? { some_high_cost_action }
    res << val
  else
    x = limiter.next_usage_after
    puts "processed: #{res.size}, next usage after #{x} seconds"
    sleep(x)
  end
end

puts "processed #{res.size}"
