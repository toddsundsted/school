require "../spec_helper"
require "../../src/school/domain"

Spectator.describe School::Domain::Builder do
  describe ".new" do
    it "builds a domain" do
      expect(described_class.new.build).to be_a(School::Domain)
    end
  end

  let(subject) { described_class.new }

  describe "#fact" do
    # fact

    it "adds a fact to the domain" do
      expect{subject.fact(MockFact)}.to change{subject.build.facts.size}
    end

    it "adds a fact to the domain" do
      expect(subject.fact(MockFact).build.facts.first).to be_a(School::Fact)
    end

    # property, first argument

    it "adds a fact to the domain" do
      expect{subject.fact(MockProperty, 0)}.to change{subject.build.facts.size}
    end

    it "adds a property to the domain" do
      expect(subject.fact(MockProperty, 0).build.facts.first).to be_a(School::Property(Int32))
    end

    # property, second argument

    it "adds a fact to the domain" do
      expect{subject.fact(0, MockProperty)}.to change{subject.build.facts.size}
    end

    it "adds a property to the domain" do
      expect(subject.fact(0, MockProperty).build.facts.first).to be_a(School::Property(Int32))
    end

    # relationship, first argument

    it "adds a fact to the domain" do
      expect{subject.fact(MockRelationship, "a", "b")}.to change{subject.build.facts.size}
    end

    it "adds a relationship to the domain" do
      expect(subject.fact(MockRelationship, "a", "b").build.facts.first).to be_a(School::Relationship(String, String))
    end

    # relationship, second argument

    it "adds a fact to the domain" do
      expect{subject.fact("a", MockRelationship, "b")}.to change{subject.build.facts.size}
    end

    it "adds a relationship to the domain" do
      expect(subject.fact("a", MockRelationship, "b").build.facts.first).to be_a(School::Relationship(String, String))
    end

    # relationship, third argument

    it "adds a fact to the domain" do
      expect{subject.fact("a", "b", MockRelationship)}.to change{subject.build.facts.size}
    end

    it "adds a relationship to the domain" do
      expect(subject.fact("a", "b", MockRelationship).build.facts.first).to be_a(School::Relationship(String, String))
    end
  end

  describe "#rule" do
    # given a block

    it "adds a rule to the domain" do
      expect{subject.rule "rule" {}}.to change{subject.build.rules.size}
    end

    it "adds a rule to the domain" do
      expect(subject.rule "rule" {}.build.rules.first).to be_a(School::Rule)
    end

    # given a rule

    it "adds a rule to the domain" do
      expect{subject.rule(MockRule.new(""))}.to change{subject.build.rules.size}
    end

    it "adds a rule to the domain" do
      expect(subject.rule(MockRule.new("")).build.rules.first).to be_a(School::Rule)
    end
  end
end

