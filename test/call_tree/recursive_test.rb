#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'

@@fib_hash = Hash.new{|h,k| h[k] = calc_fib(k)}
def fib(n)
  @@fib_hash[n]
end

def calc_fib(n)
  return 0 if n == 0
  return 1 if n == 1
  return fib(n-1) + fib(n-2)
end

def basic_fib(n)
  return 0 if n == 0
  return 1 if n == 1
  return basic_fib(n-1) + basic_fib(n-2)
end

class RecursiveTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
    RubyProf::call_tree_profile_on = true
  end

  def test_cycle
    result = RubyProf.profile do
      n = 10
      puts "fib(#{n}): #{basic_fib(n)}"
    end

    File.open('recursive.html', 'w+'){|f| RubyProf::CallTreeHtmlPrinter.new(result).print(f)}
  end
end
