class Limiter::Concurrency::Redis(T) < Limiter
  def initialize(@redis : T, @name : String, @max_count : Int32)
    super()
    @key = "concurrency-limiter-#{@name}"
    @counter = 0
  end

  def clear
    @redis.del(@key)
    @counter = 0
  end

  def increment_request
    @redis.incr(@key)
    @counter += 1
  end

  def limited? : Tuple(Bool, Time::Span?)
    if value = @redis.get(@key)
      if value > @max_count.to_u64
        {true, nil}
      else
        {false, nil}
      end
    else
      {false, nil}
    end
  end

  def stats
    {current: (@redis.get(@key) || 0).to_u64, max_count: @max_count}
  end

  protected def after_request
    @redis.decr(@key)
    @counter -= 1
  end

  def finalize
    @redis.decr(@key, @counter)
  end
end
