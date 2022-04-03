require "./expression"
require "../fact"

module School
  # A pattern.
  #
  # Prefer `Pattern` over `BasePattern` since classes derived from
  # `Pattern` can be used with special patterns `Any` and `None`.
  #
  abstract class BasePattern
    # Returns the variables in the pattern.
    #
    abstract def vars : Enumerable(String)

    # Indicates whether or not any facts match the pattern.
    #
    # Yields once for each match.
    #
    abstract def match(bindings : Bindings, &block : Bindings -> Nil) : Nil

    # A special pattern that indicates a condition that is satisfied
    # if and only if at least one fact matches the wrapped pattern.
    #
    class Any < BasePattern
      def initialize(@pattern : Pattern)
      end

      # :inherit:
      def vars : Enumerable(String)
        @pattern.vars
      end

      # :inherit:
      def match(bindings : Bindings, &block : Bindings -> Nil) : Nil
        yield bindings if @pattern.match(bindings) { break true }
      end
    end

    # A special pattern that indicates a condition that is satisfied
    # if and only if no facts match the wrapped pattern.
    #
    class None < BasePattern
      def initialize(@pattern : Pattern)
      end

      # :inherit:
      def vars : Enumerable(String)
        @pattern.vars
      end

      # :inherit:
      def match(bindings : Bindings, &block : Bindings -> Nil) : Nil
        yield bindings unless @pattern.match(bindings) { break true }
      end
    end
  end

  # A pattern.
  #
  abstract class Pattern < BasePattern
  end

  # Patterns that match against the `Fact` database.
  #
  abstract class FactPattern < Pattern
    # Indicates whether or not the fact matches the pattern.
    #
    abstract def match(fact : Fact, bindings : Bindings) : Bindings?

    # :inherit:
    def match(bindings : Bindings, &block : Bindings -> Nil) : Nil
      Fact.facts.each do |fact|
        if (temporary = match(fact, bindings))
          yield temporary
        end
      end
    end

    # Checks the result for binding conflicts.
    #
    # Returns the merged bindings.
    #
    protected def check_result(result : Result, bindings : Bindings)
      if result.success
        if (temporary = result.bindings)
          if temporary.none? { |k, v| bindings.has_key?(k) && bindings[k] != v }
            bindings.merge(temporary)
          end
        else
          bindings
        end
      end
    end
  end

  # A pattern that matches a fact.
  #
  class NullaryPattern(F) < FactPattern
    def initialize
      initialize(F)
    end

    def initialize(fact_class : F.class)
      {% unless F < Fact && F.ancestors.all?(&.type_vars.empty?) %}
        {% raise "#{F} is not a nullary Fact" %}
      {% end %}
    end

    # :inherit:
    def vars : Enumerable(String)
      Set(String).new
    end

    # :inherit:
    def match(fact : Fact, bindings : Bindings) : Bindings?
      if fact.is_a?(F)
        bindings
      end
    end

    # Asserts the associated `Fact`.
    #
    def self.assert(bindings : Bindings)
      Fact.assert(F.new)
    end
  end

  # A pattern that matches a fact with one argument.
  #
  class UnaryPattern(F, C) < FactPattern
    getter c

    def initialize(c : C)
      initialize(F, c)
    end

    def initialize(fact_class : F.class, @c : C)
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

    # :inherit:
    def match(fact : Fact, bindings : Bindings) : Bindings?
      if fact.is_a?(F)
        if fact.c == self.c
          bindings
        elsif (c = self.c).is_a?(Expression)
          check_result(c.match(fact.c), bindings)
        end
      end
    end

    # Asserts the associated `Fact`.
    #
    def self.assert(c : F::C | Lit | Var, bindings : Bindings)
      if c.is_a?(Lit)
        unless (c = c.target).is_a?(F::C)
          raise ArgumentError.new
        end
      elsif c.is_a?(Var)
        unless (name = c.name?) && (c = bindings[name]?) && c.is_a?(F::C)
          raise ArgumentError.new
        end
      end
      Fact.assert(F.new(c))
    end
  end

  # A pattern that matches a fact with two arguments.
  #
  class BinaryPattern(F, A, B) < FactPattern
    getter a, b

    def initialize(a : A, b : B)
      initialize(F, a, b)
    end

    def initialize(fact_class : F.class, @a : A, @b : B)
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

    # :inherit:
    def match(fact : Fact, bindings : Bindings) : Bindings?
      if fact.is_a?(F)
        if fact.a == self.a && fact.b == self.b
          bindings
        elsif fact.a == self.a && (b = self.b).is_a?(Expression)
          check_result(b.match(fact.b), bindings)
        elsif fact.b == self.b && (a = self.a).is_a?(Expression)
          check_result(a.match(fact.a), bindings)
        elsif (a = self.a).is_a?(Expression) && (b = self.b).is_a?(Expression)
          [a.match(fact.a), b.match(fact.b)].reduce(bindings) do |bindings, result|
            check_result(result, bindings) if bindings
          end
        end
      end
    end

    # Asserts the associated `Fact`.
    #
    def self.assert(a : F::A | Lit | Var, b : F::B | Lit | Var, bindings : Bindings)
      if a.is_a?(Lit)
        unless (a = a.target).is_a?(F::A)
          raise ArgumentError.new
        end
      elsif a.is_a?(Var)
        unless (name = a.name?) && (a = bindings[name]?) && a.is_a?(F::A)
          raise ArgumentError.new
        end
      end
      if b.is_a?(Lit)
        unless (b = b.target).is_a?(F::B)
          raise ArgumentError.new
        end
      elsif b.is_a?(Var)
        unless (name = b.name?) && (b = bindings[name]?) && b.is_a?(F::B)
          raise ArgumentError.new
        end
      end
      Fact.assert(F.new(a, b))
    end
  end

  # A pattern that wraps a proc.
  #
  class ProcPattern < Pattern
    alias ProcType = Proc(Bindings, Bindings | Nil)

    def initialize(@proc : ProcType)
    end

    # :inherit:
    def vars : Enumerable(String)
      [] of String
    end

    # :inherit:
    def match(bindings : Bindings, &block : Bindings -> Nil) : Nil
      if (temporary = @proc.call(bindings))
        if temporary.none? { |k, v| bindings.has_key?(k) && bindings[k] != v }
          yield bindings.merge(temporary)
        end
      end
    end
  end
end
