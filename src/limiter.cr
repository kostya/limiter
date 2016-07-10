class Limiter
  def initialize
  end

  struct Result(T)
    getter value : T

    def initialize(@value)
    end
  end

  struct Error
    getter limited_by : Time::Span

    def initialize(@limited_by)
    end
  end

  def add_limit(seconds : Time::Span, count); end

  protected def increment_request; end
  protected def limited? : Tuple(Bool, Time::Span?)
    {false, nil}
  end

  def clear
  end

  def request(force = false, &block : -> T)
    limited, by = limited?

    if limited && !force
      Error.new(by.not_nil!)
    else
      do_request { yield }
    end
  end

  private def do_request(&block : -> T)
    increment_request
    res = yield
    after_request
    Result(T).new(res)
  end

  protected def after_request
    # callback
  end
end

require "./limiter/memory"
