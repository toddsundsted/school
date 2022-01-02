require "./fact"

module School
  # Bindings.
  #
  alias Bindings = Hash(String, DomainTypes)

  # Result.
  #
  # Holds the result of a match as well as any passed bindings.
  #
  private record Result, success : Bool, bindings : Bindings? = nil

  # An expression.
  #
  abstract class Expression
    # Matches the expression to a value.
    #
    abstract def match(value : DomainTypes) : Result
  end

  # A variable.
  #
  class Var < Expression
    NAME = /[a-z][a-z0-9_-]*/i

    getter name

    def initialize(@name : String)
      raise ArgumentError.new("#{@name.inspect} is not a valid name") unless @name =~ NAME
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      Result.new(true, Bindings{@name => value})
    end
  end

  # A pattern.
  #
  abstract class Pattern
    getter fact_class : Fact.class = Fact

    # Returns the variables in the pattern.
    #
    abstract def vars : Enumerable(String)
  end

  # A pattern that matches a fact.
  #
  class NullaryPattern(F) < Pattern
    def initialize(@fact_class : F.class)
      {% unless F < Fact && F.ancestors.all?(&.type_vars.empty?) %}
        {% raise "#{F} is not a nullary Fact" %}
      {% end %}
    end

    # :inherit:
    def vars : Enumerable(String)
      [] of String
      Set(String).new
    end
  end

  # A pattern that matches a fact with one argument.
  #
  class UnaryPattern(F, C) < Pattern
    getter c

    def initialize(@fact_class : F.class, @c : C)
      {% begin %}
        {% ancestor = F.ancestors.find { |a| !a.type_vars.empty? } %}
        {% if F < Fact && ancestor && (types = ancestor.type_vars).size == 1 %}
          {% unless C == types[0] || C < Expression %}
            {% raise "the argument must be #{types[0]} or Expression, not #{C}" %}
          {% end %}
        {% else %}
          {% raise "#{F} is not a unary Fact" %}
        {% end %}
      {% end %}
    end

    # :inherit:
    def vars : Enumerable(String)
      Set(String).new.tap do |vars|
        if (c = @c).is_a?(Var)
          vars << c.name
        end
      end
    end
  end

  # A pattern that matches a fact with two arguments.
  #
  class BinaryPattern(F, A, B) < Pattern
    getter a, b

    def initialize(@fact_class : F.class, @a : A, @b : B)
      {% begin %}
        {% ancestor = F.ancestors.find { |a| !a.type_vars.empty? } %}
        {% if F < Fact && ancestor && (types = ancestor.type_vars).size == 2 %}
          {% unless A == types[0] || A < Expression %}
            {% raise "the first argument must be #{types[0]} or Expression, not #{A}" %}
          {% end %}
          {% unless B == types[1] || B < Expression %}
            {% raise "the second argument must be #{types[1]} or Expression, not #{B}" %}
          {% end %}
        {% else %}
          {% raise "#{F} is not a binary Fact" %}
        {% end %}
      {% end %}
    end

    # :inherit:
    def vars : Enumerable(String)
      Set(String).new.tap do |vars|
        if (a = @a).is_a?(Var)
          vars << a.name
        end
        if (b = @b).is_a?(Var)
          vars << b.name
        end
      end
    end
  end

  # An action.
  #
  alias Action = (Rule, Bindings)->

  # A rule is collection of conditions (patterns) that match against
  # facts, and associated actions.
  #
  class Rule
    def initialize(name : String)
      initialize(name, [] of Pattern, [] of Action)
    end

    protected def initialize(@name : String, @conditions : Array(Pattern), @actions : Array(Action))
    end

    getter name

    def conditions
      @conditions.dup
    end

    def actions
      @actions.dup
    end

    @vars : Enumerable(String)?

    # Returns the variables in the conditions.
    #
    def vars : Enumerable(String)
      @vars ||= @conditions.reduce(Set(String).new) { |vars, pattern| vars.concat(pattern.vars) }
    end

    # Invokes the rule's actions.
    #
    def call(bindings : Bindings)
      @actions.each(&.call(self, bindings.dup))
    end

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
