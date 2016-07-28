require "redis"
require "../limiter"

class Limiter::Redis < Limiter
  struct Entry
    getter interval, max_count

    def initialize(@interval : Time::Span, @milliseconds : UInt64, @max_count : UInt64, @redis : ::Redis, @key : String)
    end

    def increment
      @redis.incr(@key)
    end

    def limited?
      if val = @redis.get(@key)
        val.to_u64 >= @max_count
      else
        init_key
        false
      end
    end

    def current_count
      if val = @redis.get(@key)
        val.to_u64
      else
        0_u64
      end
    end

    def clear
      init_key
    end

    def next_free_after : Time::Span
      if (val = @redis.pttl(@key))
        val.to_u64.milliseconds
      else
        0.seconds
      end
    end

    private def init_key
      @redis.multi do |multi|
        multi.set(@key, "0")
        multi.pexpireat(@key, Time.now.epoch_ms + @milliseconds)
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
    self
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

  def next_usage_after
    limited = @entries.select &.limited?
    return 0.seconds if limited.empty?

    res = limited.map { |e| e.next_free_after }.max
    res.to_f < 0 ? 0.seconds : res
  end
end
