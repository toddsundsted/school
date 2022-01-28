require "./rule"

module School
  class Rule
    # Rule builder.
    #
    # Used internally to build rules with a DSL.
    #
    class Builder
      @conditions = [] of Pattern
      @actions = [] of Action

      def initialize(@name : String)
      end

      def condition(f : Fact.class)
        @conditions << NullaryPattern.new(f)
        self
      end

      def condition(f : Fact.class, m)
        @conditions << UnaryPattern.new(f, m)
        self
      end

      def condition(m, f : Fact.class)
        @conditions << UnaryPattern.new(f, m)
        self
      end

      def condition(f : Fact.class, m1, m2)
        @conditions << BinaryPattern.new(f, m1, m2)
        self
      end

      def condition(m1, f : Fact.class, m2)
        @conditions << BinaryPattern.new(f, m1, m2)
        self
      end

      def condition(m1, m2, f : Fact.class)
        @conditions << BinaryPattern.new(f, m1, m2)
        self
      end

      def any(f : Fact.class)
        @conditions << Pattern::Any.new(NullaryPattern.new(f))
        self
      end

      def any(f : Fact.class, m)
        @conditions << Pattern::Any.new(UnaryPattern.new(f, m))
        self
      end

      def any(m, f : Fact.class)
        @conditions << Pattern::Any.new(UnaryPattern.new(f, m))
        self
      end

      def any(f : Fact.class, m1, m2)
        @conditions << Pattern::Any.new(BinaryPattern.new(f, m1, m2))
        self
      end

      def any(m1, f : Fact.class, m2)
        @conditions << Pattern::Any.new(BinaryPattern.new(f, m1, m2))
        self
      end

      def any(m1, m2, f : Fact.class)
        @conditions << Pattern::Any.new(BinaryPattern.new(f, m1, m2))
        self
      end

      def none(f : Fact.class)
        @conditions << Pattern::None.new(NullaryPattern.new(f))
        self
      end

      def none(f : Fact.class, m)
        @conditions << Pattern::None.new(UnaryPattern.new(f, m))
        self
      end

      def none(m, f : Fact.class)
        @conditions << Pattern::None.new(UnaryPattern.new(f, m))
        self
      end

      def none(f : Fact.class, m1, m2)
        @conditions << Pattern::None.new(BinaryPattern.new(f, m1, m2))
        self
      end

      def none(m1, f : Fact.class, m2)
        @conditions << Pattern::None.new(BinaryPattern.new(f, m1, m2))
        self
      end

      def none(m1, m2, f : Fact.class)
        @conditions << Pattern::None.new(BinaryPattern.new(f, m1, m2))
        self
      end

      def action(&action : Action)
        @actions << action
        self
      end

      def action(action : Action)
        @actions << action
        self
      end

      @vars = Hash(String, Var).new { |h, k| h[k] = Var.new(k) }

      # Returns a new variable.
      #
      def var(name : String)
        @vars[name]
      end

      # Returns a not expression.
      #
      def not(any)
        Not.new(any)
      end

      def within(*any)
        Within.new(*any)
      end

      # Builds the rule.
      #
      # Every invocation returns the same rule (it is built once and
      # memoized).
      #
      def build
        @rule ||= Rule.new(@name, @conditions, @actions)
      end
    end
  end

  # Presents a DSL for defining rules.
  #
  def self.rule(name, &block)
    builder = Rule::Builder.new(name)
    with builder yield
    builder.build
  end
end