Spectator.describe School::Domain do
  describe ".new" do
    it "instantiates a new domain" do
      expect(described_class.new).to be_a(School::Domain)
    end
  end

  subject { described_class.new }

  let(fact) { MockFact.new }

  describe "#facts" do
    it "returns the facts in the domain" do
      expect(subject.facts).to be_a(Enumerable(School::Fact))
    end

    it "is empty" do
      expect(subject.facts).to be_empty
    end
  end

  describe "#assert" do
    it "adds a fact to the domain" do
      expect{subject.assert(fact)}.to change{subject.facts}
      expect(subject.facts).to have(fact)
    end

    context "if a fact is already asserted" do
      before_each { subject.assert(fact) }

      it "does not add the fact to the domain" do
        expect{subject.assert(fact)}.not_to change{subject.facts}
      end
    end
  end

  describe "#retract" do
    before_each { subject.assert(fact) }

    it "removes a fact from the domain" do
      expect{subject.retract(fact)}.to change{subject.facts}
      expect(subject.facts).not_to have(fact)
    end

    context "if a fact is already retracted" do
      before_each { subject.retract(fact) }

      it "raises an error" do
        expect{subject.retract(fact)}.to raise_error(ArgumentError)
      end
    end
  end

  let(rule) { MockRule.new("") }

  describe "#rules" do
    it "returns the rules in the domain" do
      expect(subject.rules).to be_a(Enumerable(School::Rule))
    end

    it "is empty" do
      expect(subject.rules).to be_empty
    end
  end

  describe "#add" do
    it "adds a rule to the domain" do
      expect{subject.add(rule)}.to change{subject.rules}
      expect(subject.rules).to have(rule)
    end

    context "if a rule is already added" do
      before_each { subject.add(rule) }

      it "does not add the rule to the domain" do
        expect{subject.add(rule)}.not_to change{subject.rules}
      end
    end
  end

  describe "#remove" do
    before_each { subject.add(rule) }

    it "removes a rule from the domain" do
      expect{subject.remove(rule)}.to change{subject.rules}
      expect(subject.rules).not_to have(rule)
    end

    context "if a rule is already removed" do
      before_each { subject.remove(rule) }

      it "raises an error" do
        expect{subject.remove(rule)}.to raise_error(ArgumentError)
      end
    end
  end

  describe "#run" do
    let(output) { [] of DomainTypes }

    let(action) do
      School::Action.new do |rule, bindings|
        terms = ["#{rule.name}:"]
        terms += bindings.map { |k, v| "#{k}=#{v}" }
        output << terms.join(" ")
      end
    end

    it "does not invoke the action" do
      expect{subject.run}.not_to change{output.dup}
    end

    context "given a simple rule" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockRelationship, "foo", "bar"
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockRelationship.new("foo", "bar"))
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule:"
          ])
        end
      end

      context "and a non-matching fact" do
        before_each do
          subject.assert(MockRelationship.new("bar", "foo"))
        end

        it "does not invoke the action" do
          expect{subject.run}.not_to change{output.dup}
        end
      end
    end

    context "given a simple rule with one var" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockRelationship, "foo", var("value")
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockRelationship.new("foo", "123"))
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value=123"
          ])
        end
      end

      context "and a non-matching fact" do
        before_each do
          subject.assert(MockRelationship.new("bar", "123"))
        end

        it "does not invoke the action" do
          expect{subject.run}.not_to change{output.dup}
        end
      end

      context "and multiple matching facts" do
        before_each do
          subject.assert(MockRelationship.new("foo", "123"))
          subject.assert(MockRelationship.new("foo", "abc"))
        end

        it "invokes the action for each match" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value=123",
            "rule: value=abc"
          ])
        end
      end

      context "and multiple non-matching facts" do
        before_each do
          subject.assert(MockRelationship.new("bar", "123"))
          subject.assert(MockRelationship.new("bar", "abc"))
        end

        it "does not invoke the action" do
          expect{subject.run}.not_to change{output.dup}
        end
      end
    end

    context "given a simple rule with two constrained vars" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockRelationship, var("value"), var("value")
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockRelationship.new("foo", "foo"))
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value=foo"
          ])
        end
      end

      context "and a non-matching fact" do
        before_each do
          subject.assert(MockRelationship.new("bar", "123"))
        end

        it "does not invoke the action" do
          expect{subject.run}.not_to change{output.dup}
        end
      end
    end

    context "given a simple rule with two vars" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockRelationship, var("value1"), var("value2")
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockRelationship.new("foo", "bar"))
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value1=foo value2=bar"
          ])
        end
      end

      context "and a non-matching fact" do
        before_each do
          subject.assert(MockFact.new)
        end

        it "does not invoke the action" do
          expect{subject.run}.not_to change{output.dup}
        end
      end
    end

    context "given a complex rule with two vars" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockRelationship, var("value1"), "bar"
            condition MockRelationship, "foo", var("value2")
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockRelationship.new("foo", "bar"))
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value1=foo value2=bar"
          ])
        end
      end

      context "and a non-matching fact" do
        before_each do
          subject.assert(MockRelationship.new("bar", "foo"))
        end

        it "does not invoke the action" do
          expect{subject.run}.not_to change{output.dup}
        end
      end
    end

    context "beware of under-constrained conditions" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockProperty, var("value1")
            condition MockProperty, var("value2")
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockProperty.new(123))
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value1=123 value2=123"
          ])
        end
      end

      context "and multiple matching facts" do
        before_each do
          subject.assert(MockProperty.new(123))
          subject.assert(MockProperty.new(890))
        end

        it "invokes the action for each match" do
          expect{subject.run}.to change{output.dup}.to([
            "rule: value1=123 value2=123",
            "rule: value1=123 value2=890",
            "rule: value1=890 value2=123",
            "rule: value1=890 value2=890"
          ])
        end
      end
    end

    context "beware of under-constrained conditions" do
      before_each do
        subject.add(
          School.rule "rule" do
            condition MockFact
            condition MockFact
            action action
          end
        )
      end

      it "does not invoke the action" do
        expect{subject.run}.not_to change{output.dup}
      end

      context "and a matching fact" do
        before_each do
          subject.assert(MockFact.new)
        end

        it "invokes the action" do
          expect{subject.run}.to change{output.dup}.to([
            "rule:"
          ])
        end
      end

      context "and multiple matching facts" do
        before_each do
          subject.assert(MockFact.new)
          subject.assert(MockFact.new)
        end

        it "invokes the action for each match" do
          expect{subject.run}.to change{output.dup}.to([
            "rule:",
            "rule:",
            "rule:",
            "rule:"
          ])
        end
      end
    end
  end
end

Spectator.describe School do
  describe ".domain" do
    it "builds a new domain" do
      expect(described_class.domain { fact MockFact }).to be_a(School::Domain)
    end
  end
end
