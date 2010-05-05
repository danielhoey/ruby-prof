#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require 'timeout'
require 'test/call_tree/common'
require 'rubygems'; require 'ruby-debug'

class ThreadTest < Test::Unit::TestCase
  include Common
 
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_threads_in_call_tree
  	RubyProf.start    
    thread = Thread.new do
       method_a
     end
    method_b
    thread.join
    
    results = RubyProf.stop
    dump_to_html(results)
    debugger
    assert_equal(8, results.size)
    assert_profile_result(results[0], :klass=>"<Class::Thread>", :method=>'new', :call_count=>1, 
      #:time=>0.1, 
      :file=>__FILE__)
    assert_profile_result(results[1], :klass=>"[thread]", :call_count=>1, 
      #:time=>0.1, 
      :file=>__FILE__)
 end
  
  def test_thread
    return
    result = RubyProf.profile do
      begin
        status = Timeout::timeout(0.5) do
          while true
            next
          end
        end
      rescue Timeout::Error
      end
    end
  end
  
  private
  def method_a
    sleep 0.1
  end
  
  def method_b
    sleep 0.2
  end
end
