
module Common
  def assert_profile_result(result, expected_values)
    expected_values.each do |key, value|
      check(result, key, value)
    end
  end

  def check(result, method, expected)
    if expected.is_a?(Float)
      assert_in_delta(expected, result.send(method), 0.05, "#{method.to_s}: expected #{expected} got #{result.send(method)} at #{caller[1].inspect}")
    else
      assert_equal(expected, result.send(method), "#{method.to_s}: expected #{expected} got #{result.send(method)} at #{caller[1].inspect}")
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

    attr_reader :klass, :time, :method, :call_count, :file
    attr_accessor :children

    def initialize(klass, method, time, call_count)
      @klass = klass
      @time = time
      @call_count = call_count
      @method = method
      @file = caller[rand(caller.size).to_i].split(':')[0]
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
end
