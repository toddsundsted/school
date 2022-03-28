require "../../spec_helper"
require "../../../src/school/rule/expression"

Spectator.describe School::Lit do
  describe "#match" do
    let(lit) { described_class.new("lit") }

    it "returns true if the value matches" do
      expect(lit.match("lit").success).to be_true
    end

    it "returns false if the value does not match" do
      expect(lit.match("mus").success).to be_false
    end

    context "nested in a not" do
      subject { School::Not.new(lit) }

      it "returns false if the value matches" do
        expect(subject.match("lit").success).to be_false
      end
    end

    context "nested in a within" do
      subject { School::Within.new(lit) }

      it "returns true if the value matches" do
        expect(subject.match("lit").success).to be_true
      end
    end

    context "given a name" do
      subject { described_class.new("lit", name: "val") }

      it "returns the bindings" do
        expect(subject.match("lit").bindings).to eq(School::Bindings{"val" => "lit"})
      end
    end
  end
end

Spectator.describe School::Var do
  describe ".new" do
    it "raises an error if the name is not valid" do
      expect{described_class.new("")}.to raise_error(ArgumentError)
    end
  end

  describe "#match" do
    let(var) { described_class.new("var") }

    it "returns the bindings" do
      expect(var.match("value").bindings).to eq(School::Bindings{"var" => "value"})
    end

    context "nested in a not" do
      subject { School::Not.new(var) }

      it "does not return the bindings" do
        expect(subject.match("value").bindings).to be_nil
      end
    end

    context "nested in a within" do
      subject { School::Within.new(var) }

      it "returns the bindings" do
        expect(subject.match("value").bindings).to eq(School::Bindings{"var" => "value"})
      end
    end
  end
end

Spectator.describe School::Not do
  describe "#match" do
    subject { described_class.new("target") }

    it "returns true if the value does not match" do
      expect(subject.match("value").success).to be_true
    end

    it "returns false if the value matches" do
      expect(subject.match("target").success).to be_false
    end

    context "given a nested not" do
      subject { described_class.new(described_class.new("target")) }

      it "returns true if the value matches" do
        expect(subject.match("target").success).to be_true
      end

      it "returns false if the value does not match" do
        expect(subject.match("value").success).to be_false
      end
    end

    context "given a nested lit" do
      subject { described_class.new(School::Lit.new("lit")) }

      it "returns false" do
        expect(subject.match("value").success).to be_true
      end
    end

    context "given a nested var" do
      subject { described_class.new(School::Var.new("var")) }

      it "returns false" do
        expect(subject.match("value").success).to be_false
      end
    end

    context "given a name" do
      subject { described_class.new("target", name: "val") }

      it "returns the bindings" do
        expect(subject.match("value").bindings).to eq(School::Bindings{"val" => "value"})
      end
    end
  end
end

Spectator.describe School::Within do
  describe "#match" do
    subject { described_class.new("foo", "bar") }

    it "returns true if the value is within the set" do
      expect(subject.match("bar").success).to be_true
    end

    it "returns false if the value is not within the set" do
      expect(subject.match("baz").success).to be_false
    end

    context "given a nested lit" do
      subject { described_class.new(School::Lit.new("lit")) }

      it "returns true" do
        expect(subject.match("lit").success).to be_true
      end
    end

    context "given a nested var" do
      subject { described_class.new(School::Var.new("var")) }

      it "returns true" do
        expect(subject.match("baz").success).to be_true
      end
    end

    context "given a name" do
      subject { described_class.new("foo", "bar", name: "val") }

      it "returns the bindings" do
        expect(subject.match("foo").bindings).to eq(School::Bindings{"val" => "foo"})
      end
    end
  end
end
