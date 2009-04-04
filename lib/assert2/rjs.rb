$:.unshift '~/projects/ruby/rkelly/lib'  #  TODO  correct path!
require 'rkelly'

module Test; module Unit; module Assertions

  def assert_rjs(command, target, matcher = //)
    ast = RKelly.parse(@response.body)
    command == :replace_html or 
      flunk("assert_rjs's alpha version only respects :replace_html")
    
    ast.pointcut('Element.update()').matches.each do |updater|
      updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
        div_id, html = thang.value
        
        if target and html
          div_id = eval(div_id.value)
          html   = eval(html.value)
p target
p html
          if div_id == target.to_s
            assert_match matcher, html
            return html
          end
        end
      end
    end
    flunk 'TODO'
  end

end; end; end