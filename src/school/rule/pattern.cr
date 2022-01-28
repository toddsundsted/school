require "./expression"
require "../fact"

module School
  # A pattern.
  #
  abstract class Pattern
    getter fact_class : Fact.class = Fact

    # Returns the variables in the pattern.
    #
    abstract def vars : Enumerable(String)

    # Indicates whether or not the fact matches the pattern.
    #
    abstract def match(fact : Fact) : Bindings?

    # A special pattern that indicates a condition that is satisfied
    # if and only if at least one fact matches the wrapped pattern.
    #
    class Any < Pattern
      def initialize(@pattern : Pattern)
      end

      # :inherit:
      def vars : Enumerable(String)
        @pattern.vars
      end

      # :inherit:
      def match(fact : Fact) : Bindings?
        @pattern.match(fact)
      end
    end

    # A special pattern that indicates a condition that is satisfied
    # if and only if no facts match the wrapped pattern.
    #
    class None < Pattern
      def initialize(@pattern : Pattern)
      end

      # :inherit:
      def vars : Enumerable(String)
        @pattern.vars
      end

      # :inherit:
      def match(fact : Fact) : Bindings?
        @pattern.match(fact)
      end
    end
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
      Set(String).new
    end

    # :inherit:
    def match(fact : Fact) : Bindings?
      if fact.is_a?(F)
        Bindings.new
      end
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

    # :inherit:
    def match(fact : Fact) : Bindings?
      if fact.is_a?(F)
        if fact.c == self.c
          Bindings.new
        elsif (c = self.c).is_a?(Expression)
          match = c.match(fact.c)
          match.bindings if match.success
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

    # :inherit:
    def match(fact : Fact) : Bindings?
      if fact.is_a?(F)
        if fact.a == self.a && fact.b == self.b
          Bindings.new
        elsif fact.a == self.a && (b = self.b).is_a?(Expression)
          match = b.match(fact.b)
          match.bindings if match.success
        elsif fact.b == self.b && (a = self.a).is_a?(Expression)
          match = a.match(fact.a)
          match.bindings if match.success
        elsif (a = self.a).is_a?(Expression) && (b = self.b).is_a?(Expression)
          match_a = a.match(fact.a)
          match_b = b.match(fact.b)
          if match_a.success && match_b.success
            if (bindings_a = match_a.bindings) && (bindings_b = match_b.bindings)
              if (bindings_a.keys & bindings_b.keys).all? { |key| bindings_a[key] == bindings_b[key] }
                bindings_a.merge(bindings_b)
              end
            else
              match_a.bindings || match_b.bindings
            end
          end
        end
      end
    end
  end
end
