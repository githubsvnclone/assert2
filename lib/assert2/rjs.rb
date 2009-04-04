require 'rkelly/visitors'  #  ERGO  advise AP these requirers are broke!
require 'rkelly/visitable'
require 'rkelly/nodes/node'
require 'rkelly/nodes/postfix_node'
require 'rkelly'
require 'assert2/xhtml'

module Test; module Unit; module Assertions

  def assert_rjs(command, target, matcher = //, &block)
    ast = RKelly.parse(@response.body)
    command == :replace_html or 
      flunk("assert_rjs's alpha version only respects :replace_html")
    
    ast.pointcut('Element.update()').matches.each do |updater|
      updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
        div_id, html = thang.value
        
        if target and html
          div_id = eval(div_id.value)
          html   = eval(html.value)
          if div_id == target.to_s
            assert_match matcher, html
            assert_xhtml html, &block if block
            return html
          end
        end
      end
    end
    flunk 'TODO'
  end

end; end; end