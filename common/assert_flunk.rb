require 'test/unit'

module Test; module Unit; module Assertions

  def assert_raise_message(types, matcher, message = nil, &block)
    args = [types].flatten + [message]
    exception = _assert_raise(*args, &block)
    matchee = exception.message
    
    if matcher.kind_of? String
        #  if we cosmetically strip leading spaces from both the matcher and matchee,
        #  then multi-line assert_flunk messages are easier on the eyes!
      matchee.gsub!(/^\s+/, '')
      matcher.gsub!(/^\s+/, '')
    end
  
    assert(message){ matchee.match(matcher) }  #  TODO  better diagnostic, already!
    return exception.message
  end

  FlunkError = if defined? Test::Unit::AssertionFailedError
                 Test::Unit::AssertionFailedError
               else
                 MiniTest::Assertion
               end

  def assert_flunk(matcher, message = nil, &block)
    assert_raise_message FlunkError, matcher, message, &block
  end

# TODO reinstall ruby-1.9.0 and pass all cross-tests!!

      def _assert_raise(*args)
#        _wrap_assertion do
          if Module === args.last
            message = ""
          else
            message = args.pop
          end
          exceptions, modules = args, [] # _check_exception_class(args)

          expected = args.size == 1 ? args.first : args
          actual_exception = nil
          full_message = build_message(message, "<?> exception expected but none was thrown.", expected)
          assert_block(full_message) do
            begin
              yield
            rescue Exception => actual_exception
              break
            end
            false
          end
          full_message = build_message(message, "<?> exception expected but was\n?", expected, actual_exception)
          assert_block(full_message) {exceptions.include?(actual_exception.class)}
          actual_exception
  #      end
      end

end; end; end

