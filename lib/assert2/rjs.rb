require 'rkelly/visitors'  #  ERGO  advise AP these requirers are broke!
require 'rkelly/visitable'
require 'rkelly/nodes/node'
require 'rkelly/nodes/postfix_node'
require 'rkelly'
require 'assert2/xhtml'

module Test; module Unit; module Assertions

  class AssertRjs
    def initialize(js); @ast = RKelly.parse(@js = js); end
    
    def replace_html command, target, &block
      @ast.pointcut('Element.update()').matches.each do |updater|
        updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
          div_id, html = thang.value
          
          if target and html
            div_id = eval(div_id.value)
            html   = eval(html.value)
            if div_id == target.to_s
              block.call(div_id, html)
            end
          end
        end
      end
      return false
    end
    
    def alert command, matcher, &block
      @ast.pointcut('alert()').matches.each do |updater|
        updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
          text = thang.value.first
          text = eval(text.value)
          return text if text =~ /#{matcher}/ or text.index(matcher.to_s)
        end
      end
      return false
    end
  end

  def assert_rjs(command, target, matcher = //, &block)
    rjs = AssertRjs.new(js = @response.body)
    
    command == :replace_html or  #  TODO  put me inside the method_missing!
      flunk("assert_rjs's alpha version only respects :replace_html")
      
    rjs.send command, command, target do |div_id, html|
      cornplaint = "#{ command } for ID #{ target } has incorrect payload, in #{ js }"
      assert_match matcher, html, cornplaint
      assert_xhtml html, cornplaint, &block if block
      return html
    end
    
    flunk "#{ command } for ID #{ target } not found in #{ js }"
  end

end; end; end