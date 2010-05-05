#!/usr/bin/env ruby
$: <<  "#{File.dirname(__FILE__)}/../lib"
require 'test/unit'
require 'ruby-prof'
require 'test/call_tree/common'

def simple(n)
  sleep(0.1)
  n -= 1
  return if n == 0
  simple(n)
end

def cycle(n)
  sub_cycle(n)
end

def sub_cycle(n)
  sleep(0.1)
  n -= 1
  return if n == 0
  cycle(n)
end

class RecursiveTest < Test::Unit::TestCase
  include Common

  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_simple
    results = RubyProf.profile do
      simple(2)  
    end

    assert_in_delta(0.2, results.time, 0.05)
    assert_equal(4, results.size)
    assert_profile_result(results[0], {:klass=>"Object", :method=>'simple', :time=>0.2, :call_count=>2})
    assert_profile_result(results[0][0], {:klass=>"Kernel", :method=>'sleep', :time=>0.2, :call_count=>2})
  end

  def test_cycle
    results = RubyProf.profile do
      cycle(2)  
    end

    assert_in_delta(0.2, results.time, 0.05)
    assert_equal(5, results.size)
    assert_profile_result(results[0], {:klass=>"Object", :method=>'cycle', :time=>0.2, :call_count=>2})
    assert_profile_result(results[0][0], {:klass=>"Object", :method=>'sub_cycle', :time=>0.2, :call_count=>2})
  end
end
