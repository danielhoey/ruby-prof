#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require 'timeout'

# --  Tests ----
class ThreadTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_thread_timings
  	RubyProf.start    
    thread = Thread.new do
      sleep 0 # force it to hit thread.join, below, first
      # thus forcing sleep(1), below, to be counted as (wall) self_time
      # since we currently count time "in some other thread" as self.wait_time
      # for whatever reason
      sleep(0.1)
    end
    sleep(0.2)
    thread.join
    
    results = RubyProf.stop
    return 
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
end
