$: <<  "#{File.dirname(__FILE__)}/../lib"
require 'test/unit'
require 'ruby-prof'

# Need to use wall time for this test due to the sleep calls
RubyProf::measure_mode = RubyProf::WALL_TIME


class CallTreeBasicTest < Test::Unit::TestCase
  def setup
    RubyProf::call_tree_profile_on = true
  end

  def teardown
    RubyProf::call_tree_profile_on = false
  end

  def test_one_level
    RubyProf.start
    method_1a
    method_1b
    results = RubyProf.stop
    
    assert_equal(4, results.size)
    assert_in_delta(0.3, results.time, 0.05)
    assert_equal('method_1a', results[0].method)
    assert_equal(CallTreeBasicTest, results[0].klass)
    assert_equal(__FILE__, results[0].file)
    assert_equal('method_1b', results[1].method)
    assert_equal(CallTreeBasicTest, results[1].klass)
    assert_equal(__FILE__, results[0].file)
    assert_in_delta(0.1, results[0].time, 0.05)
    assert_in_delta(0.2, results[1].time, 0.05)
  end

  def test_two_levels
    RubyProf.start
      method_2
    results = RubyProf.stop
    
    assert_equal(5, results.size)
    assert_in_delta(0.3, results.time, 0.05)
    assert_equal('method_2', results[0].method)
    assert_equal(CallTreeBasicTest, results[0].klass)
    assert_equal('method_1a', results[0][0].method)
    assert_equal('method_1b', results[0][1].method)
  end

  def test_exception
    RubyProf.start
    begin
      method_exception
    rescue
    end
    results = RubyProf.stop
    assert results != nil
  end

  def test_multiple_calls_to_same_method
    RubyProf.start
      method_1a
      method_1a
    results = RubyProf.stop

    assert_in_delta(0.2, results.time, 0.05)
    assert_equal(2, results.size)
    assert_equal(1, results.call_count)
    assert_equal(2, results[0].call_count)
    assert_equal(CallTreeBasicTest, results[0].klass)
    assert_equal('method_1a', results[0].method)
  end

  def test_stop_after_root_context_finished
    method_start
    results = RubyProf.stop
    assert_equal(0, results.size)
  end
private
  def method_1a
    sleep 0.1
  end

  def method_1b
    sleep 0.2 
  end

  def method_2
    method_1a
    method_1b
  end

  def method_3
    method_1a
  end

  def method_exception
    raise 'error'
  end

  def method_start
    RubyProf.start
  end
end
