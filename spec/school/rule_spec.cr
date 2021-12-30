require "../spec_helper"
require "../../src/school/rule"

# Every project must specify the types of objects used in the
# domain. The tests use `String` and `Int32`.
alias DomainTypes = String | Int32

class MockFact < School::Fact
end

class MockProperty < School::Property(Int32)
end

class MockRelationship < School::Relationship(String, String)
end

Spectator.describe School::Var do
  describe ".new" do
    it "raises an error if the name is not valid" do
      expect{described_class.new("")}.to raise_error(ArgumentError)
    end
  end
end

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
end

Spectator.describe School::Rule::Builder do
  describe ".new" do
    it "builds a rule" do
      expect(described_class.new("").build).to be_a(School::Rule)
    end

    it "builds a rule with a name" do
      expect(described_class.new("name").build.name).to eq("name")
    end
  end

  let(subject) { described_class.new("") }

  describe "#condition" do
    # nullary condition

    it "adds a condition to the rule" do
      expect{subject.condition(MockFact)}.to change{subject.build.conditions.size}
    end

    it "adds a nullary condition to the rule" do
      expect(subject.condition(MockFact).build.conditions.first).to be_a(School::NullaryPattern(MockFact))
    end

    # unary condition, first argument

    it "adds a condition to the rule" do
      expect{subject.condition(MockProperty, 0)}.to change{subject.build.conditions.size}
    end

    it "adds a unary condition to the rule" do
      expect(subject.condition(MockProperty, 0).build.conditions.first).to be_a(School::UnaryPattern(MockProperty, Int32))
    end

    # unary condition, second argument

    it "adds a condition to the rule" do
      expect{subject.condition(0, MockProperty)}.to change{subject.build.conditions.size}
    end

    it "adds a unary condition to the rule" do
      expect(subject.condition(0, MockProperty).build.conditions.first).to be_a(School::UnaryPattern(MockProperty, Int32))
    end

    # binary condition, first argument

    it "adds a condition to the rule" do
      expect{subject.condition(MockRelationship, "a", "b")}.to change{subject.build.conditions.size}
    end

    it "adds a binary condition to the rule" do
      expect(subject.condition(MockRelationship, "a", "b").build.conditions.first).to be_a(School::BinaryPattern(MockRelationship, String, String))
    end

    # binary condition, second argument

    it "adds a condition to the rule" do
      expect{subject.condition("a", MockRelationship, "b")}.to change{subject.build.conditions.size}
    end

    it "adds a binary condition to the rule" do
      expect(subject.condition("a", MockRelationship, "b").build.conditions.first).to be_a(School::BinaryPattern(MockRelationship, String, String))
    end

    # binary condition, third argument

    it "adds a condition to the rule" do
      expect{subject.condition("a", "b", MockRelationship)}.to change{subject.build.conditions.size}
    end

    it "adds a binary condition to the rule" do
      expect(subject.condition("a", "b", MockRelationship).build.conditions.first).to be_a(School::BinaryPattern(MockRelationship, String, String))
    end
  end

  describe "#action" do
    # given a block

    it "adds an action to the rule" do
      expect{subject.action {}}.to change{subject.build.actions.size}
    end

    it "adds an action to the rule" do
      expect(subject.action {}.build.actions.first).to be_a(School::Action)
    end

    # given a block with arguments

    it "adds an action to the rule" do
      expect{subject.action { |r, b| }}.to change{subject.build.actions.size}
    end

    it "adds an action to the rule" do
      expect(subject.action { |r, b| }.build.actions.first).to be_a(School::Action)
    end

    # given an action

    it "adds an action to the rule" do
      expect{subject.action(->(r : School::Rule, b : School::Bindings) {})}.to change{subject.build.actions.size}
    end

    it "adds an action to the rule" do
      expect(subject.action(->(r : School::Rule, b : School::Bindings) {}).build.actions.first).to be_a(School::Action)
    end
  end

  describe "#var" do
    it "allocates a new var" do
      expect(subject.var("i")).to be_a(School::Var)
    end
  end
end

Spectator.describe School::Rule do
  describe ".new" do
    it "instantiates a new rule" do
      expect(School::Rule.new("")).to be_a(School::Rule)
    end
  end

  describe "#vars" do
    subject do
      School.rule "" do
        condition var("a"), MockRelationship, var("b")
        condition var("b"), MockRelationship, var("a")
      end
    end

    it "returns the vars" do
      expect(subject.vars).to contain_exactly("a", "b")
    end
  end

  describe "#call" do
    subject do
      School.rule "" do
        condition var("a"), MockRelationship, var("b")
        action { |rule, bindings| output.concat(bindings.keys) }
        action { |rule, bindings| output.concat(bindings.values) }
      end
    end

    let(bindings) { School::Bindings{"a" => "A", "b" => "B"} }

    let(output) { [] of DomainTypes }

    it "invokes the actions" do
      expect{subject.call(bindings)}.to change{output.dup}.to(["a", "b", "A", "B"])
    end
  end
end

Spectator.describe School do
  describe ".rule" do
    it "builds a new rule" do
      expect(described_class.rule "rule" { condition MockFact }).to be_a(School::Rule)
    end
  end
end
