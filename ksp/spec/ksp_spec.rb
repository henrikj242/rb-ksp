require 'spec_helper'

RSpec.describe Ksp do
  it "has a version number" do
    expect(Ksp::VERSION).not_to be nil
  end

  it "generates an integer variable" do
    # "some text".should == "some text"
    expect(Ksp::Integer.declare("$my_int", 42)).to eq("declare $my_int := 42")
  end
end
