require 'test/unit'
require File.dirname(__FILE__) + '/../../common_test_helper'
require 'pathname'

HomePath = (Pathname.new(__FILE__).dirname + '..').expand_path
Ruby186 = (HomePath + '../ruby1.8').expand_path

if RUBY_VERSION < '1.9.0'
  $:.unshift Ruby186 + 'lib'  #  reach out to ruby1.8's assert{ 2.0 }
else
  $:.unshift HomePath + 'lib'  #  reach out to ruby1.9's assert{ 2.1 }
  require 'ripdoc'
end

require 'assert2'
require 'assert2/common/assert_flunk'

#  FIXME  put the magic includer into a helper

class Assert2UtilitiesSuite < Test::Unit::TestCase

  def setup
    #~ @effect = Test::Unit::Assertions::RubyReflector.new()
    #~ array = [1, 3]
    #~ hash = { :x => 42, 43 => 44 }
    #~ x = 42
    #~ @effect.block = lambda{x}
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

  def test_flunking_assert_equal_inside_assert_decorates
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

