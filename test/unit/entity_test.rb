require File.dirname(__FILE__) + '/../test_helper'

class EntityTest < Test::Unit::TestCase
  fixtures :entities

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Entity, entities(:first)
  end
end
