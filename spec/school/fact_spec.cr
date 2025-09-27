require "../spec_helper"
require "../../src/school/fact"

Spectator.describe School::Fact do
  describe ".new" do
    it "instantiates a new fact" do
      expect(MockFact.new).to be_a(School::Fact)
    end

    it "instantiates a new fact" do
      expect(MockProperty.new(123)).to be_a(School::Fact)
    end

    it "instantiates a new fact" do
      expect(MockRelationship.new("xyz", "abc")).to be_a(School::Fact)
    end
  end
end
