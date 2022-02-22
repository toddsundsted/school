module School
  # Bindings.
  #
  alias Bindings = Hash(String, DomainTypes)

  # Result.
  #
  # Holds the result of a match as well as any resulting bindings.
  #
  private record Result, success : Bool, bindings : Bindings? = nil

  # An expression.
  #
  abstract class Expression
    @name : String?

    private NAME = /[a-z][a-zA-Z0-9_-]*/

    # Sets the name of the expression.
    #
    protected def name=(@name)
      raise ArgumentError.new("#{@name.inspect} is not a valid name") unless @name =~ NAME
    end

    # Returns the name of the expression.
    #
    getter! name

    # Matches the expression to a value.
    #
    abstract def match(value : DomainTypes) : Result
  end

  # A literal.
  #
  class Lit < Expression
    getter target

    def initialize(@target : DomainTypes)
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      Result.new(value == @target)
    end
  end

  # A variable.
  #
  class Var < Expression
    def initialize(name : String)
      self.name = name
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      Result.new(true, Bindings{name => value})
    end
  end

  # A "not" expression.
  #
  class Not < Expression
    def initialize(@target : Expression)
    end

    def initialize(target : DomainTypes)
      initialize(Lit.new(target))
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      match = @target.match(value)
      Result.new(!match.success, match.bindings)
    end
  end

  # A "within" expression.
  #
  class Within < Expression
    def initialize(*targets : Lit | Var)
      @targets = Array(Lit | Var).new
      targets.each { |target| @targets << target }
    end

    def initialize(*targets : DomainTypes)
      @targets = Array(Lit | Var).new
      targets.each { |target| @targets << Lit.new(target) }
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      @targets.each do |target|
        match = target.match(value)
        return match if match.success
      end
      Result.new(false)
    end
  end
end
