require "redis"
require "../limiter"

class Limiter::Redis < Limiter
  struct Entry
    getter interval, max_count

    def initialize(@interval : Time::Span, @milliseconds : UInt64, @max_count : UInt64, @redis : ::Redis, @key : String)
      @key_ttl = "#{key}-ttl"
    end

    def increment
      @redis.incr(@key)
    end

    def limited?
      return false if expire_key!

      if val = @redis.get(@key)
        val.to_u64 >= @max_count
      else
        false
      end
    end

    def expire_key!
      return false if (val = @redis.get(@key_ttl)) && (Time.now.epoch_ms - val.to_u64) < @milliseconds
      init_key
      true
    end

    def current_count
      return 0_u64 if expire_key!
      if val = @redis.get(@key)
        val.to_u64
      else
        0_u64
      end
    end

    def clear
      init_key
    end

    private def init_key
      @redis.multi do |multi|
        multi.set(@key_ttl, Time.now.epoch_ms)
        multi.pexpire(@key_ttl, @milliseconds)
        multi.set(@key, "0")
        multi.pexpire(@key, @milliseconds)
      end
    end
  end

  getter entries

  def initialize(@redis : ::Redis, @name = "default")
    super()
    @entries = [] of Entry
  end

  def add_limit(interval : Time::Span, count)
    milliseconds = interval.total_milliseconds.to_u64
    entry = Entry.new(interval, milliseconds, count.to_u64, @redis, "limiter-#{@name}-#{milliseconds}")
    @entries << entry
  end

  def increment_request
    @entries.each &.increment
  end

  def limited? : Tuple(Bool, Time::Span?)
    @entries.each do |entry|
      return {true, entry.interval} if entry.limited?
    end
    {false, nil}
  end

  def clear
    @entries.each &.clear
  end

  def stats
    h = {} of Time::Span => {UInt64, UInt64}
    @entries.each do |e|
      h[e.interval] = {e.current_count, e.max_count}
    end
    h
  end
end
