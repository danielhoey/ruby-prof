require 'erb'
require 'rexml/document'
require 'cgi'

module RubyProf
  class CallTreeHtmlPrinter < CallTreeAbstractPrinter
    def initialize(call_tree, min_percentage=2)
      super(call_tree, min_percentage)
      @total_time = call_tree.children.inject(0){|s, c| s+=c.time}
    end

    def print(io)
      @result = print_methods(@call_tree.children, @call_tree.time)
      @result = "<div id='main'>main (#{@total_time}s)\n  #{@result}\n</div>"
      formatted_result = ''
      REXML::Document.new(@result).write(formatted_result, 2)
      @result = formatted_result
      erb = ERB.new(page_template, nil, nil)
      io << erb.result(binding)      
    end

    def print_methods(method_calls, parent_time)
      result = ''
      
      significant_method_calls = method_calls.find_all{|call| call.time >= (parent_time * @min_percentage.to_f / 100) and percentage(call.time) >= 1}
      significant_method_calls.sort_by{|m| m.time}.reverse.each do |method|
        @method = method
        if method.children.empty? 
          erb = ERB.new(leaf_template, nil, nil)
        else
          erb = ERB.new(node_template, nil, nil)
        end
        result << erb.result(binding)
      end
    
      return result
      
      @insignificant_method_calls = method_calls - significant_method_calls
      unless @insignificant_method_calls.empty?
        erb = ERB.new(insignificant_calls_template, nil, nil)
        result << erb.result(binding)
      end
      
      result
    end
    
    def print_leaf(method_call)
      @method = method_call
      ERB.new(leaf_template, nil, nil).result(binding)
    end

    def percentage(time)
      ((time * 100) / @total_time).to_i
    end

    def page_template
     @page_template ||= File.read("#{File.dirname(__FILE__)}/html_printer_output.html.erb")
    end

    def node_template
      %Q{<div class="call_tree_node" time="#{percentage(@method.time)}" onclick="CallTree.click(this, event)">#{call_summary(@method)}
           <span class="nodes_not_shown">...</span>
           <%= print_methods(@method.children, method.time) %>
         </div>}.strip
    end

    def leaf_template
      %Q{<div class="call_tree_node leaf" time="#{percentage(@method.time)}">#{call_summary(@method)}</div>}
    end
    
    def insignificant_calls_template
      %Q{<div class="hide_child_nodes" onclick="CallTree.click(this, event)">            
           <div class="nodes_not_shown">...</div>
           <% @insignificant_method_calls.each do |call| %>
             <%= print_leaf(call) %>
           <% end %>
         </div>}.strip
    end
    
    def call_summary(call)
      klass, method = %w(klass method).collect{|m| CGI.escapeHTML(call.send(m).to_s)}
      if percentage(call.time) < 1
        "#{klass}::#{method}"
      else
        "<span class='klass_and_method'>#{klass}::#{method}</span> - <span class='percentage'>#{percentage(call.time)}%</span> <span class='extra_info'>(<span class='file'>#{call.file},</span> <span class='time'>#{(call.time*1000).to_i}ms,</span> <span class='call_count'>#{call.call_count} calls</span>)</span>"
      end
    end
  end
end
