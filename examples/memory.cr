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
p limiter.stats
