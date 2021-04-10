require "./spec_helper"

describe Limiter::Concurrency::Redis do
  it "works" do
    l = Limiter::Redis(Redis::PooledClient).new(Global.redis, "default")
    l.add_limit(2.seconds, 10)

    ch = Channel(Int32).new

    res = 0
    10.times do |i|
      spawn do
        if x = l.request? { sleep 0.5; i }
          ch.send x
        end
      end
    end

    sleep 0.1
    10.times { l.request? { 1 }.should eq nil }

    10.times { res += ch.receive }
    res.should eq 45
  end
end
