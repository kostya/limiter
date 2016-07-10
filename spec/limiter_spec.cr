require "./spec_helper"

describe Limiter do
  it "correct types for values" do
    l1 = Limiter::Memory.new
    l2 = Limiter::Memory.new
    resp1 = l1.request { 1 }
    resp2 = l2.request { "bla" }

    case resp1
    when Limiter::Result
      (resp1.value + 1).should eq 2
    else
      raise "unexpected result #{resp1}"
    end

    case resp2
    when Limiter::Result
      (resp2.value + "1").should eq "bla1"
    else
      raise "unexpected result #{resp2}"
    end
  end
end
