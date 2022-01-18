require "../rule"

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
      # For each condition, find every fact that satisfies the
      # condition. Capture the values bound to any vars.
      satisfactions =
        rule.conditions.map do |condition|
          matches = facts.map { |fact| condition.match(fact) }.compact
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
  end
end
