require 'test/unit'
require File.dirname(__FILE__) + '/../../test_helper'
require 'assert2/common/assert_flunk'


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

end

