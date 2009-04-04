require 'rkelly/visitors'  #  ERGO  advise AP these requirers are broke!
require 'rkelly/visitable'
require 'rkelly/nodes/node'
require 'rkelly/nodes/postfix_node'
require 'rkelly'
require 'assert2/xhtml'

module Test; module Unit; module Assertions

  class AssertRjs
    def initialize(js, command, scope)
      @js, @command, @scope = js, command, scope
    end

    attr_reader :command, :js, :scope

    def match(kode)
      ast = RKelly.parse(@js = js)
      
      ast.pointcut(kode).matches.each do |updater|
        updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
          yield thang
        end
      end
    end

    def complain(about)
      "#{ command } #{ about }\n#{ js }"
    end
    
    def flunk(about)
      scope.flunk(complain(about))
    end

    class ALERT < AssertRjs
      def pwn target, matcher, &block
        matcher = target

        match 'alert()' do |thang|
          text = thang.value.first
          text = eval(text.value)
          
          text =~ /#{matcher}/ or 
            text.index(matcher.to_s) or
            flunk("has incorrect payload. #{ matcher.inspect } should match #{ text }, in")
            
          return text 
            #  TODO  find any alert with the given payload not just the first
        end
        
        scope.flunk("#{ command } not found in #{ js }")
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
              cornplaint = complain("for ID #{ target } has incorrect payload, in")
              scope.assert_match matcher, html, cornplaint
              scope.assert_xhtml html, cornplaint, &block if block
              return html
            end
          end
        end

        scope.flunk "#{ command } for ID #{ target } not found in #{ js }"
      end
    end
  end

  def assert_rjs(command, target, matcher = //, &block)
    klass    = command.to_s.upcase
    asserter = eval("AssertRjs::#{klass}").new(@response.body, command, self)
    return asserter.pwn(target, matcher, &block)
  end
    
#     command == :replace_html or  #  TODO  put me inside the method_missing!
#       flunk("assert_rjs's alpha version only respects :replace_html")
#   TODO  also crack out the args correctly and gripe if they wrong
#  TODO TDD the matcher can be a string or regexp

end; end; end