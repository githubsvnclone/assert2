require File.dirname(__FILE__) + '/../../test_helper'


class Assert2Suite < Test::Unit::TestCase #:nodoc:

  def setup;  colorize(true);  end

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
