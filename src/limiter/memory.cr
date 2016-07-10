class Limiter::Memory < Limiter
  class Entry
    getter interval

    def initialize(@interval : Time::Span, @max_count : UInt64)
      @current_count = 0
    end

    def increment
      @current_count += 1
    end

    def clear
      @current_count = 0
    end

    def limited?
      @current_count >= @max_count
    end
  end

  getter entries

  def initialize
    super
    @entries = [] of Entry
    @stopped = false
  end

  def finalize
    stop
  end

  def stop
    @stopped = true
  end

  def add_limit(interval : Time::Span, count)
    entry = Entry.new(interval, count.to_u64)
    @entries << entry
    run_entry(entry)
    switch_coroutines
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

  private def run_entry(entry)
    spawn do
      loop do
        entry.clear
        sleep(entry.interval)
        break if @stopped
      end
    end
  end

  protected def after_request
    switch_coroutines
  end

  private def switch_coroutines
    sleep 0
  end
end
