=begin
<code>assert{ 2.1 }</code> reinvents <code>assert{ 2.0 }</code> for <a href='http://www.ruby-lang.org/en/news/2007/12/25/ruby-1-9-0-released/' onclick='window.location.href = "http://www.ruby-lang.org/en/news/2007/12/25/ruby-1-9-0-released/";'>Ruby 1.9</a>.

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
             z --> "<span>=begin</span>"
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
require 'assert2/common/assert_flunk'

class Assert21Suite < Test::Unit::TestCase

  def setup
    @effect = Test::Unit::Assertions::RubyReflector.new()
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
    
    denigh{ x == 43 }  #  an alternate spelling, for smooth columns of code...
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
        add_diagnostic 'silly Rabbi!' and
        true
      end

    end

  end
#!end_panel!
=begin
<code>add_diagnostic{ '<em>block</em>' }</code>
Sometimes the diagnostic is more expensive than a passing assertion.
To keep all your assertions fast, wrap your diagnostics
in blocks. They only call when their assertions fail fail:
=end
  def test_add_diagnostic_lambda
    ark = ''
    assert_flunk /^remarkable/ do

      assert do
        add_diagnostic{ 'rem' + ark } and
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
=begin
Warning: Put Assertions on Separate Lines

FIXME  clearer example

<code>assert{}</code> works by exploiting marginal features in Ruby's internal parser.
To reflect source, assertions must find clean beginnings and endings to statements.

Do not, for example, put two assertions in one line, because the first one will 
confuse the second one:
=end
  def test_put_assertions_on_separate_lines
    assert_flunk /not like this/ do

      assert('not like this'){ deny{ true } }

    end
  end
#!end_panel!
=begin
What about Ruby 1.8.7?

<code>assert{ 2.0 }</code> uses RubyNode, which works with 1.8.6 and lower.
<code>assert{ 2.1 }</code> uses Ripper, which is built into Ruby 1.9.
Ruby 1.8.7 includes some backports from 1.9 that break the internal API that
RubyNode used. This means the <code>assert{ 2.0 }</code> project cannot support
a Ruby 1.8 greater than 1.8.6!

Those of you using a platform that automatically installed Ruby 1.8.7 can
use Keith Lancaster's blog entry, 
<a href='http://www.keith-lancaster.com/blog/?p=24'>"Installing RubyNode when using MacPorts"</a>, 
to recover some 1.8.6 stability!
=end
#!end_panel!
#!no_doc! ever again!

#  TODO  demonstrate writing tolerance() as an assertion motivator - emphasize DSL
#  TODO  do %w() with dark green on the delims, light green on the strings, and white on the gaps
#  TODO  the panels ought to stay open until closed
#  TODO  system to embolden a word in the documented panel!
#  TODO  demo test that explicates why we cannot allow the "money line" 
#            to appear inside assert{}

  def test_consume_diagnostic
    add_diagnostic 'silly Rabbi!'
    assert{ true }

    x = assert_flunk /true/ do
      denigh{ true }
    end

    deny('consume diagnostics at fault time'){ x =~ /silly Rabbi/ }
    add_diagnostic 'silly Rabbi'
    denigh{ false }

    x = assert_flunk /true/ do
          denigh{ true }
        end 
    deny('always consume diagnostics'){ x =~ /silly Rabbi/ }
  end

  def test_assert_args
    assert 'the irony /is/ lost on us!', 
              :args => [42] do |x|
      assert{ x == 42 }
    end
  end  #  FIXME  move all tests like these into assert2_utilities_suite.rb

  def test_assert_args_flunk
    assert_flunk /x.*--> 42/ do
      assert nil, :args => [42] do |x|
        x == 43
      end
    end
  end
  
  def test_deny_args_flunk
    assert_flunk /x.*--> 42/ do
      deny nil, :args => [42] do |x|
        x == 42
      end
    end
  end

  def test_trapped_faults_decorate_with_stack_traces
    return if RUBY_VERSION == '1.9.1'  # TODO
    assert_flunk __FILE__ do
      assert{ 1 / 0 }
    end
  end
  
  def daZone( whatever )
    add_diagnostic 'daybreak on the land'
    return nil
  end

  def test_daZone
    assert_flunk /daybreak on the land.*nested/m do
      assert{ daZone("string \"nested\"") }
    end

    message = assert_flunk /nested/ do
                assert{ daZone('string "nested"') }
              end
    deny{ message =~ /SyntaxError/ }
  end

  def test_extra_assertion_diagnostics_with_ripper
    tattle = "doc says what's the condition?"
    
    assert_flunk /the condition.*tattle/m do
      x = 43
      assert(tattle){ x == 42 }
    end

  end

  #  TODO  the =begin header can be multiple lines, down to a space!

end

