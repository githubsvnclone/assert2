# this is assert{ 2.0 }, for Ruby <= 1.8.6

if RUBY_VERSION > '1.8.6'
  puts "\nWarning: This version of assert{ 2.0 } requires\n" +
       "RubyNode, which only works on Ruby versions < 1.8.7.\n" +
       "Upgrade to Ruby1.9, and try 'gem install assert21'\n\n"
end

require 'assert2/common/assert2_utilities'

#  TODO  evaluate parts[3]
#  ERGO  if the block is a block, decorate with do-end
#  ERGO  decorate assert_latest's block at fault time


module Test; module Unit; module Assertions

  # Assert that a block raises a given Exception type matching 
  # a given message
  # 
  # * +types+ - single exception class or array of classes
  # * +matcher+ - Regular Expression to match the inner_text of XML nodes
  # * +diagnostic+ - optional string to add to failure message
  # * +block+ - Ruby statements that should raise an exception
  #
  # Examples:
  # %transclude AssertXPathSuite#test_assert_raise_message_detects_assertion_failure
  #
  # %transclude AssertXPathSuite#test_assert_raise_message_raises_message
  #
  # See: {assert_raise - Don't Just Say "No"}[http://www.oreillynet.com/onlamp/blog/2007/07/assert_raise_on_ruby_dont_just.html]
  #
  def assert_raise_message(types, matcher, diagnostic = nil, &block)
    args = [types].flatten + [diagnostic]
    exception = assert_raise(*args, &block)
    
    assert_match matcher,  #  TODO  merge this stuff into the utilities
                 exception.message,
                 [ diagnostic, 
                   "incorrect #{ exception.class.name 
                     } message raised from block:", 
                   "\t"+reflect_source(&block).split("\n").join("\n\t")
                   ].compact.join("\n")

    return exception
  end

  def deny_raise_message(types, matcher, diagnostic = nil, &block) #:nodoc:
    exception = assert_raise_message(types, //, diagnostic, &block)
    
    assert_no_match matcher,
                 exception.message,
                 [ diagnostic, 
                   "exception #{ exception.class.name 
                     } with this message should not raise from block:", 
                   "\t"+reflect_source(&block).split("\n").join("\n\t")
                   ].compact.join("\n")
    
    return exception.message
  end

  #~ def assert_flunked(gripe, diagnostic = nil, &block) #:nodoc:
    #~ assert_raise_message Test::Unit::AssertionFailedError,
                         #~ gripe,
                         #~ diagnostic,
                        #~ &block
  #~ end

  def deny_flunked(gripe, diagnostic = nil, &block) #:nodoc:
    deny_raise_message Test::Unit::AssertionFailedError,
                       gripe,
                       diagnostic,
                      &block
  end  #  ERGO  move to assert{ 2.0 }, reflect, and leave there!

  # This is a copy of the classic assert, so your pre�xisting
  # +assert+ calls will not change their behavior
  #
  def assert_classic(boolean, message=nil)
    _wrap_assertion do
      assert_block("assert<classic> should not be called with a block.") { !block_given? }
      assert_block(build_message(message, "<?> is not true.", boolean)) { boolean }
    end
  end
  
  #  wrap this common idiom:
  #    foo = assemble()
  #    deny{ foo.bar() }
  #    foo.activate()
  #    assert{ foo.bar() }
  #
  #  that becomes:
  #    foo = assemble()
  #
  #    assert_yin_yang proc{ foo.bar() } do
  #      foo.activate()
  #    end
  #
  def assert_yin_yang(*args, &block)
      # prock(s), diagnostic = nil, &block)
    procks, diagnostic = args.partition{|p| p.respond_to? :call }
    block ||= procks.shift
    source = reflect_source(&block)
    fuss = [diagnostic, "fault before calling:", source].compact.join("\n")
    procks.each do |prock|  deny(fuss, &prock);  end
    block.call
    fuss = [diagnostic, "fault after calling:", source].compact.join("\n")
    procks.each do |prock|  assert(fuss, &prock);  end
  end

  #  the prock assertion must pass on both sides of the called block
  #
  def deny_yin_yang(*args, &block)
      # prock(s), diagnostic = nil, &block)
    procks, diagnostic = args.partition{|p| p.respond_to? :call }
    block ||= procks.shift
    source = reflect_source(&block)
    fuss = [diagnostic, "fault before calling:", source].compact.join("\n")
    procks.each do |prock|  assert(fuss, &prock);  end
    block.call
    fuss = [diagnostic, "fault after calling:", source].compact.join("\n")
    procks.each do |prock|  assert(fuss, &prock);  end
  end

end ; end ; end  #  "Eagle-eyes it!"


