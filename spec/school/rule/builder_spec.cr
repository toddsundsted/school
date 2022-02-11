require "../../spec_helper"
require "../../../src/school/rule/builder"

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

    # given a block

    it "adds a condition to the rule" do
      expect{subject.condition {}}.to change{subject.build.conditions.size}
    end

    it "adds a proc pattern to the rule" do
      expect(subject.condition {}.build.conditions.first).to be_a(School::ProcPattern)
    end

    # given a proc

    it "adds a condition to the rule" do
      expect{subject.condition(School::ProcPattern::ProcType.new {})}.to change{subject.build.conditions.size}
    end

    it "adds a proc pattern to the rule" do
      expect(subject.condition(School::ProcPattern::ProcType.new {}).build.conditions.first).to be_a(School::ProcPattern)
    end
  end

  describe "#any" do
    # nullary condition

    it "adds a condition to the rule" do
      expect{subject.any(MockFact)}.to change{subject.build.conditions.size}
    end

    # unary condition, first argument

    it "adds a condition to the rule" do
      expect{subject.any(MockProperty, 0)}.to change{subject.build.conditions.size}
    end

    # unary condition, second argument

    it "adds a condition to the rule" do
      expect{subject.any(0, MockProperty)}.to change{subject.build.conditions.size}
    end

    # binary condition, first argument

    it "adds a condition to the rule" do
      expect{subject.any(MockRelationship, "a", "b")}.to change{subject.build.conditions.size}
    end

    # binary condition, second argument

    it "adds a condition to the rule" do
      expect{subject.any("a", MockRelationship, "b")}.to change{subject.build.conditions.size}
    end

    # binary condition, third argument

    it "adds a condition to the rule" do
      expect{subject.any("a", "b", MockRelationship)}.to change{subject.build.conditions.size}
    end
  end

  describe "#none" do
    # nullary condition

    it "adds a condition to the rule" do
      expect{subject.none(MockFact)}.to change{subject.build.conditions.size}
    end

    # unary condition, first argument

    it "adds a condition to the rule" do
      expect{subject.none(MockProperty, 0)}.to change{subject.build.conditions.size}
    end

    # unary condition, second argument

    it "adds a condition to the rule" do
      expect{subject.none(0, MockProperty)}.to change{subject.build.conditions.size}
    end

    # binary condition, first argument

    it "adds a condition to the rule" do
      expect{subject.none(MockRelationship, "a", "b")}.to change{subject.build.conditions.size}
    end

    # binary condition, second argument

    it "adds a condition to the rule" do
      expect{subject.none("a", MockRelationship, "b")}.to change{subject.build.conditions.size}
    end

    # binary condition, third argument

    it "adds a condition to the rule" do
      expect{subject.none("a", "b", MockRelationship)}.to change{subject.build.conditions.size}
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

    # given a proc

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

  describe "#not" do
    it "allocates a new expression" do
      expect(subject.not("target")).to be_a(School::Not)
    end
  end

  describe "#within" do
    it "allocates a new expression" do
      expect(subject.within("target")).to be_a(School::Within)
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
