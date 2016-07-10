require "spec"
require "../src/limiter"
require "../src/limiter/redis"

$redis = Redis.new

def cleanup
  $redis.keys("limiter-*").each do |key|
    $redis.del key
  end
end

Spec.before_each do
  cleanup
end
