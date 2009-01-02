require File.dirname(__FILE__) + '/../../test_helper'


class Assert2UtilitiesSuite < Test::Unit::TestCase

  def setup
    colorize(false)
  end

  def test_assert
    assert_flunk /x == 42.*false.*x \s*--> 43/m do
      x = 43
      assert{ x == 42 }
    end
  end

  def test_deny_everything
    assert_flunk /x.*true.*\s+--> 42/m do
      x = 42
      deny{ x == 42 }
    end
  end

  def test_assert_classic
    assert_flunk /(false. is not true)|(Failed assertion)/ do
      assert false
    end
  end

  def test_assert_decorates_no_flunks
    complaint = assert_flunk /expected but was/ do
                  assert 'fat chance - we ain\'t Perl!' do
                    assert_equal '42', 42
                  end
                end
    deny{ complaint =~ /fat chance/ }
  end

  def test_multi_line_assertion    
    return if RUBY_VERSION == '1.9.1'  # TODO
    assert_flunk /false.*nil/m do
      assert do
        false
        42; nil
      end
    end
  end
  
  def test_assertion_diagnostics
    tattle = "doc says what's the condition?"
    
    assert_flunk /the condition/ do
      x = 43
      assert(tattle){ x == 42 }
    end

    assert_flunk /on a mission/m do
      x = 42
      deny("I'm a man that's on a mission"){ x == 42 }
    end
  end
  
  def morgothrond(thumpwhistle)
    return false  #  what did you think such a function would do?? (-:
  end
  
  def test_morgothrond_thumpwhistle
    thumpwistle = 42
    
    x = assert_raise FlunkError do
      assert{ self.morgothrond(thumpwistle) }
    end
    
    assert{ x.message =~ /thumpwistle\s+--> 42/ }
    denigh{ x.message =~ /self.morgothrond\s+--> / }
  end

  def test_assert_diagnose
    x = 42

    assert do
      add_diagnostic{ flunk 'this should never call' } and
      x == 42
    end
  end

  def test_assert_diagose_flunk
    expected = 42
    x = 43

    assert_flunk /^you ain.t #{expected}/ do
      assert do
        add_diagnostic{ "you ain't #{expected}" }
        x == expected
      end
    end
  end

  def test_deny_diagnose
    x = 42
    
    deny do
      add_diagnostic{ flunk 'this should never call' } and
      x == 43
    end
  end

  def test_deny_diagose_flunk
    expected = 42
    x = 42

    assert_flunk /^you ain.t #{expected}/ do
      deny do
        add_diagnostic{ "you ain't #{expected}" } and
        x == expected
      end
    end
  end

  def test_asserts_see_arguments
    x = 42
    assert :args => [42] do |val|
      x == 42
    end
  end

  def test_assert_args
    assert 'the irony /is/ lost on us!',
              :args => [42] do |x|
      assert{ x == 42 }
    end
  end

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
    return if RUBY_VERSION == '1.9.1'  # FIXME
    assert_flunk __FILE__ do
      assert{ 1 / 0 }
    end
  end

  def test_format_inspection
    rf = RubyReflector.new
    assert{ rf.format_inspection('foo'.inspect, 42) == '"foo"' }
  end

  def test_format_multiline_inspection
    rf = RubyReflector.new
    assert{ rf.format_inspection("foo\nbar", 42) =~ /foo\n\s{42}bar/ }
  end

  def test_format_literal_multiline_inspection
    rf = RubyReflector.new
    return # FIXME
    assert{ rf.format_inspection("foo\\nbar", 42) =~ /foo\n\s{42}bar/ }
  end

end  #  TODO  ultimately, the top of _this_ file should document all of assert{ 2.x }

