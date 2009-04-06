require 'rkelly/visitors'  #  ERGO  advise AP these requirers are broke!
require 'rkelly/visitable'
require 'rkelly/nodes/node'
require 'rkelly/nodes/binary_node'
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
      RKelly.parse(js).pointcut(kode).
          matches.each do |updater|
        updater.grep(RKelly::Nodes::ArgumentsNode).each do |thang|
          yield thang
        end
      end
    end

#  TODO  implement assert_no_rjs by upgrading scope to UnScope

    def complain(about)
      "#{ command } #{ about }\n#{ js }"
    end
    
    def flunk(about)
      scope.flunk(complain(about))
    end

    def match_or_flunk(why)  
      @matcher = @matcher.to_s if @matcher.kind_of?(Symbol)
      scope.assert_match @matcher, @text, complain(why)
    end

    def pwn_call *args, &block  #  TODO  use or reject the block
      target, matchers_backup = args[0], args[1..-1]
      
      match "#{target}()" do |thang|
        matchers = matchers_backup.dup
        
        thang.value.each do |arg|
          @text = eval(arg.value)
          @matcher = matchers.first # or return @text
          @matcher.to_s == @text or /#{ @matcher }/ =~ @text or break
          matchers.shift
        end
        
        matchers.empty? and 
          matchers_backup.length == thang.value.length and 
          return @text 
      end
      
      matchers = matchers_backup.inspect

      scope.flunk("#{ command } to #{ target } with arguments #{ 
                        matchers } not found in #{ js }")
    end

    class ALERT < AssertRjs
      def pwn *args, &block
        @command = :call
        pwn_call :alert, *args, &block
      end
    end

    class REMOVE < AssertRjs
      def pwn *args, &block
        @command = :call
        pwn_call 'Element.remove', *args, &block
      end
    end

    class CALL < AssertRjs
      def pwn *args, &block  #  TODO  use or reject the block
        pwn_call *args, &block
      end
    end

    class REPLACE_HTML < AssertRjs
      def pwn *args, &block
        target, @matcher = args
        @matcher ||= //
        
        match concept do |thang|
          div_id, html = thang.value
          
          if target and html
            div_id = eval(div_id.value)
            html   = html.value.gsub('\u003C', '<').
                                gsub('\u003E', '>')  #  ERGO  give a crap about encoding! 
            html   = eval(html)

            if div_id == target.to_s
              cornplaint = complain("for ID #{ target } has incorrect payload, in")
              scope.assert_match @matcher, html, cornplaint if @matcher
              scope.assert_xhtml html, cornplaint, &block if block
              return html
            end
          end
        end

        flunk "for ID #{ target } not found in"
      end
      def concept;  'Element.update()';  end
    end
    
    class REPLACE < REPLACE_HTML
      def concept;  'Element.replace()';  end
    end
  end

  def assert_rjs_(command, *args, &block)
    klass = command.to_s.upcase
    klass = eval("AssertRjs::#{klass}") rescue
      flunk("#{command} not implemented!")
    asserter = klass.new(@response.body, command, self)
    return asserter.pwn(*args, &block)
  end
    
#     command == :replace_html or  #  TODO  put me inside the method_missing!
#       flunk("assert_rjs's alpha version only respects :replace_html")
#   TODO  also crack out the args correctly and gripe if they wrong
#  TODO TDD the @matcher can be a string or regexp

end; end; end
