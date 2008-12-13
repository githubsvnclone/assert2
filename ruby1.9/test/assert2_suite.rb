=begin
<code>assert{ 2.1 }</code> reinvents <code>assert{ 2.0 }</code> for Ruby 1.9.

<code>assert{ 2.0 }</code> is the industry's most aggressive TDD 
system&mdash;for Ruby, or any other language. Each time it fails, it analyzes the 
reason and presents a complete, formatted report. This makes the cause very
easy to rapidly identify and fix. <code>assert{ 2.0 }</code> is like a 
debugger's "inspect variable" system, and it makes your TDD cycle more
effective.

Here's an example of the output diagnostic when <code>assert{ 2.1 }</code> 
fails. The first line reflects the source of the entire assertion:

     assert{ z =~ /=begon/ } # complete with comments
  --> nil
             z --> "<span style=\"display: none;\">=begin</span>"
 z =~ /=begon/ --> nil.

The second line, <code>--> nil</code>, is the return value of the asserted expression.
The next lines contain the complete source and re-evaluation of each
terminal (<code>z</code>) and expression (<code>z =~ /=begon/</code>) in the assertion's block.

The diagnostic lines are formatted to scan easily, and they use "<code>pretty_inspect()</code>"
to wrap complex outputs. The diagostic contains the name and value of every variable and
expression in the asserted block.

These simple techniques free your assertions from restricting patterns, such 
as <code>assert_equal()</code> or 
<code>assert_match()</code> (or their syntax-sugary equivalents!).
The more creative your assertions, the more elaborate their diagnostics.
=end
#!end_panel!
=begin
Installation

   gem install assert2   <em># for Ruby 1.8, via RubyNode</em>
  gem install assert21  <em># for Ruby 1.9, via Ripper (comes with Ruby)</em>

Then place <code>require 'assert2'</code> (for either package) above your tests.
=end
#!end_panel!
#!no_doc!
require 'test/unit'
$:.unshift 'lib'; $:.unshift '../lib'
require 'assert2'
require 'common/assert_flunk'

class Assert2Suite < Test::Unit::TestCase

  def setup
    @effect = Test::Unit::Assertions::AssertionRipper.new()
    array = [1, 3]
    hash = { :x => 42, 43 => 44 }
    x = 42
    @effect.block = lambda{x}
  end

#!doc!
=begin
<code>assert{ <em>boolean expression</em> }</code> and Fault Diagnostics
This test uses a semi-private assertion, <code>assert_flunk()</code>,
to detect that when <code>assert{ 2.0 }</code> fails, it prints out a diagnostic
containing the assertion's variables and values:
=end
  def test_assert_reflects_your_expression_in_its_fault_diagnostic
    x = 42
    assert_flunk '      assert{ x == 43 }  #  even comments reflect!
                   --> false
                        x --> 42
                  x == 43 --> false' do

      assert{ x == 43 }  #  even comments reflect!

    end
  end
#!end_panel!
=begin
<code>deny{ <em>boolean expression</em> }</code>
This shows <code>assert{}</code>'s arch-nemesis, 
<code>deny{}</code>. Use it when your programs
are too cheerful and happy, to bring them down:
=end
  def test_deny_reflects_your_expression_in_its_fault_diagnostic
    x = 42
    assert_flunk '      deny{ x == 42 }
                   --> true
                        x --> 42
                  x == 42 --> true' do

      deny{ x == 42 }

    end
    
    denigh{ x == 43 }  #  an alternative spelling, for smooth columns of code...
  end
#!end_panel!
=begin
<code>assert('<em>extra spew</em>'){ <em>boolean...</em> }</code>
<code>assert{}</code> and <code>deny{}</code> take an optional first argument&mdash;a
string. At fault time, this appears in the output diagnostic, above all other spew:
=end
  def test_diagnostic_string
    x = 42
    assert_flunk 'medium rare' do
      
      assert('medium rare'){ x == 43 }
      
    end
  end
#!end_panel!
=begin
<code>add_diagnostic '<em>extra spew</em>'</code>
This test shows how to add extra diagnostic information to an assertion.

Custom test-side methods which know they are inside
<code>assert{}</code> and <code>deny{}</code> blocks
can use this to explain what's wrong with some situation.
=end
  def test_add_diagnostic
    
    assert_flunk /silly Rabbi!/ do
      
      deny do
        add_diagnostic 'silly Rabbi!'
        true
      end
      
    end
    
  end
#!end_panel!
=begin
<code>add_diagnostic{ '<em>block</em>' }</code>
Sometimes the diagnostic is more expensive than the actual assertion.
To keep all your assertions fast, wrap your diagnostics
in blocks. They only call when their assertions fail fail:
=end
  def test_add_diagnostic_lambda
    ark = ''
    assert_flunk /^remarkable/ do
      
      assert do
        add_diagnostic{ 'rem' + ark }
        ark = 'arkable'
        false
      end
      
    end
  end
#!end_panel!
=begin
Classic <code>assert( <em>boolean</em> )</code>
<code>assert{}</code> will pass thru to the original <code>assert()</code>
from <code>Test::Unit::TestCase</code>. When you drop <code>require 'assert2'</code>
into your tests, all your legacy <code>assert()</code> calls will still perform
correctly:
=end
  def test_assert_classic
    assert_flunk /(false. is not true)|(Failed assertion)/ do
      
      assert false
      
    end
  end
#!end_panel!
=begin
Error Handling
<code>assert{}</code> interprets program errors and decorates their diagnostics:
=end
  def test_error_handling
    assert_flunk /ZeroDivisionError: divided by 0/ do
      
      assert{ 1 / 0 }  # would you believe some math professors frown upon that?!
      
    end
  end
#!end_panel!
#!no_doc! ever again!

#  TODO  demonstrate writing tolerance() as an assertion motivator - emphasize DSL
#  TODO  do %w() with dark green on the delims, light green on the strings, and white on the gaps
#  TODO  the panels ought to stay open until closed
#  TODO  system to embolden a word in the documented panel!
#  TODO  demo test that explicates why we cannot allow the "money line" 
#            to appear inside assert{}
# TODO  document rubynode does not work for 1.8.7

end

