require "./spec_helper"

describe Limiter do
  it "correct types for values" do
    l1 = Limiter::Memory.new
    l2 = Limiter::Memory.new
    resp1 = l1.request! { 1 }
    resp2 = l2.request! { "bla" }

    (resp1 + 1).should eq 2
    (resp2 + "1").should eq "bla1"
  end
end
