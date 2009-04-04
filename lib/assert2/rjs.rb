require 'rkelly/visitors'  #  ERGO  advise AP these requirers are broke!
require 'rkelly/visitable'
require 'rkelly/nodes/node'
require 'rkelly/nodes/postfix_node'
require 'rkelly'
require 'assert2/xhtml'

module Test; module Unit; module Assertions

  class AssertRjs
    def initialize(js, scope)
      @ast = RKelly.parse(@js = js)
      @command = self.class.name.downcase.to_sym
      @scope = scope
    end

    attr_reader :command, :js, :passed, :scope

    def match(kode)
      @ast.pointcut(kode).matches.each do |updater|
        updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
          yield thang
        end
      end
    end

    class ALERT < AssertRjs
      def pwn matcher, &block
        match 'alert()' do |thang|
          text = thang.value.first
          text = eval(text.value)
          @passed = text =~ /#{matcher}/ or text.index(matcher.to_s)
          return text 
        end
        
        return nil
      end
    end
    
    class REPLACE_HTML < AssertRjs
      def pwn target, matcher, &block
        match 'Element.update()' do |thang|
          div_id, html = thang.value
          
          if target and html
            div_id = eval(div_id.value)
            html   = eval(html.value)
            
            if div_id == target.to_s
              cornplaint = "#{ command } for ID #{ target } has incorrect payload, in #{ js }"
              scope.assert_match matcher, html, cornplaint
              scope.assert_xhtml html, cornplaint, &block if block
              return html
            end
          end
        end
        return false
      end
    end
  end

  def assert_rjs(command, target, matcher = //, &block)
    klass = command.to_s.upcase
    rjs = eval("AssertRjs::#{klass}").new(js = @response.body, self)
    
#     command == :replace_html or  #  TODO  put me inside the method_missing!
#       flunk("assert_rjs's alpha version only respects :replace_html")
#   TODO  also crack out the args correctly and gripe if they wrong

    if command == :alert
      text = rjs.pwn(target)
      text or flunk("#{ command } not found in #{ js }")
      rjs.passed or flunk("#{ command } has incorrect payload. #{ target.inspect } should match #{ js }")
      return text
    else
      html = rjs.pwn(target, matcher, &block)
      html and return html
    end
    
    flunk "#{ command } for ID #{ target } not found in #{ js }"
  end

end; end; end