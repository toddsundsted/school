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
end
