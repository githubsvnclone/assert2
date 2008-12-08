require 'test/unit'

module Test; module Unit; module Assertions

  # This is a copy of the classic assert, so your pre-existing
  # +assert+ calls will not change their behavior
  #
  if self.respond_to? :_assertions
    def assert_classic(test, msg=nil)
        msg ||= "Failed assertion, no message given."
        self._assertions += 1
        unless test then
          msg = msg.call if Proc === msg
          raise MiniTest::Assertion, msg
        end
        true
    end
  else
    def assert_classic(boolean, message=nil)
      _wrap_assertion do
        assert_block("assert<classic> should not be called with a block.") { !block_given? }
        assert_block(build_message(message, "<?> is not true.", boolean)) { boolean }
      end
    end
  end

  def add_diagnostic(whatever = nil, &block)
    @__additional_diagnostics ||= []
    
    if whatever == :clear
      @__additional_diagnostics = []
      whatever = nil
    end
    
    @__additional_diagnostics << whatever if whatever
    @__additional_diagnostics << block if block
  end

  def __evaluate_diagnostics
    @__additional_diagnostics.each_with_index do |d, x|
      @__additional_diagnostics[x] = d.call if d.respond_to? :call
    end
  end  #  TODO  pass the same args as blocks take
      #  TODO  recover from errors?
      #  TODO  add a stack trace when assert{} or deny{} rescue

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
    if block
      assert_ *args, &block
    else
      assert_classic *args
    end
    return true # or die trying ;-)
  end

  alias denigh deny  #  to line assert{ ... } and 
                     #          denigh{ ... } statements up neatly!

end ; end ; end

