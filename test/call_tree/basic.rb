require 'test/unit'
require 'ruby-prof'
require 'test/call_tree/common'

# Need to use wall time for this test due to the sleep calls
RubyProf::measure_mode = RubyProf::WALL_TIME


class CallTreeBasicTest < Test::Unit::TestCase
  include Common

  def test_one_level
    RubyProf.start
    method_1a
    method_1b
    results = RubyProf.stop
    
    assert_equal(4, results.size)
    assert_in_delta(0.3, results.time, 0.05)
    assert_profile_result(results[0], :klass=>"CallTreeBasicTest", :method=>'method_1a', :call_count=>1, :time=>0.1, :file=>__FILE__)
    assert_profile_result(results[1], :klass=>"CallTreeBasicTest", :method=>'method_1b', :call_count=>1, :time=>0.2, :file=>__FILE__)
  end

  def test_two_levels
    RubyProf.start
      method_2
    results = RubyProf.stop
    
    assert_equal(5, results.size)
    assert_in_delta(0.3, results.time, 0.05)
    assert_profile_result(results[0], :method=>'method_2')
    assert_profile_result(results[0][0], :method=>'method_1a')
    assert_profile_result(results[0][1], :method=>'method_1b')
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

    dump_to_html(results)
    assert_in_delta(0.2, results.time, 0.05)
    assert_equal(2, results.size)
    assert_equal(1, results.call_count)
    assert_profile_result(results[0], :klass=>"CallTreeBasicTest", :method=>'method_1a', :call_count=>2)
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
