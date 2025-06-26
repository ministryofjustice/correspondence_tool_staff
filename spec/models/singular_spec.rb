require "rails_helper"

describe "singular" do
  describe "singular" do
    it "returns the singular item in the enumerable" do
      obj = [:a]
      expect(obj.singular).to eq :a
    end

    it "raises if the enumerable has zero items" do
      obj = []
      expect {
        obj.singular
      }.to raise_error Enumerable::NotSingular, "length 0 is not 1"
    end

    it "raises if the enumerable has more than one item" do
      obj = %i[a b]
      expect {
        obj.singular
      }.to raise_error Enumerable::NotSingular, "length 2 is not 1"
    end
  end
end
