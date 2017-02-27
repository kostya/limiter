require "./spec_helper"

describe Limiter::Concurrency::Memory do
  it "works" do
    l = Limiter::Concurrency::Memory.new(10)

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
