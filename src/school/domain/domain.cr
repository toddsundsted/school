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

    private def each_match(conditions : Array(Pattern), bindings = Bindings.new, &block : Bindings ->)
      if (condition = conditions.first?)
        facts.each do |fact|
          if (temporary = condition.match(fact))
            next if temporary.any? { |k, v| bindings.has_key?(k) && bindings[k] != v }
            each_match(conditions[1..-1], bindings.merge(temporary), &block)
          end
        end
      else
        block.call(bindings)
      end
    end

    private def match_all
      Array(Match).new.tap do |matches|
        rules.each do |rule|
          each_match(rule.conditions) do |bindings|
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
