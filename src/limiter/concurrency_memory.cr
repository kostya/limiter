class Limiter::Concurrency::Memory < Limiter
  def initialize(@max_count : Int32)
    super()
    @current = 0
  end

  def clear
    @current = 0
  end

  def increment_request
    @current += 1
  end

  def limited? : Tuple(Bool, Time::Span?)
    if @current >= @max_count
      {true, nil}
    else
      {false, nil}
    end
  end

  def stats
    {current: @current, max_count: @max_count}
  end

  protected def after_request
    @current -= 1
  end
end
