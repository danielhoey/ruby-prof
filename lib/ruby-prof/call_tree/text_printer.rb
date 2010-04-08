
module RubyProf
  class CallTreeTextPrinter < CallTreeAbstractPrinter
    def print(io)
      io << "<main>\n"
      super(io) 
    end

    def print_methods(io, methods, parent_time=nil)
      super(IndentedIo.new(io, 2), methods, parent_time)
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
