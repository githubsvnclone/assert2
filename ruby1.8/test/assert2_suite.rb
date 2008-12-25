require 'test/unit'
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'assert2'
require 'assert2/common/assert_flunk'


class Assert_2_0_Test < Test::Unit::TestCase #:nodoc:

  def setup;  colorize(true);  end

  def test_assert_2_0
    x = 42
    assert{ x == 42 }
  end

  def test_assert_
    x = 42
    assert_{ x == 42 }
  end

  def test_deny_2_0
    x = 43
    deny{ x == 42 }
  end

  def test_catch_exceptions
    x = 42

    assert_flunk /RuntimeError.*gotcha.*42/m do
      assert{ x; raise 'gotcha' }
    end

    assert_flunk /look out.*RuntimeError.*gotcha.*42/m do
      assert('look out!'){ x; raise 'gotcha' }
    end
  end

  def test_catch_undeniable_exceptions
    x = 42

    assert_flunk /RuntimeError.*me_too.*42/m do
      denigh{ x; raise 'me_too' }
    end

    assert_flunk /tolja.*RuntimeError.*me_too.*42/m do
      deny('tolja'){ x; raise 'me_too' }
    end
  end

  def test_flunk_2_0
    x = 43
    assert_flunk /43.*but.*42/m    do  assert_equal x, 42           end
    assert_flunk /x == 42/         do  assert_{ x == 42 }           end
    assert_flunk /43.*expect.*43/m do  assert_not_equal x, 43       end
    assert_flunk /x > 43/          do  assert_{ x > 430 }           end
    assert_flunk /nope/            do  assert('nope'){ x > 430 }    end
    assert_flunk /x == 43.*should not.*x.*43/m do  deny{ x == 43 }  end
    assert_flunk /x.* > 43/ do  assert x > 430, 'x should be > 43'  end
  end

  def test_assert_classic
    x = 41
    assert_flunk /false/   do  assert x == 42             end
    assert_flunk /message/ do  assert x == 42, 'message'  end
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

  #############################################################
  ######## for manual tests

  def create_topics
    return { 'first' => 'wrong topic' }
  end

# FIXME
#> * you shouldn't use "+" for string concatenation, it is much faster to
#> use "<<" instead
#
#Noted!
#
#> * rescue with else does not work:
#>
#>>> puts(reflect_source { begin 1; rescue Foo;2;else;3;end })
#> begin
#> 13rescue Foo
#> 2
#> end

#> * flip2 and flip3 are for rubys flip-flop operator
#> (http://redhanded.hobix.com/inspect/hopscotchingArraysWithFlipFlops.html)

  #  use these to manually test the diagnostic failures
  #
  def test_topics
    topics = create_topics
    x = 43
#    assert{ x == 42 }
#    deny{ x == 43 }
#    assert_equal 'a topic', topics['first']
#    assert{ 'a topic' == topics['first'] }
#    assert_not_nil topics['second']
#    assert_{ topics['second'] }
  end

end
