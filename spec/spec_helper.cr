require "spec"
require "../src/limiter"
require "../src/limiter/redis"
require "redis"

class Global
  @@redis : Redis::PooledClient?

  def self.redis
    @@redis ||= Redis::PooledClient.new
  end
end

def cleanup
  Global.redis.keys("limiter-*").each do |key|
    Global.redis.del key.to_s
  end
end

Spec.before_each do
  cleanup
end

def should_raise_with(limited_by)
  begin
    yield
    raise "Expected raises, but not"
  rescue ex : Limiter::Error
    ex.limited_by.should eq limited_by
  end
end
