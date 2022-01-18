require "../../spec_helper"
require "../../../src/school/rule/pattern"

Spectator.describe School::NullaryPattern do
  describe ".new" do
    it "instantiates a new pattern" do
      expect(described_class.new(MockFact)).to be_a(School::Pattern)
    end
  end

  describe "#fact_class" do
    it "returns the fact class" do
      expect(described_class.new(MockFact).fact_class).to eq(MockFact)
    end
  end

  describe "#vars" do
    it "returns the vars" do
      expect(described_class.new(MockFact).vars).to be_empty
    end
  end

  describe "#match" do
    it "returns empty bindings if the fact matches" do
      fact = MockFact.new
      expect(described_class.new(MockFact).match(fact)).to be_empty
    end

    it "returns nil if the fact does not match" do
      fact = MockProperty.new(123)
      expect(described_class.new(MockFact).match(fact)).to be_nil
    end
  end
end

Spectator.describe School::UnaryPattern do
  describe ".new" do
    it "instantiates a new pattern" do
      expect(described_class.new(MockProperty, 123)).to be_a(School::Pattern)
    end

    it "accepts a var as the argument" do
      expect(described_class.new(MockProperty, School::Var.new("c"))).to be_a(School::Pattern)
    end
  end

  describe "#fact_class" do
    it "returns the fact class" do
      expect(described_class.new(MockProperty, 123).fact_class).to eq(MockProperty)
    end
  end

  describe "#vars" do
    subject { described_class.new(MockProperty, School::Var.new("c")) }

    it "returns the vars" do
      expect(subject.vars).to contain_exactly("c")
    end
  end

  describe "#match" do
    it "returns empty bindings if the fact matches" do
      fact = MockProperty.new(123)
      expect(described_class.new(MockProperty, 123).match(fact)).to be_empty
    end

    it "returns the bindings if the fact matches" do
      fact = MockProperty.new(123)
      expect(described_class.new(MockProperty, School::Var.new("c")).match(fact)).to eq(School::Bindings{"c" => 123})
    end

    it "returns nil if the fact does not match" do
      fact = MockProperty.new(890)
      expect(described_class.new(MockProperty, 123).match(fact)).to be_nil
    end

    it "returns nil if the fact does not match" do
      fact = MockFact.new
      expect(described_class.new(MockProperty, 123).match(fact)).to be_nil
    end
  end
end

Spectator.describe School::BinaryPattern do
  describe ".new" do
    it "instantiates a new pattern" do
      expect(described_class.new(MockRelationship, "abc", "xyz")).to be_a(School::Pattern)
    end

    it "accepts a var as the first argument" do
      expect(described_class.new(MockRelationship, School::Var.new("m"), "xyz")).to be_a(School::Pattern)
    end

    it "accepts a var as the second argument" do
      expect(described_class.new(MockRelationship, "abc", School::Var.new("n"))).to be_a(School::Pattern)
    end
  end

  describe "#fact_class" do
    it "returns the fact class" do
      expect(described_class.new(MockRelationship, "abc", "xyz").fact_class).to eq(MockRelationship)
    end
  end

  describe "#vars" do
    subject { described_class.new(MockRelationship, School::Var.new("m"), School::Var.new("n")) }

    it "returns the vars" do
      expect(subject.vars).to contain_exactly("m", "n")
    end
  end

  describe "#match" do
    it "returns empty bindings if the fact matches" do
      fact = MockRelationship.new("abc", "xyz")
      expect(described_class.new(MockRelationship, "abc", "xyz").match(fact)).to be_empty
    end

    it "returns the bindings if the fact matches" do
      fact = MockRelationship.new("abc", "xyz")
      expect(described_class.new(MockRelationship, School::Var.new("a"), "xyz").match(fact)).to eq(School::Bindings{"a" => "abc"})
    end

    it "returns the bindings if the fact matches" do
      fact = MockRelationship.new("abc", "xyz")
      expect(described_class.new(MockRelationship, "abc", School::Var.new("b")).match(fact)).to eq(School::Bindings{"b" => "xyz"})
    end

    it "returns the bindings if the facts match" do
      fact = MockRelationship.new("abc", "xyz")
      expect(described_class.new(MockRelationship, School::Var.new("a"), School::Var.new("b")).match(fact)).to eq(School::Bindings{"a" => "abc", "b" => "xyz"})
    end

    it "returns nil if the fact does not match" do
      fact = MockRelationship.new("abc", "123")
      expect(described_class.new(MockRelationship, "abc", "xyz").match(fact)).to be_nil
    end

    it "returns nil if the fact does not match" do
      fact = MockRelationship.new("123", "xyz")
      expect(described_class.new(MockRelationship, "abc", "xyz").match(fact)).to be_nil
    end

    it "returns nil if the fact does not match" do
      fact = MockFact.new
      expect(described_class.new(MockRelationship, "abc", "xyz").match(fact)).to be_nil
    end
  end
end
