require File.dirname(__FILE__) + '/../test_helper'

class HouseholdTest < Test::Unit::TestCase
  fixtures :households

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Household, households(:first)
  end
end
