require 'test/unit'
require 'assert2/ruby_reflector'

#  CONSIDER  fix if an assertion contains more than one command - reflect it all!

module Test; module Unit; module Assertions

  FlunkError = if defined? Test::Unit::AssertionFailedError
                 Test::Unit::AssertionFailedError
               else
                 MiniTest::Assertion
               end

  def add_diagnostic(whatever = nil, &block)
    @__additional_diagnostics ||= []
    
    if whatever == :clear
      @__additional_diagnostics = []
      whatever = nil
    end
    
    @__additional_diagnostics += [whatever, block]  # note .compact will take care of them if they don't exist
  end

  def __evaluate_diagnostics
    @__additional_diagnostics.each_with_index do |d, x|
      @__additional_diagnostics[x] = d.call if d.respond_to? :call
    end
  end  #  CONSIDER  pass the same args as blocks take?

  def __build_message(reflection)
    __evaluate_diagnostics
    return (@__additional_diagnostics.uniq + [reflection]).compact.join("\n")
  end  #  TODO  move this fluff to the ruby_reflector!

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

  module Coulor  #:nodoc:
    def colorize(we_color)
      @@we_color = we_color
    end
    unless defined? BOLD
      BOLD  = "\e[1m" 
      CLEAR = "\e[0m" 
    end       # ERGO  modularize these; anneal with Win32
    def colour(text, colour_code)
      return colour_code + text + CLEAR  if colorize?
      return text
    end
    def colorize?  #  ERGO  how other libraries set these options transparent??
      we_color = (@@we_color rescue true)  #  ERGO  parens needed?
      return false if ENV['EMACS'] == 't'
      return (we_color == :always or we_color && $stdout.tty?)
    end
    def bold(text)
      return BOLD + text + CLEAR  if colorize?
      return text
    end
    def green(text); colour(text, "\e[32m"); end
    def red(text); colour(text, "\e[31m"); end
    def magenta(text); colour(text, "\e[35m"); end
    def blue(text); colour(text, "\e[34m"); end
    def orange(text); colour(text, "\e[3Bm"); end
  end
  
  class RubyReflector
    attr_accessor :captured_block_vars,
                  :args

    include Coulor
    
    def split_and_read(called)
      if called =~ /([^:]+):(\d+):/
        file, line = $1, $2.to_i
        return File.readlines(file)[line - 1 .. -1]
      end
      
      return nil
    end
    
    def reflect_assertion(block, got)
      self.block = block
      
      extract_block.each do |statement|
        sender statement
      end
      
      inspection = got.pretty_inspect

      return format_assertion_result(assertion_source, inspection) + 
               format_captures
    end

    def format_inspection(inspection, spaces)
      spaces = ' ' * spaces
      inspection = inspection.gsub('\n'){ "\\n\" +\n \"" } if inspection =~ /^".*"$/
      inspection = inspection.gsub("\n"){ "\n" + spaces }
      return inspection.lstrip
    end

    def format_assertion_result(assertion_source, inspection)
      spaces = " --> ".length
      inspection = format_inspection(inspection, spaces)
      return assertion_source.rstrip + "\n --> #{inspection.lstrip}\n"
    end

    def format_capture(width, snip, value)
      return "#{ format_snip(width, snip) } --> #{ format_value(width, value) }"
    end

    def format_value(width, value)  #  TODO  width is a de-facto instance variable
      width += 4
      source = value.pretty_inspect
      source = source.split("\n").map{|snippet| ' ' * width + snippet }.join("\n")
      return source.lstrip
    end

    def measure_capture(kap)
      return kap.split("\n").inject(0){|x, v| v.strip.length > x ? v.strip.length : x } if kap.match("\n")
      kap.length
      # TODO  need the if?
    end

  end
  
  def colorize(to_color)
    RubyReflector.new.colorize(to_color)
  end

  #  TODO  work with raw MiniTest 

  # This is a copy of the classic assert, so your pre-existing
  # +assert+ calls will not change their behavior
  #
  if defined? MiniTest::Assertion 
    def assert_classic(test, msg=nil)
      msg ||= "Failed assertion, no message given."
      self._assertions += 1
      unless test then
        msg = msg.call if Proc === msg
        raise MiniTest::Assertion, msg
      end
      true
    end
    
    def add_assertion
      self._assertions += 1
    end
  else
    def assert_classic(boolean, message=nil)
      #_wrap_assertion do
        assert_block("assert<classic> should not be called with a block.") { !block_given? }
        assert_block(build_message(message, "<?> is not true.", boolean)) { boolean }
      #end
    end
  end

  #  The new <code>assert()</code> calls this to interpret
  #  blocks of assertive statements.
  #
  def assert_(diagnostic = nil, options = {}, &block)
    @__additional_diagnostics = []
    
    begin
      got = block.call(*options[:args]) and add_assertion and return got
    rescue FlunkError
      raise  #  asserts inside assertions that fail do not decorate the outer assertion
    rescue => got
      add_exception got
    end

    flunk diagnose(diagnostic, got, caller[1], options, block)
  end

  def add_exception(ex)
    ex.backtrace[0..10].each do |line|
      add_diagnostic '  ' + line
    end
  end

  #  This assertion replaces:
  #  
  #  - +assert_nil+
  #  - +assert_no_match+
  #  - +assert_not_equal+
  #
  #  It faults, and prints its block's contents and values,
  #  if its block returns non-+false+ and non-+nil+.
  #  
  def deny(diagnostic = nil, options = {}, &block)
      #  "None shall pass!" --the Black Knight
      
    @__additional_diagnostics = []
    
    begin
      got = block.call(*options[:args]) or (add_assertion and return true)
    rescue FlunkError
      raise
    rescue => got
      add_exception got
    end
  
    flunk diagnose(diagnostic, got, caller[0], options, block)
  end  #  "You're a looney!"  -- King Arthur

  alias denigh deny  #  to line assert{ ... } and 
                     #          denigh{ ... } statements up neatly!

end ; end ; end

