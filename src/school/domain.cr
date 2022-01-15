require "./fact"
require "./rule"

module School
  # A domain is a collection of facts.
  #
  class Domain
    @changed = false

    # Returns the facts in the domain.
    #
    def facts
      @facts.dup
    end

    # Adds a fact to the domain.
    #
    def assert(fact : Fact) : Fact
      @facts.add(fact)
      @changed = true
      fact
    end

    # Removes a fact from the domain.
    #
    def retract(fact : Fact) : Fact
      @facts.delete(fact) || raise ArgumentError.new("fact not in domain")
      @changed = true
      fact
    end

    # Returns the rules in the domain.
    #
    def rules
      @rules.dup
    end

    # Adds a rule to the domain.
    #
    def add(rule : Rule) : Rule
      @rules.add(rule)
      @changed = true
      rule
    end

    # Removes a rule from the domain.
    #
    def remove(rule : Rule) : Rule
      @rules.delete(rule) || raise ArgumentError.new("rule not in domain")
      @changed = true
      rule
    end

    # Instantiates a new, empty domain.
    #
    def initialize
      initialize(Set(Fact).new, Set(Rule).new)
    end

    # Instantiates a new domain.
    #
    # Used internally by the domain builder.
    #
    protected def initialize(@facts : Set(Fact), @rules : Set(Rule))
    end

    private record Match, rule : Rule, bindings : Bindings

    private record Satisfaction, condition : Pattern, matches : Indexable(Bindings)

    private def each_match(rule)
      # For each condition, find every rule that satisfies the
      # condition. Capture the values bound to any vars.
      satisfactions =
        rule.conditions.map do |condition|
          matches =
            facts.map do |fact|
              if condition.fact_class == fact.class
                case fact
                when Property
                  if condition.is_a?(UnaryPattern)
                    if fact.c == condition.c
                      Bindings.new
                    elsif (c = condition.c).is_a?(Expression)
                      match = c.match(fact.c)
                      match.bindings if match.success
                    end
                  end
                when Relationship
                  if condition.is_a?(BinaryPattern)
                    if fact.a == condition.a && fact.b == condition.b
                      Bindings.new
                    elsif fact.a == condition.a && (b = condition.b).is_a?(Expression)
                      match = b.match(fact.b)
                      match.bindings if match.success
                    elsif fact.b == condition.b && (a = condition.a).is_a?(Expression)
                      match = a.match(fact.a)
                      match.bindings if match.success
                    elsif (a = condition.a).is_a?(Expression) && (b = condition.b).is_a?(Expression)
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
                when Fact
                  if condition.is_a?(NullaryPattern)
                    Bindings.new
                  end
                end
              end
            end.compact
          Satisfaction.new(condition, matches)
        end

      # If all conditions have matching rules, group them and yield
      # every group where the bound values are consistent.
      unless satisfactions.any?(&.matches.empty?)
        Indexable.each_cartesian(satisfactions.map(&.matches), reuse: true) do |satisfaction|
          conflicts = false
          bindings = satisfaction.reduce(Bindings.new) do |a, b|
            if b.any? { |k, v| a.has_key?(k) && a[k] != v }
              conflicts = true
              break
            end
            a.merge(b)
          end
          if bindings && !conflicts
            yield(bindings)
          end
        end
      end
    end

    private def match_all
      Array(Match).new.tap do |matches|
        rules.each do |rule|
          each_match(rule) do |bindings|
            matches << Match.new(rule, bindings)
          end
        end
      end
    end

    # The status of the run.
    #
    enum Status
      Completed
      Paused
    end

    # Runs the rules engine.
    #
    # First, matches rules' conditions to facts, and then invokes
    # rules' actions for each distinct match.
    #
    def run
      @changed = false
      match_all.each do |match|
        match.rule.call(match.bindings)
        return Status::Paused if @changed
      end
      Status::Completed
    end

    # Domain builder.
    #
    # Used internally to build a domain with a DSL.
    #
    class Builder
      @facts = Set(Fact).new
      @rules = Set(Rule).new

      def fact(f : Fact.class)
        @facts << f.new
        self
      end

      def fact(f : Fact.class, m)
        @facts << f.new(m)
        self
      end

      def fact(m, f : Fact.class)
        @facts << f.new(m)
        self
      end

      def fact(f : Fact.class, m1, m2)
        @facts << f.new(m1, m2)
        self
      end

      def fact(m1, f : Fact.class, m2)
        @facts << f.new(m1, m2)
        self
      end

      def fact(m1, m2, f : Fact.class)
        @facts << f.new(m1, m2)
        self
      end

      def rule(name, &block)
        builder = Rule::Builder.new(name)
        with builder yield
        @rules << builder.build
        self
      end

      def rule(rule : Rule)
        @rules << rule
        self
      end

      # Builds the domain.
      #
      # Every invocation returns the same domain (it is built once and
      # memoized).
      #
      def build
        @domain ||= Domain.new(@facts, @rules)
      end
    end
  end

  # Presents a DSL for defining domains.
  #
  def self.domain(&block)
    builder = Domain::Builder.new
    with builder yield
    builder.build
  end
end
