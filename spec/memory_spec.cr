require "./spec_helper"

describe Limiter::Memory do
  it "no limits" do
    l = Limiter::Memory.new
    10000.times do |i|
      l.request? { i }.should eq i
    end
  end

  it "1 limit" do
    l = Limiter::Memory.new
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
    l = Limiter::Memory.new
    l.add_limit(1.seconds, 10)

    1000.times do |i|
      l.request?(force: true) { i }.should eq i
    end
    l.request? { 111 }.should eq nil
  end

  it "work with small interval" do
    l = Limiter::Memory.new
    l.add_limit(0.1.seconds, 10)

    10.times do |i|
      l.request? { i }.should eq i
    end
    l.request? { 111 }.should eq nil

    sleep 0.15

    10.times do |i|
      l.request? { i }.should eq i
    end
    l.request? { 111 }.should eq nil
  end

  it "complex case" do
    l = Limiter::Memory.new
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

  it "clear" do
    l = Limiter::Memory.new
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
    l = Limiter::Memory.new
    l.add_limit(1.seconds, 10)

    9.times do |i|
      l.request? { i }.should eq i
    end

    l.stats.should eq({1.seconds => {9, 10}})
  end
end
