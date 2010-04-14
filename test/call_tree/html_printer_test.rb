$: <<  "#{File.dirname(__FILE__)}/../lib"
require 'test/unit'
require 'ruby-prof'
require 'test/call_tree/stub_call_tree'
require 'rexml/document'
#require 'rubygems'; require 'ruby-debug';

class CallTreeHtmlPrintersTest < Test::Unit::TestCase
  def test_printer
    call_tree = 
      StubCallTree.create([
        [Array, 'each', 0.5, 1, [
          [Object, 'calc', 0.25, 2]]],
        [Integer, 'to_s', 0.25, 2]
      ])

    lines = ''
    printer = RubyProf::CallTreeHtmlPrinter.new(call_tree)
    printer.print(lines)
    
    ctn_xpath = "[@class='call_tree_node']"
    doc = REXML::Document.new(lines).root
    assert_equal 3, doc.elements.to_a("//*#{ctn_xpath}").size
    assert_equal 2, doc.elements.to_a("/html/body/div/div#{ctn_xpath}/.").size
    assert_equal 1, doc.elements.to_a("/html/body/div/div#{ctn_xpath}/div#{ctn_xpath}").size
  end
  
  def test_html_escaping
    call_tree = 
      StubCallTree.create([['#<Class:Benchmark>', 'ms', 0.5, 1]])
   
    lines = ''
    printer = RubyProf::CallTreeHtmlPrinter.new(call_tree)
    printer.print(lines)
    
    ctn_xpath = "[@class='call_tree_node']"
    doc = REXML::Document.new(lines).root
    assert_equal 1, doc.elements.to_a("//*#{ctn_xpath}").size
    assert lines =~ /Class:Benchmark/
    assert lines =~ /#&lt;Class:Benchmark&gt;/
  end
end
