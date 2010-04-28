#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'
require 'timeout'

# --  Test for bug [#5657]
# http://rubyforge.org/tracker/index.php?func=detail&aid=5657&group_id=1814&atid=7060


class A
  attr_accessor :as
  def initialize
    @as = []
    class << @as
      def <<(an_a)
        super
      end
    end
  end

  def <<(an_a)
    @as << an_a
  end
end

class SingletonTest < Test::Unit::TestCase
  def test_singleton
    RubyProf.call_tree_profile_on = true
    result = RubyProf.profile do
      a = A.new
      a << :first_thing
      assert_equal(1, a.as.size)
    end
    RubyProf::CallTreeTextPrinter.new(result).print('')
  end
end