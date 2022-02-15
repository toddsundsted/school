module School
  # Bindings.
  #
  alias Bindings = Hash(String, DomainTypes)

  # Result.
  #
  # Holds the result of a match as well as any passed bindings.
  #
  private record Result, success : Bool, bindings : Bindings? = nil

  # An expression.
  #
  abstract class Expression
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
    NAME = /[a-z][a-z0-9_-]*/i

    getter name

    def initialize(@name : String)
      raise ArgumentError.new("#{@name.inspect} is not a valid name") unless @name =~ NAME
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      Result.new(true, Bindings{@name => value})
    end
  end

  # A "not" expression.
  #
  class Not < Expression
    def initialize(@target : DomainTypes | Expression)
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      case (target = @target)
      in DomainTypes
        Result.new(value != target)
      in Expression
        match = target.match(value)
        Result.new(!match.success, match.bindings)
      end
    end
  end

  # A "within" expression.
  #
  class Within < Expression
    @targets : Array(DomainTypes | Lit | Var)

    def initialize(*targets : DomainTypes | Lit | Var)
      @targets = Array(DomainTypes | Lit | Var){*targets}
    end

    # :inherit:
    def match(value : DomainTypes) : Result
      result =
        @targets.each do |target|
          case target
          in DomainTypes
            break Result.new(true) if value == target
          in Expression
            break target.match(value)
          end
        end
      result || Result.new(false)
    end
  end
end
