require "./spec_helper"

describe Limiter::Memory do
  it "no limits" do
    l = Limiter::Memory.new
    10000.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
  end

  it "1 limit" do
    l = Limiter::Memory.new
    l.add_limit(1.seconds, 10)

    9.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
    sleep 0.9
    l.request { 110 }.should eq(Limiter::Result(Int32).new(110))
    l.request { 111 }.should eq(Limiter::Error.new(1.seconds))

    sleep 0.2

    10.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
    l.request { 111 }.should eq(Limiter::Error.new(1.seconds))
  end

  it "allowed by force" do
    l = Limiter::Memory.new
    l.add_limit(1.seconds, 10)

    1000.times do |i|
      l.request(force: true) { i }.should eq(Limiter::Result(Int32).new(i))
    end
    l.request { 111 }.should eq(Limiter::Error.new(1.seconds))
  end

  it "work with small interval" do
    l = Limiter::Memory.new
    l.add_limit(0.01.seconds, 10)

    10.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
    l.request { 111 }.should eq(Limiter::Error.new(0.01.seconds))

    sleep 0.05

    10.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
    l.request { 111 }.should eq(Limiter::Error.new(0.01.seconds))
  end

  it "complex case" do
    l = Limiter::Memory.new
    l.add_limit(1.seconds, 10)
    l.add_limit(2.seconds, 15)
    l.add_limit(3.seconds, 20)

    10.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end

    l.request { 111 }.should eq(Limiter::Error.new(1.seconds))
    sleep 1.1

    5.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
    l.request { 111 }.should eq(Limiter::Error.new(2.seconds))

    sleep 1.1

    5.times do |i|
      l.request { i }.should eq(Limiter::Result(Int32).new(i))
    end
    l.request { 111 }.should eq(Limiter::Error.new(3.seconds))
  end
end
