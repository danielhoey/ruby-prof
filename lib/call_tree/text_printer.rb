module RubyProf
  class CallTreeTextPrinter
    def initialize(call_tree, min_percentage=0)
      @call_tree = call_tree
      @min_percentage = min_percentage.to_f
    end

    def print(io)
      io << "<main>\n"
      print_methods(io, @call_tree.children)
    end

    def print_methods(io, methods, parent_time=nil)
      io = IndentedIo.new(io, 2)
      methods.sort_by{|m| m.time}.reverse.each do |method|
        io << format_method(method)
        next if parent_time and method.time < parent_time * @min_percentage / 100
        print_methods(io, method.children, method.time)
      end
    end

    def format_method(method)
      "#{method.klass}::#{method.method}, #{method.time}, #{method.call_count}\n"
    end

    class IndentedIo
      def initialize(io, indent)
        @io = io
        @indent = Array.new(indent, ' ').join
      end

      def <<(text)
        @io << "#{@indent}#{text}"
      end
    end
  end
end
