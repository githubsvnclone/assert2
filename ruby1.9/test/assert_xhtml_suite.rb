=begin
<code>xpath{}</code> tests XML and XHTML

<code>xpath{}</code> works closely with <code>assert{ 2.0</code> & <code>2.1 }</code> 
to provide elaborate, detailed, formatted reports when your XHTML code has
gone astray.
<ul>
<li>* <a href='#assert_xhtmlemxhtmlemcode'><code>assert_xhtml()</code></a> absorbs your XHTML</li>
<li>* <code>_assert_xml()</code> absorbs your XML</li>
<li>* Then <code>assert{ xpath() }</code> scans it</li>
</ul>
=end
#!end_panel!
#!no_doc!
require 'test/unit'
$:.unshift 'lib'; $:.unshift '../lib'
require 'assert2'
require 'ripdoc'
require 'common/assert_flunk'
require 'assert_xhtml'
require 'pathname'

  HomePath = (Pathname.new(__FILE__).dirname + '..').expand_path #  TODO  unify

class AssertXhtmlSuite < Test::Unit::TestCase

  def test_document_self
      #  TODO  use the title argument mebbe??
    doc = Ripdoc.generate(HomePath + 'test/assert_xhtml_suite.rb', 'assert{ xpath }')
    luv = HomePath + 'doc/assert_xhtml.html'
    File.write(luv, doc)
    reveal luv, '#codexpathemDSLemcode'
  end
#!doc!
=begin
<code>assert_xhtml( <em>xhtml</em> )</code>
Use this method to push well-formed XHTML into the assertion system. Subsequent
<code>xpath()</code> calls will interrogate this XHTML, using XPath notation:
=end
  def test_assert_xhtml
    
    assert_xhtml '<html><body><div id="forty_two">yo</div></body></html>'
    
    assert{ xpath('//div[ @id = "forty_two" ]').text == 'yo' }
  end
#!end_panel!
=begin
<code>xpath( '<em>path</em>' )</code>

=end
  def test_assert_xpath
    assert_xhtml '<html><body><div id="forty_two">yo</div></body></html>'
    
    assert{ xpath('descendant-or-self::div[ @id = "forty_two" ]').text == 'yo' }
    assert{ xpath('//div[ @id = "forty_two" ]').text == 'yo' }
    assert{ xpath(:'div[ @id = "forty_two" ]').text == 'yo' }
    assert{ xpath(:div, :forty_two).text == 'yo' }
  end
#!end_panel!
=begin
<code>xpath( <em>DSL</em> )</code>
You can write simple XPath queries using Ruby's familiar hash notation. Query
a node's string contents with <code>:'.'</code>:
=end
  def test_xpath_dsl
    assert_xhtml 'yo <a href="http://antwrp.gsfc.nasa.gov/apod/">apod</a> dude'
    
    assert do
      xpath :a, 
            :href => 'http://antwrp.gsfc.nasa.gov/apod/',
            :'.' => 'apod'
    end
  end  #  TODO  take off the : use .? ?
#!no_doc!
  def test_xpath_converts_symbols_to_ids
    _assert_xml '<a id="b"/>'
    assert{ xpath(:a, :b) == @xdoc.find_first('/a[ @id = "b" ]') }
  end

#  TODO  deal with horizontal overflow in panels!

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
    return if RUBY_VERSION > '1.8.6'  #  TODO fix!
    assert_xhtml '<html><body/></html>'

    spew = assert_flunk /xpath context/ do
      deny{ xpath '/html/body' }
    end

    assert{ spew =~ /xpath: "\/html\/body"/ }
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
  end

  def test_xpath_takes_both_a_symbolic_id_and_options
   _assert_xml '<div id="zone" foo="bar">yo</div>'
    assert{ xpath(:div, :zone, {}).text == 'yo' }
    assert{ xpath(:div, :zone, :foo => :bar).text == 'yo' }
  end

  def test_failing_xpaths_indent_their_returnage
    return if RUBY_VERSION < '1.9' # TODO  fix!
    assert_xhtml '<html><body/></html>'
    
    assert_flunk "xpath context:\n<html>\n  <body/>\n</html>" do
      assert{ xpath('yack') }
    end
  end

  def reveal(filename, anchor)
    # File.write('yo.html', xhtml)
#    system 'konqueror yo.html &'
    path = filename.relative_path_from(Pathname.new(Dir.pwd)).to_s.inspect
    system '"C:/Program Files/Mozilla Firefox/firefox.exe" ' + path + anchor + ' &'
  end
  
end







