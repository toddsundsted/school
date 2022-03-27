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

    # Binds the value into a result.
    #
    protected def bind(value : DomainTypes, result : Result? = nil) : Result
      if result && (temporary = result.bindings)
        name? ?
          Result.new(true, temporary.merge(Bindings{name => value})) :
          Result.new(true, temporary)
      else
        name? ?
          Result.new(true, Bindings{name => value}) :
          Result.new(true)
      end
    end

    protected def no_match
      Result.new(false)
    end
  end

  # A literal.
  #
  class Lit < Expression
    getter target

    def initialize(@target : DomainTypes, name : String? = nil)
      self.name = name if name
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      value == @target ? bind(value) : no_match
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
      bind(value)
    end
  end

  # A "not" expression.
  #
  class Not < Expression
    getter target

    def initialize(@target : Expression, name : String? = nil)
      self.name = name if name
    end

    def initialize(target : DomainTypes, name : String? = nil)
      initialize(Lit.new(target), name: name)
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      result = @target.match(value)
      !result.success ? bind(value, result) : no_match
    end
  end

  # A "within" expression.
  #
  class Within < Expression
    getter targets

    def initialize(*targets : Lit | Var, name : String? = nil)
      @targets = Array(Lit | Var).new
      targets.each { |target| @targets << target }
      self.name = name if name
    end

    def initialize(*targets : DomainTypes, name : String? = nil)
      @targets = Array(Lit | Var).new
      targets.each { |target| @targets << Lit.new(target) }
      self.name = name if name
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      @targets.each do |target|
        result = target.match(value)
        return bind(value, result) if result.success
      end
      no_match
    end
  end
end
