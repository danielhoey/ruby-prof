$: <<  "#{File.dirname(__FILE__)}/../lib"
require 'test/unit'
require 'ruby-prof'
require 'test/call_tree/common'

def generate_call_tree(time, max_children)
  this_time = time
  if max_children > 0
    number_of_children = rand(max_children+1).to_i
    children = (0..number_of_children).to_a.collect {
      child_time = time * (0.1 + rand(0.6))
      time = time - child_time 
      generate_call_tree(child_time, max_children-1)
    }
  else
    children = []
  end
  [get_klass, "method", this_time, rand(10).to_i, children]
end

def get_klass
  Module.constants[rand(Module.constants.size).to_i]
end

call_tree = Common::StubCallTree.create([generate_call_tree(10.0, 7)])

File.open('html_printer_test.html', 'w+'){|f| RubyProf::CallTreeHtmlPrinter.new(call_tree).print(f)}

