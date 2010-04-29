#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require 'rubygems'
require 'ruby-debug'

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


def simple(n)
  sleep(1)
  n -= 1
  return if n == 0
  simple(n)
end

def cycle(n)
  sub_cycle(n)
end

def sub_cycle(n)
  sleep(1)
  n -= 1
  return if n == 0
  cycle(n)
end

class RecursiveTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_simple
    results = RubyProf.profile do
      simple(2)  
    end

    assert_in_delta(2, results.time, 0.05)
    assert_equal(4, results.size)
    assert_equal(2, results[0].call_count)
    assert_in_delta(2, results[0].time, 0.05)
    assert_equal('simple', results[0].method)
    assert_equal(Object, results[0].klass)
    
    assert_equal(2, results[0][0].call_count)
    assert_in_delta(2, results[0][0].time, 0.05)
    assert_equal('sleep', results[0][0].method)
    assert_equal(Kernel, results[0][0].klass)
  end

  def test_cycle
    results = RubyProf.profile do
      cycle(2)  
    end

    assert_in_delta(2, results.time, 0.05)
    assert_equal(5, results.size)
    assert_equal(2, results[0].call_count)
    assert_in_delta(2, results[0].time, 0.05)
    assert_equal('cycle', results[0].method)
    assert_equal(Object, results[0].klass)

    assert_equal(2, results[0][0].call_count)
    assert_in_delta(2, results[0][0].time, 0.05)
    assert_equal('sub_cycle', results[0][0].method)
    assert_equal(Object, results[0][0].klass)
  end
end
