require "../rule"
{% if flag?(:"school:metrics") %}
  require "./metrics"
{% end %}

module School
  # Rule evaluation tracing utility class.
  #
  class Trace
    def rule(rule : Rule)
    end

    def succeed
    end

    def fail
    end
  end

  # A domain is a collection of facts.
  #
  class Domain
    @changed = false

    # Returns the facts in the domain.
    #
    def facts
      Fact.facts
    end

    # Adds a fact to the domain.
    #
    def assert(fact : Fact) : Fact
      @changed = true
      Fact.assert(fact)
    end

    # Removes a fact from the domain.
    #
    def retract(fact : Fact) : Fact
      @changed = true
      Fact.retract(fact)
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
      initialize(Set(Rule).new)
    end

    # Instantiates a new domain.
    #
    # Used internally by the domain builder.
    #
    protected def initialize(@rules : Set(Rule))
    end

    private record Match, rule : Rule, bindings : Bindings

    private def each_match(conditions : Array(BasePattern), bindings = Bindings.new, &block : Bindings ->)
      if (condition = conditions.first?)
        {% if flag?(:"school:metrics") %}
          Metrics.count_condition
        {% end %}
        condition.match(bindings) do |temporary|
          each_match(conditions[1..-1], temporary, &block) if temporary
        end
      else
        block.call(bindings)
      end
    end

    private def match_all
      @matches = false
      rules.each do |rule|
        Array(Match).new.tap do |matches|
          {% if flag?(:"school:metrics") %}
            Metrics.count_rule
          {% end %}
          each_match(rule.conditions) do |bindings|
            matches << Match.new(rule, bindings)
          end
        end.each do |match|
          @matches = true
          yield match
        end
      end
      @matches ? Status::Completed : Status::NoMatches
    end

    # The status of the run.
    #
    enum Status
      NoMatches
      Completed
    end

    # Runs the rules engine.
    #
    # First, matches rules' conditions to facts, and then invokes
    # rules' actions for each distinct match.
    #
    # Rules are matched in order of their definition. Within a run,
    # earlier rules can influence later rules (by asserting or
    # retracting facts). Later rules cannot influence earlier rules.
    #
    def run
      {% if flag?(:"school:metrics") %}
        Metrics.count_run
      {% end %}
      match_all do |match|
        match.rule.call(match.bindings)
      end
    end
  end
end
