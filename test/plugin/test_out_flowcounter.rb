# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/out_flowcounter.rb'

class FlowcounterOutTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test 'failure' do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::FlowcounterOut).configure(conf)
  end
end
