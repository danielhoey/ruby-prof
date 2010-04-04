$: <<  "#{File.dirname(__FILE__)}/../lib"
require 'test/unit'
require 'ruby-prof'
require 'lib/call_tree/text_printer'

class CallTreeTextPrintersTest < Test::Unit::TestCase
  def test_text_printer
    call_tree = 
      StubCallTree.create([
        [Array, 'each', 0.5, 1, [
          [Integer, 'to_s', 0.25, 2]]
        ]
      ])

    lines = []
    printer = RubyProf::CallTreeTextPrinter.new(call_tree)
    printer.print(lines)

    assert_equal 3, lines.size
    assert lines[0] =~ /main/
    assert lines[1] =~ /Array/
    assert lines[1] =~ /each/
    assert lines[1] =~ /0\.5/
    assert lines[1] =~ /1/
    assert lines[2] =~ /Integer/
    assert lines[2] =~ /to_s/
    assert lines[2] =~ /0\.25/
    assert lines[2] =~ /2/
  end

  def test_results_filter
    call_tree = 
      StubCallTree.create([
        [Array, 'each', 0.5, 1, [
          [Integer, 'to_s', 0.25, 2],
          ['SomeClass', 'method', 0.05, 2, [
            [Integer, '+', 0.0001, 2]]]]
        ]
      ])

    lines = []
    printer = RubyProf::CallTreeTextPrinter.new(call_tree, 11)
    printer.print(lines)

    assert_equal 4, lines.size
    assert lines[3] =~ /SomeClass/
    assert lines[3] =~ /method/
    assert lines.all?{|l| l !~ /\+/}
  end

  def test_sort_slowest_first
    call_tree = 
      StubCallTree.create([
        [Array, 'each', 0.5, 1, [
          ['SomeClass', 'method', 0.05, 2, [
            [Integer, '+', 0.0001, 2]]],
          [Integer, 'to_s', 0.25, 2]]
        ]
      ])

    lines = []
    printer = RubyProf::CallTreeTextPrinter.new(call_tree, 11)
    printer.print(lines)

    assert lines[3] =~ /SomeClass/
    assert lines[2] =~ /Integer/
    assert lines[2] =~ /to_s/
  end
end


class StubCallTree
  def self.create(*args)
    if args.size == 1
      ct = StubCallTree.new(nil, '', 0, 1)
      child_nodes = args[0]
    else
      child_nodes = args.delete_at(4) || []
      ct = StubCallTree.new(*args)
    end
    
    ct.children = child_nodes.collect{|child| create(*child)}
    ct
  end

  attr_reader :klass, :time, :method, :call_count
  attr_accessor :children

  def initialize(klass, method, time, call_count)
    @klass = klass
    @time = time
    @call_count = call_count
    @method = method
    @children = []
  end

  def to_s
    if parent
      ["CallTree: #{klass}::#{method}", call_count, time].join(', ')
    else
      "CallTree: <root>"
    end
  end
end
