require "./spec_helper"

describe Limiter::Redis do
  it "no limits" do
    l = Limiter::Redis(Redisoid).new($redis)
    10000.times do |i|
      l.request? { i }.should eq i
    end
  end

  it "1 limit" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(1.seconds, 10)

    9.times do |i|
      l.request? { i }.should eq i
    end
    sleep 0.9
    l.request? { 110 }.should eq 110
    l.request? { 111 }.should eq nil

    sleep 0.2

    10.times do |i|
      l.request? { i }.should eq i
    end
    l.request? { 111 }.should eq nil
  end

  it "allowed by force" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(1.seconds, 10)

    1000.times do |i|
      l.request?(force: true) { i }.should eq i
    end
    l.request? { 111 }.should eq nil
  end

  it "work with small interval" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(0.01.seconds, 10)

    10.times do |i|
      l.request? { i }.should eq i
    end
    l.request? { 111 }.should eq nil

    sleep 0.02

    10.times do |i|
      l.request? { i }.should eq i
    end
    l.request? { 111 }.should eq nil
  end

  it "complex case" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(1.seconds, 10)
    l.add_limit(2.seconds, 15)
    l.add_limit(3.seconds, 20)

    10.times do |i|
      l.request! { i }.should eq i
    end

    should_raise_with(1.seconds) { l.request! { 111 } }
    sleep 1.1

    5.times do |i|
      l.request! { i }.should eq i
    end
    should_raise_with(2.seconds) { l.request! { 111 } }

    sleep 1.1

    5.times do |i|
      l.request! { i }.should eq i
    end
    should_raise_with(3.seconds) { l.request! { 111 } }
  end

  it "complex case2" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(1.seconds, 10)
    l.add_limit(2.seconds, 5)

    5.times { |i| l.request! { i }.should eq i }
    should_raise_with(2.seconds) { l.request! { 111 } }

    sleep 1.1
    l.request? { 1 }.should eq nil
  end

  it "clear" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(1.seconds, 10)

    9.times do |i|
      l.request? { i }.should eq i
    end
    sleep 0.1
    l.request? { 110 }.should eq 110
    l.request? { 111 }.should eq nil

    l.clear

    10.times do |i|
      l.request? { i }.should eq i
    end
    l.request? { 111 }.should eq nil
  end

  it "stats" do
    l = Limiter::Redis(Redisoid).new($redis)
    l.add_limit(1.seconds, 10)

    9.times do |i|
      l.request? { i }.should eq i
    end

    l.stats.should eq({1.seconds => {9, 10}})
  end

  describe "next_usage_after" do
    it "simple" do
      l = Limiter::Redis(Redisoid).new($redis).add_limit(1.seconds, 1)
      l.request? { 1 }.should eq 1
      l.request? { 1 }.should eq nil
      l.next_usage_after.to_f.should be_close(1.0, 0.01)
    end

    it "2 limits max of two" do
      l = Limiter::Redis(Redisoid).new($redis).add_limit(1.seconds, 1).add_limit(2.seconds, 1)
      l.request? { 1 }.should eq 1
      l.request? { 1 }.should eq nil
      l.next_usage_after.to_f.should be_close(2.0, 0.01)
    end

    it "2 limits min of two" do
      l = Limiter::Redis(Redisoid).new($redis).add_limit(1.seconds, 10).add_limit(1.hour, 1000)
      10.times { l.request? { 1 }.should eq 1 }
      sleep 0.7
      l.next_usage_after.to_f.should be_close(0.3, 0.01)
    end

    it "no requests" do
      l = Limiter::Redis(Redisoid).new($redis).add_limit(1.seconds, 1).add_limit(2.seconds, 1).add_limit(3.seconds, 2)
      l.next_usage_after.to_f.should be_close(0.0, 0.01)
    end

    it "less than limit" do
      l = Limiter::Redis(Redisoid).new($redis).add_limit(1.seconds, 10).add_limit(2.seconds, 10).add_limit(3.seconds, 20)
      l.request? { 1 }.should eq 1
      l.next_usage_after.to_f.should be_close(0.0, 0.01)
    end

    it "complex" do
      l = Limiter::Redis(Redisoid).new($redis).add_limit(1.seconds, 10).add_limit(2.seconds, 20)
      10.times { l.request? { 1 }.should eq 1 }
      sleep 1.5
      10.times { l.request? { 1 }.should eq 1 }
      l.next_usage_after.to_f.should be_close(1.0, 0.01) # TODO: here should be 0.5?
    end
  end
end
