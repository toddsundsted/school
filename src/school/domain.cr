require "./fact"
require "./rule"

module School
  # A domain is a collection of facts.
  #
  class Domain
    @facts = Set(Fact).new

    # Returns the facts in the domain.
    #
    def facts
      @facts.dup
    end

    # Adds a fact to the domain.
    #
    def assert(fact : Fact) : Fact
      @facts.add(fact)
      fact
    end

    # Removes a fact from the domain.
    #
    def retract(fact : Fact) : Fact
      @facts.delete(fact) || raise ArgumentError.new("fact not in domain")
      fact
    end

    @rules = Set(Rule).new

    # Returns the rules in the domain.
    #
    def rules
      @rules.dup
    end

    # Adds a rule to the domain.
    #
    def add(rule : Rule) : Rule
      @rules.add(rule)
      rule
    end

    # Removes a rule from the domain.
    #
    def remove(rule : Rule) : Rule
      @rules.delete(rule) || raise ArgumentError.new("rule not in domain")
      rule
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
                    elsif (c = condition.c).is_a?(Var)
                      Bindings{c.name => fact.c}
                    end
                  end
                when Relationship
                  if condition.is_a?(BinaryPattern)
                    if fact.a == condition.a && fact.b == condition.b
                      Bindings.new
                    elsif fact.a == condition.a && (b = condition.b).is_a?(Var)
                      Bindings{b.name => fact.b}
                    elsif fact.b == condition.b && (a = condition.a).is_a?(Var)
                      Bindings{a.name => fact.a}
                    elsif (a = condition.a).is_a?(Var) && (b = condition.b).is_a?(Var)
                      if a.name != b.name
                        Bindings{a.name => fact.a, b.name => fact.b}
                      elsif fact.a == fact.b
                        Bindings{a.name => fact.a}
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

    # Runs the rules engine.
    #
    # First, matches rules' conditions to facts, and then invokes
    # rules' actions for each distinct match.
    #
    def run
      match_all.each do |match|
        match.rule.call(match.bindings)
      end
    end
  end
end
