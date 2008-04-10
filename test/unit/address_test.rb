require File.dirname(__FILE__) + '/../test_helper'

class AddressTest < Test::Unit::TestCase
  fixtures :addresses

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Address, addresses(:first)
  end
end
