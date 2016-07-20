class Limiter
  def initialize
  end

  class Error < Exception
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

  # request with limits, raised if request is not possible
  def request!(force = false, &block)
    limited, by = limited?

    if limited && !force
      raise Error.new(by.not_nil!)
    else
      do_request { yield }
    end
  end

  # request with limits, return nil if request is not possible
  def request?(force = false, &block)
    limited, by = limited?

    if limited && !force
      nil
    else
      do_request { yield }
    end
  end

  private def do_request(&block)
    increment_request
    yield
  ensure
    after_request
  end

  protected def after_request
    # callback
  end
end

require "./limiter/memory"
