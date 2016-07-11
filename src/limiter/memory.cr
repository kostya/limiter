class Limiter::Memory < Limiter
  class Entry
    getter interval, max_count

    def initialize(@interval : Time::Span, @max_count : UInt64)
      @current_count = 0_u64
      @stopped = false
      @clear_at = Time.now
    end

    def increment
      @current_count += 1
    end

    def clear
      @current_count = 0_u64
      @clear_at = Time.now
    end

    def current_count
      @current_count
    end

    def limited?
      @current_count >= @max_count
    end

    def stop!
      @stopped = true
    end

    def next_free_at
      @clear_at + interval
    end

    def async_run
      spawn do
        loop do
          clear
          sleep(interval)
          break if @stopped
        end
      end
    end
  end

  getter entries

  def initialize
    super
    @entries = [] of Entry
  end

  def finalize
    stop
  end

  def stop
    @entries.each &.stop!
  end

  def add_limit(interval : Time::Span, count)
    entry = Entry.new(interval, count.to_u64)
    @entries << entry
    entry.async_run
    switch_coroutines
    self
  end

  def clear
    @entries.each &.clear
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

  def stats
    h = {} of Time::Span => {UInt64, UInt64}
    @entries.each do |e|
      h[e.interval] = {e.current_count, e.max_count}
    end
    h
  end

  def next_usage_at
    limited = @entries.select &.limited?
    return Time.now if limited.empty?

    limited.map { |e| e.next_free_at }.max
  end

  protected def after_request
    switch_coroutines
  end

  private def switch_coroutines
    sleep 0
  end
end
