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
      %Q{<html>
           <head>
             <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
             <title>Ruby-Prof Results</title>
             <style type="text/css" media="screen">
               .call_tree_node {
                 margin-left: 10px;
                 padding-top: 2px;
                 padding-bottom: 1px;
               }
               
               .leaf {
                 color: #333333;
               }
               
               .hide_child_nodes > .call_tree_node {
                 display: none;
               }
               
               .nodes_not_shown {
                 visibility: hidden;
               }
               
               .hide_child_nodes > .nodes_not_shown {
                 visibility: visible;
               }
               
               .insignificant_calls > .nodes_not_shown {
                 visibility: visible;
               }
              
              .show_insignificant_calls > .nodes_not_shown {
                 visibility: hidden;
               }
             </style>
             <script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"> </script>
            
             <script type="text/javascript">
               CallTreeNode = {
                 click: function(node, event) {
                   $(node).toggleClass('hide_child_nodes');
                   event.stopPropagation();
                   return false;
                   $(node).children().toggleClass('red');

                   $(node).slideToggle();
                 }
               }
              </script>
           </head>

           <body>
             <%= @result %>
           </body>
         </html>}.strip
    end

    def node_template
      %Q{<div class="call_tree_node" onclick="CallTreeNode.click(this, event)">#{call_summary(@method)}
           <span class="nodes_not_shown">...</span>
           <%= print_methods(@method.children, method.time) %>
         </div>}.strip
    end

    def leaf_template
      %Q{<div class="call_tree_node leaf">#{call_summary(@method)}</div>}
    end
    
    def insignificant_calls_template
      %Q{<div class="hide_child_nodes" onclick="CallTreeNode.click(this, event)">            
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
        "#{klass}::#{method} #{percentage(call.time)}%"
      end
    end
  end
end
