=begin
<code>xpath{}</code> tests XML and XHTML

<code>xpath{}</code> works closely with <code>assert{ 2.0</code> & <code>2.1 }</code> 
to provide elaborate, detailed, formatted reports when your XHTML code has
gone astray.

* 
#!link!assert_xhtml_xhtml!<code>assert_xhtml()</code>
absorbs your XHTML<br/>
* 
#!link!_assert_xml!<code>_assert_xml()</code>
absorbs your XML fragments<br/>
* TODO <code>_assert_xml()</code> absorbs your XML<br/>
* ...then 
#!link!xpath_path!<code>assert{ xpath() }</code>
scans it for details.<br/>
* you can program <code>xpath()</code> using XPath notation, or convenient 
#!link!xpath_DSL!Ruby option-hashes<br/>
* 
#!link!xpathtext!<code>xpath().text</code>
returns a copy of an XML node's (shallow) text contents<br/>
* 
#!link!Nested_xpath_Faults!assert{} and xpath()
work together to diagnose XHTML efficiently<br/>

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

  HomePath = (Pathname.new(__FILE__).dirname + '..').expand_path

class AssertXhtmlSuite < Test::Unit::TestCase

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
a node's string contents with <code>?.</code>:
=end
  def test_xpath_dsl
    assert_xhtml 'yo <a href="http://antwrp.gsfc.nasa.gov/apod/">apod</a> dude'
    assert do
      
      xpath :a, 
            :href => 'http://antwrp.gsfc.nasa.gov/apod/',
            ?. => 'apod'
            
    end
  end
#!end_panel!
=begin
<code>_assert_xml()</code>

Some versions of <code>assert_xhtml</code> fuss when
passed an XHTML fragment, or XML with some other schema. Use 
<code>_assert_xml()</code> to bypass those conveniences:
=end
  def test__assert_xml
    
   _assert_xml '<Mean><Woman>Blues</Woman></Mean>'
   
    assert{ xpath('/Mean/Woman').text == 'Blues' }
  end
#!end_panel!
=begin
=begin
<code>xpath().text</code>

<code>xpath()</code> returns a 
<a href='http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Node.html'><code>LibXML::XML::Node</code></a> object 
(or <code>nil</code> if it found none). The object has an additional method, <code>.text</code>,
which returns the nearest text contents:
=end
  def test_xpath_text
   _assert_xml '<Mean><Woman>Blues</Woman></Mean>'
    assert do
      
      xpath('/Mean/Woman').text == 'Blues'
      
    end
  end
#!end_panel!
=begin
Nested <code>xpath{}</code> Faults

When an inner <code>xpath{}</code> fails, the diagnostic's "xml context" 
contains only the inner XML. This prevents excessive spew when testing entire
web pages:
=end
  def _test_nested_xpath_faults
    assert_xhtml (HomePath + 'doc/assert_x.html').read
    
   # assert do
      p xpath(:'span[ . = "test_nested_xpath_faults" ]/../..')

    #end
    
#    deny  excessive spew
    
  end
#!end_panel!
=begin
<code>xpath( ?. )</code> Matches Recursive Text

When an XML node contains nodes with text, 
the XPath predicate <code>[ . = "..." ]</code> matches
all their text, concatenated together. <code>xpath()</code>'s 
DSL converts <code>?.</code> into that notation:
=end
  def test_nested_xpath_text
   _assert_xml '<boats><a>frig</a><b>ates</b></boats>'
    assert do
      xpath :boats, ?. => 'frigates'
    end
  end
#!end_panel!
#!no_doc!

        # TODO  inner_text should use ?.
        #  TODO  which back-ends support . = '' matching recursive stuff?
#  TODO  replace libxml with rexml in the documentation
# TODO  nest ' and " correctly - via node=REXML::XPath.first doc, '//lexeme[phrase/text()=$name]', {}, {"name"=>"n't"}

  def test_document_self
      #  TODO  use the title argument mebbe??
    doc = Ripdoc.generate(HomePath + 'test/assert_xhtml_suite.rb', 'assert{ xpath }')
    luv = HomePath + 'doc/assert_x.html'
    File.write(luv, doc)
    reveal luv, '#xpath_DSL'
  end
  
  def test_xpath_converts_symbols_to_ids
    _assert_xml '<a id="b"/>'
    assert{ xpath(:a, :b) == xpath('/a[ @id = "b" ]') }
  end

#  TODO  deal with horizontal overflow in panels!

  def test_xpath_converts_hashes_into_predicates
   _assert_xml '<a class="b"/>'
    expected_node = REXML::XPath.first(@xdoc, '/a[ @class = "b" ]')
    assert{ xpath(:a, :class => :b) == expected_node }
  end  #  TODO  use this in documentation

  def test_xpath_converts_silly_notation_to_text_matches
    _assert_xml '<a>b</a>'
    assert{ xpath(:a, :'.' => :b) == xpath('/a[ . = "b" ]') }
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

    spew = assert_flunk /xml context/ do
      deny{ xpath '/html/body' }
    end

    assert{ spew =~ /xpath: "\/html\/body"/ }
  end

#  TODO  put a test runner ta the bottom of assert_xhtml.rb

  def test_nested_diagnostics  #  TODO  put a test like this inside assert2_suite.rb
   _assert_xml '<a><b><c/></b></a>'
   
    diagnostic = assert_flunk 'xpath: "descendant-or-self::si"' do
      assert do
        xpath :a do
          xpath :b do
            xpath :si
          end
        end
      end
    end
    
    deny{ diagnostic.match('<a>') }
  end

  def test_deny_xpath
   _assert_xml '<foo/>'
    deny{ xpath :bar }
  end
        
  def test_nested_contexts
   _assert_xml '<a><b/></a>'
   
    assert do
      xpath :a do
        xpath :b do
          deny{ xpath :a }
        end
      end
    end
  end

  def test_deny_nested_diagnostics
   _assert_xml '<a><b><c/></b></a>'
   
    diagnostic = assert_flunk 'xpath: "descendant-or-self::si"' do
      deny do
        xpath :a do
          xpath :b do
            xpath :si
          end
        end
      end
    end
    
    deny{ diagnostic.match('<a>') }
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
    return # TODO
    assert_flunk "xml context:\n<html>\n  <body/>\n</html>" do
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




