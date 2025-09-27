module School
  # A fact is a statement that asserts a truth.
  #
  abstract class Fact
    protected def _class
      self.class
    end

    def_equals_and_hash _class

    # Appends a short `String` representation of this object.
    #
    def to_s(io : IO)
      self.class.to_s(io)
    end
  end

  # A fact that asserts a property.
  #
  # e.g. <thing> <is blank>
  #
  abstract class Property(C) < Fact
    getter c

    def_equals_and_hash _class, c

    def initialize(@c : C)
    end
  end

  # A fact that asserts a relationship.
  #
  # e.g. <thing> <follows> <thing>
  #
  abstract class Relationship(A, B) < Fact
    getter a, b

    def_equals_and_hash _class, a, b

    def initialize(@a : A, @b : B)
    end
  end
end
