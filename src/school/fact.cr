module School
  # A fact is a statement that asserts a truth.
  #
  abstract class Fact
  end

  # A fact that asserts a property.
  #
  # e.g. <thing> <is blank>
  #
  abstract class Property(C) < Fact
    getter c

    def initialize(@c : C)
    end
  end

  # A fact that asserts a relationship.
  #
  # e.g. <thing> <follows> <thing>
  #
  abstract class Relationship(A, B) < Fact
    getter a, b

    def initialize(@a : A, @b : B)
    end
  end
end
