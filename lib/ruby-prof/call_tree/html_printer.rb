require 'erb'
require 'rexml/document'
require 'cgi'

module RubyProf
  class CallTreeHtmlPrinter < CallTreeAbstractPrinter
    def initialize(call_tree, min_percentage=0)
      super(call_tree, min_percentage)
      @total_time = call_tree.children.inject(0){|s, c| s+=c.time}
    end

    def print(io)
      @result = print_methods(@call_tree.children)
      @result = "<div id='main'>main (#{@total_time}s)\n  #{@result}\n</div>"
      
      erb = ERB.new(page_template, nil, nil)
      output = erb.result(binding)
      File.open("#{self.class.to_s}.html", 'w+'){|f| f << output}
      REXML::Document.new(output).write(io, 2)
    end

    def print_methods(methods, parent_time=nil)
      result = ''
      methods.sort_by{|m| m.time}.reverse.each do |method|
        @method = method
        if method.children.empty? or (parent_time and method.time < parent_time * @min_percentage / 100)
          erb = ERB.new(leaf_template, nil, nil)
        else
          erb = ERB.new(node_template, nil, nil)
        end
        result << erb.result(binding)
      end
      result
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
             </style>
             <script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"></script>
             <script type="text/javascript">
               $(document).ready(function(){
                   $('.call_tree_node').click(function(event){
                     $('.call_tree_node', this).slideToggle();
                   });
               });
              </script>
           </head>

           <body>
             <%= @result %>
           </body>
         </html>}.strip
    end

    def node_template
      %Q{<div class="call_tree_node">#{call_summary(@method)}
           <%= print_methods(@method.children, method.time) %>
         </div>}.strip
    end

    def leaf_template
      %Q{<div class="call_tree_node">#{call_summary(@method)}</div>}
    end
    
    def call_summary(call)
      klass, method = %w(klass method).collect{|m| CGI.escapeHTML(call.send(m).to_s)}
      "#{klass}::#{method} #{percentage(call.time)}%"
    end
  end
end
