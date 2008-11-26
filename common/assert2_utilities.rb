require 'test/unit/assertions'

module Test; module Unit; module Assertions

  def add_diagnostic(whatever)
    @__additional_diagnostics ||= []
    
    if whatever == :clear
      @__additional_diagnostics = []
    else
      @__additional_diagnostics << whatever if whatever
    end
  end

  def assert(*args, &block)
  #  This assertion calls a block, and faults if it returns
  #  +false+ or +nil+. The fault diagnostic will reflect the
  #  assertion's complete source - with comments - and will
  #  reevaluate the every variable and expression in the
  #  block.
  #
  #  The first argument can be a diagnostic string:
  #
  #    assert("foo failed"){ foo() }
  #
  #  The fault diagnostic will print that line.
  # 
  #  The next time you think to write any of these assertions...
  #  
  #  - +assert+
  #  - +assert_equal+
  #  - +assert_instance_of+
  #  - +assert_kind_of+
  #  - +assert_operator+
  #  - +assert_match+
  #  - +assert_not_nil+
  #  
  #  use <code>assert{ 2.1 }</code> instead.
  #
  #  If no block is provided, the assertion calls +assert_classic+,
  #  which simulates RubyUnit's standard <code>assert()</code>.
  #  
  #  Note: This only works for Ruby 1.9, because it uses the Ripper library,
  #  maintained by Ruby's core team.
  #
    if block
      assert_ *args, &block
    else
      assert_classic *args
    end
    return true # or die trying ;-)
  end

  # This is a copy of the classic assert, so your pre-existing
  # +assert+ calls will not change their behavior
  #
  def assert_classic(boolean, message=nil)
    _wrap_assertion do
      assert_block("assert<classic> should not be called with a block.") { !block_given? }
      assert_block(build_message(message, "<?> is not true.", boolean)) { boolean }
    end
  end

end ; end ; end

