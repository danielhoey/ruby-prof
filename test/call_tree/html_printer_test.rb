$: <<  "#{File.dirname(__FILE__)}/../lib"
require 'test/unit'
require 'ruby-prof'
require 'test/call_tree/common'
require 'rexml/document'

class CallTreeHtmlPrintersTest < Test::Unit::TestCase
  def test_printer
    call_tree = 
      Common::StubCallTree.create([
        [Array, 'each', 0.5, 1, [
          [Object, 'calc', 0.25, 2]]],
        [Integer, 'to_s', 0.25, 2]
      ])

    lines = ''
    printer = RubyProf::CallTreeHtmlPrinter.new(call_tree)
    printer.print(lines)
  
    doc = REXML::Document.new(lines).root
    assert_equal 1, doc.elements.to_a("//*[@class='call_tree_node']").size
    assert_equal 2, doc.elements.to_a("//*[@class='call_tree_node leaf']/.").size
  end
  
  def test_html_escaping
    call_tree = 
      Common::StubCallTree.create([['#<Class:Benchmark>', 'ms', 0.5, 1]])
   
    lines = ''
    printer = RubyProf::CallTreeHtmlPrinter.new(call_tree)
    printer.print(lines)
    
    doc = REXML::Document.new(lines).root
    assert_equal 1, doc.elements.to_a("//*[@class='call_tree_node leaf']").size
    assert lines =~ /Class:Benchmark/
    assert lines =~ /#&lt;Class:Benchmark&gt;/
  end
end
