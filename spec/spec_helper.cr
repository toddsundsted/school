require "../src/school"

require "spectator"
require "yaml"

macro finished
  {% if School.has_constant? "Fact" %}
    class MockFact < School::Fact
    end

    class MockProperty < School::Property(Int32)
    end

    class MockRelationship < School::Relationship(String, String)
    end
  {% end %}

  {% if School.has_constant? "Rule" %}
    class MockRule < School::Rule
    end
  {% end %}
end

# Every project must specify the types of objects used in the
# domain. The tests use `String` and `Int32`.
alias DomainTypes = String | Int32
