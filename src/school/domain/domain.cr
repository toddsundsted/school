require "../rule"
require "../utils/trace"
{% if flag?(:"school:metrics") %}
  require "./metrics"
{% end %}

module School
  class TraceRoot < Trace
    def rule(rule : Rule)
      @rule = "Rule #{rule.name}"
    end

    protected def render(ar = [] of String)
      ar << @rule.to_s if @rule
    end

  end

  # A domain is a collection of facts.
  #
  class Domain
    @changed = false
    @facts = Set(Fact).new

    # Returns the facts in the domain.
    #
    def facts
      @facts.dup
    end

    # Adds a fact to the domain.
    #
    def assert(fact : Fact) : Fact
      @changed = true
      @facts.add?(fact) || raise ArgumentError.new("already asserted")
      fact
    end

    # Removes a fact from the domain.
    #
    def retract(fact : Fact) : Fact
      @changed = true
      @facts.delete(fact) || raise ArgumentError.new("already retracted")
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
      initialize(Set(Rule).new)
    end

    # Instantiates a new domain.
    #
    # Used internally by the domain builder.
    #
    protected def initialize(@rules : Set(Rule), @facts : Set(Fact) = Set(Fact).new)
    end

    # Copies the domain.
    #
    # By default, facts and rules are *shared*.
    #
    def copy(independent_rules = false, independent_facts = false)
      self.class.new(
        independent_rules ? Set(Rule).new : @rules,
        independent_facts ? Set(Fact).new : @facts,
      )
    end

    private record Match, rule : Rule, context : Context

    private def each_match(conditions : Array(BasePattern), bindings = Bindings.new, trace : TraceNode? = nil, &block : Context ->)
      if (condition = conditions.first?)
        {% if flag?(:"school:metrics") %}
          Metrics.count_condition
        {% end %}
        any_matches = false
        context = Context.new(bindings, facts)
        condition.match(context, trace) do |temporary|
          any_matches = true
          if temporary
            if trace
              trace.nest do |trace|
                each_match(conditions[1..-1], temporary, trace, &block)
              end
            else
              each_match(conditions[1..-1], temporary, &block)
            end
          end
        end
        unless any_matches
          # matching fails if any condition in this branch fails to match any facts
          trace.fail if trace
          return
        end
      else
        # matching succeeds if there are no more conditions left to check
        trace.succeed if trace
        context = Context.new(bindings, @facts)
        block.call(context)
      end
    end

    private def match_all
      @matches = false
      rules.each do |rule|
        if rule.trace
          root = Trace.root
          root.rule(rule)
          node = root.nest
        end
        Array(Match).new.tap do |matches|
          {% if flag?(:"school:metrics") %}
            Metrics.count_rule
          {% end %}
          each_match(rule.conditions, trace: node) do |context|
            matches << Match.new(rule, context)
          end
        end.each do |match|
          @matches = true
          yield match
        end
      ensure
        if root
          root.dump
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
        match.rule.call(match.context)
      end
    end
  end
end
