module RubyProf
  class CallTreeAbstractPrinter
    def initialize(call_tree, min_percentage=0)
      @call_tree = call_tree
      @min_percentage = min_percentage.to_f
    end

    def print(io)
      print_methods(io, @call_tree.children)
    end

    def print_methods(io, methods, parent_time=nil)
      methods.sort_by{|m| m.time}.reverse.each do |method|
        io << format_method(method)
        next if parent_time and method.time < parent_time * @min_percentage / 100
        print_methods(io, method.children, method.time)
      end
    end

    def format_method(method)
      raise "abstract"
    end
  end
end
