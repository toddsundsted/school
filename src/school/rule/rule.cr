require "./pattern"

module School
  # An action.
  #
  alias Action = (Rule, Context)->

  # A rule is collection of conditions (patterns) that match against
  # facts, and associated actions.
  #
  class Rule
    def initialize(name : String)
      initialize(name, [] of BasePattern, [] of Action)
    end

    def initialize(@name : String, @conditions : Array(BasePattern), @actions : Array(Action), *, @trace : Bool = false)
    end

    getter name, trace

    def conditions
      @conditions.dup
    end

    def actions
      @actions.dup
    end

    # Returns the variables in the conditions.
    #
    def vars : Enumerable(String)
      @conditions.reduce(Set(String).new) { |vars, pattern| vars.concat(pattern.vars) }
    end

    # Invokes the rule's actions.
    #
    def call(context : Context)
      new_context = Context.new(context.bindings.dup, context.facts)
      @actions.each(&.call(self, new_context))
    end
  end
end
