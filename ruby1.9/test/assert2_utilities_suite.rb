require 'test/unit'
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
    #~ @effect = Test::Unit::Assertions::AssertionRipper.new()
    #~ array = [1, 3]
    #~ hash = { :x => 42, 43 => 44 }
    #~ x = 42
    #~ @effect.block = lambda{x}
    colorize(false) if defined? colorize
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


end

