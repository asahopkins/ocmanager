require File.dirname(__FILE__) + '/../test_helper'
require "#{RAILS_ROOT}/vendor/plugins/backgroundrb/backgroundrb.rb"
require "#{RAILS_ROOT}/lib/workers/bulk_email_worker"
require 'drb'

class BulkEmailWorkerTest < Test::Unit::TestCase

  # Replace this with your real tests.
  def test_truth
    assert BulkEmailWorker.included_modules.include?(DRbUndumped)
  end
end
