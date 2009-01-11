require File.dirname(__FILE__) + '/../../test_helper'


class Assert2Suite < Test::Unit::TestCase #:nodoc:

  def setup;  colorize(true);  end

  def test_catch_exceptions
    x = 42
    return unless RubyReflector::HAS_RUBYNODE

    assert_flunk /RuntimeError.*gotcha.*42/m do
      assert{ x; raise 'gotcha' }
    end

    assert_flunk /look out.*RuntimeError.*gotcha.*42/m do
      assert('look out!'){ x; raise 'gotcha' }
    end
  end

  def test_catch_undeniable_exceptions
    x = 42
    return unless RubyReflector::HAS_RUBYNODE

    assert_flunk /RuntimeError.*me_too.*42/m do
      denigh{ x; raise 'me_too' }
    end

    assert_flunk /tolja.*RuntimeError.*me_too.*42/m do
      deny('tolja'){ x; raise 'me_too' }
    end
  end

  def test_flunk_2_0
# FIXME    return unless RubyReflector::HAS_RUBYNODE
    x = 43
    assert_flunk /43.*but.*42/m    do  assert_equal x, 42           end
    assert_flunk /x == 42/         do  assert_{ x == 42 }           end
    assert_flunk /43.*expect.*43/m do  assert_not_equal x, 43       end
    assert_flunk /x > 43/          do  assert_{ x > 430 }           end
    assert_flunk /nope/            do  assert('nope'){ x > 430 }    end

    assert_flunk /x == 43.*should not.*x.*43/m do
      deny{ x == 43 }
    end

    assert_flunk /x.* > 43/ do  assert x > 430, 'x should be > 43'  end
  end

  def test_assert_yin_yang
    q = 41

    assert_yin_yang lambda{ q == 42 } do
      q += 1
    end

    deny_yin_yang lambda{ q == 42 } do
      q += 0
    end
  end

  def _(&block); lambda &block;  end

  def test_assert_yin_yang_postfix_style
    q = 41

    assert_yin_yang _{ q +=  1 },
                    _{ q == 42 }
  end

  def test_deny_yin_yang_postfix_style
    q = 41
    deny_yin_yang _{ q +=  0 },
                  _{ q == 41 }

    assert_flunk /fault before calling/ do
      deny_yin_yang _{ q +=  0 },
                    _{ q == 42 }
    end
  end

  def test_deny_multiple_yin_yangs
    q = 41
    whatever = 1
    deny_yin_yang _{ q +=  0 },
                  _{ q == 41 },
                  _{ whatever == 1 }
  end

  def test_assert_yin_yang_corn_plain
    q = 41

    assert_flunk /it broke!/ do
      assert_yin_yang _{ q +=  0 }, 'it broke!',
                      _{ q == 42 }
    end
  end

end
