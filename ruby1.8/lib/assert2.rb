# this is assert{ 2.0 }, for Ruby <= 1.8.6


module Test; module Unit; module Assertions

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
  
end ; end ; end  #  "Eagle-eyes it!"


