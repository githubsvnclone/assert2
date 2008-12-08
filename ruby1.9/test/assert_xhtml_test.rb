require 'test/unit'
$:.unshift 'lib'; $:.unshift '../lib'
require 'assert2'
require 'common/assert_flunk'
require 'assert_xhtml'

class AssertXhtmlSuite < Test::Unit::TestCase

  def test_assert_xhtml
    assert_xhtml '<html><body><div id="forty_two">yo</div></body></html>'
    assert{ xpath('descendant-or-self::div[ @id = "forty_two" ]').text == 'yo' }
    assert{ xpath(:'div[ @id = "forty_two" ]').text == 'yo' }
    assert{ xpath(:div, :forty_two).text == 'yo' }
  end
  
  def test_xpath_converts_symbols_to_ids
    _assert_xml '<a id="b"/>'
    assert{ xpath(:a, :b) == @xdoc.find_first('/a[ @id = "b" ]') }
  end

  def test_xpath_converts_hashes_into_predicates
    _assert_xml '<a class="b"/>'
    assert{ xpath(:a, :class => :b) == @xdoc.find_first('/a[ @class = "b" ]') }
  end

  def test_xpath_converts_silly_notation_to_text_matches
    _assert_xml '<a>b</a>'
    assert{ xpath(:a, :'.' => :b) == @xdoc.find_first('/a[ . = "b" ]') }
  end

  def test_xpath_wraps_assert
    return if RUBY_VERSION < '1.9' # TODO  fix!
    assert_xhtml '<html/>'

    assert_flunk /node.name --> "html"/ do
      xpath '/html' do |node|
        node.name != 'html'
      end
    end
  end

  def test_deny_xpath_decorates
    assert_xhtml '<html><body/></html>'

    spew = assert_flunk /xpath context/ do
      deny{ xpath '/html/body' }
    end
    puts spew
  end

  def test_to_predicate_expects_options
    args = AssertXPathArguments.new
    assert{ args.to_predicate(:zone, {}) == "[ @id = 'zone' ]" }
    predicate = args.to_predicate(:zone, :foo => :bar)

    assert{
      predicate.index('[ ') == 0 and
      predicate.match("@id = 'zone'") and
      predicate.match(" and ")        and
      predicate.match("@foo = 'bar'") and
      predicate.match(/ \]$/)
    }
  end #  TODO  reflect the generated path in the fault diagnostic

  def test_xpath_takes_both_a_symbolic_id_and_options
    _assert_xml '<div id="zone" foo="bar">yo</div>'
    assert{ xpath(:div, :zone, {}).text == 'yo' }
    assert{ xpath(:div, :zone, :foo => :bar).text == 'yo' }
  end

#  TODO  scratch the add_diagnostics if we can rescue flunks, decorate them, and re-raise them

  def test_failing_xpaths_indent_their_returnage
    return if RUBY_VERSION < '1.9' # TODO  fix!
    assert_xhtml '<html><body/></html>'
    
    assert_flunk "xpath context:\n<html>\n  <body/>\n</html>" do
      assert{ xpath('yack') }
    end
  end

  def reveal(xhtml = @sauce || @output)
    File.write('yo.html', xhtml)
#    system 'konqueror yo.html &'
    system '"C:/Program Files/Mozilla Firefox/firefox.exe" yo.html &'
  end
  
end















