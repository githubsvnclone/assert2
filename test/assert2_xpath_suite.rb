=begin
<code>xpath{}</code> tests XML and XHTML

<code>xpath{}</code> works closely with 
<a href='http://assert2.rubyforge.org/assert21.html'><code>assert{ 2.0 }</code></a>
to provide elaborate, detailed, formatted reports when your XHTML code has
gone astray.
=end
#!end_panel!
=begin
Installation

<code>xpath{}</code> bundles with <code>assert{ 2.0 }</code>
and <code>assert{ 2.1 }</code>. 
<a href='http://assert2.rubyforge.org/assert21.html#Installation'>Install</a> 
one of them first, then 

 require 'assert2/xpath'

That also imports <code>assert{ 2.0 }</code>.
=end
#!end_panel!
=begin
Strategy

First, generate your XHTML, then pass it into 
#!link!assert_xhtml_xhtml!<code>assert_xhtml()</code>
. Use
#!link!_assert_xml!<code>_assert_xml()</code>
if all you have is a fragment of XHTML, or XML from some other schema.

Use a call like <code>title = xpath('/html/head/title')</code> 
alone, without <code>assert{}</code>, to
extract XML nodes non-judgementally. It returns a <code>nil</code>
when it fails. The returned node will provide
#!link!xpathtext!text
and
#!link!xpath_Attribute_Accessors!attribute
helper methods.

To learn XPath, read
"<a href='http://www.oreillynet.com/onlamp/blog/2007/08/xpath_checker_and_assert_xpath.html'>XPath
Checker and assert_xpath</a>", and attach an XPath tool like XPath Checker or XPather to your Firefox
web browser.

Then wrap your <code>xpath()</code> calls in <code>assert{}</code> to
verify their details. For example, if your production code generates a 
<code><form></code> with a useful edit field in it, you can 
#!link!xpath_path!capture
the
field like this:

  assert{ xpath('//input[ @type = "text" and @name = "user" and 
                             @value = "Roosevelt Franklin" ]') }

You can program <code>xpath()</code> using XPath notation, or convenient 
Ruby option-hash 
#!link!xpath_DSL!notation.
The equivalent query is:

  assert{ xpath(:input, :type => :text, :name => :user", 
                             :value => 'Roosevelt Franklin') }

When these assertions fail, <code>xpath()</code> works closely with
<code>assert{}</code> to present a detailed, formatted, readable report
of the XML node that failed, and its relevant context within a document.

<code>xpath{}</code> can evaluate a block; if this contains more
<code>xpath()</code> calls, they
#!link!Nested_xpath!nest
inside the outer <code>xpath{}</code>'s context. This lets you skip
over irrelevant details in a document, and only test the relevant
regions.

If a nested <code>xpath{}</code> fails, the diagnostic only
reflects the 
#!link!Nested_xpath_Faults!inner context.
This is you don't have to read an entire document to find the
part that failed.

=end
#!end_panel!
#!no_doc!
require File.dirname(__FILE__) + '/test_helper'
require 'assert2/ripdoc' if RUBY_VERSION >= '1.9.0'
require 'assert2/xpath'
require 'assert2/xhtml'

#  FIXME  given :' why is the tick not colored?

class AssertXhtmlSuite < Test::Unit::TestCase

  def setup
    colorize(false)
  end

#!doc!
=begin
<code>assert_xhtml( <em>xhtml</em> )</code>
Use this method to push well-formed XHTML into the assertion system. Subsequent
<code>xpath()</code> calls will interrogate this XHTML, using XPath notation:
=end
  def test_assert_xhtml
    
    assert_xhtml '<html><body><div id="forty_two">42</div></body></html>'
    
    assert{ xpath('//div[ @id = "forty_two" ]').text == '42' }
  end
#!end_panel!
=begin
<code>_assert_xml()</code>

Some versions of <code>assert_xhtml()</code> fuss when
passed an XHTML fragment, or XML under some other schema. Use 
<code>_assert_xml()</code> to bypass those conveniences:
=end
  def test__assert_xml
    
   _assert_xml '<Mean><Woman>Blues</Woman></Mean>'
   
    assert{ xpath('/Mean/Woman').text == 'Blues' }
  end
#!end_panel!
=begin
<code>xpath( '<em>path</em>' )</code>

The function's first argument can be raw XPath in a string, or a symbol. The first 
symbol gets decorated
with the <code>'descendant-or-self::'</code> XPath axis, and a second symbol,
or an option hash,
get converted into a predicate, like <code>[ @id = "forty_two" ]</code>.

All the 
following queries reach out to the same node. Prefer the last notation, 
to cut thru a large XHTML web page down to the 
element containing the contents that you need to test:
=end
  def test_assert_xpath
    assert_xhtml '<html><body><div id="forty_two">42</div></body></html>'
    
    assert{ xpath('descendant-or-self::div[ @id = "forty_two" ]').text == '42' }
    assert{ xpath('//div[ @id = "forty_two" ]').text == '42' }
    assert{ xpath(:'div[ @id = "forty_two" ]').text == '42' }
    assert{ xpath(:div, :id => :forty_two).text == '42' }
    assert{ xpath(:div, :forty_two).text == '42' }
  end
#!end_panel!
=begin
<code>xpath( <em>DSL</em> )</code>

You can write simple XPath queries using Ruby's familiar hash notation. Query
a node's string contents with <code>?.</code>:
=end
  def test_xpath_dsl
    assert_xhtml 'hit
                  <a href="http://antwrp.gsfc.nasa.gov/apod/"
                    >apod</a>
                  daily!'
    assert do

      xpath :a, 
            :href => 'http://antwrp.gsfc.nasa.gov/apod/',
            ?. => 'apod'  #  the <code>?.</code> resolves to XPath: <code>a[ . = "apod" ]</code>

    end
  end
#!end_panel!
=begin
<code>xpath( <em>ID shortcut</em> )</code>

When <code>xpath()</code>'s second argument is a <code>:symbol</code>,
it expands to <code>[ @id = "<em>symbol</em>" ]</code>. Subsequent arguments
use Hash notation:
=end
  def test_xpath_ID_shortcut
    assert_xhtml '<html><body>
                    <div id="forty_two" class="answer_to_the_great_question">
                      42
                    </div>
                  </body></html>'

    div_1 = xpath(:div, :forty_two, :class => :answer_to_the_great_question)
    div_2 = xpath(:div, :id => :forty_two, :class => :answer_to_the_great_question)

    assert{ div_1.text =~ /42/ and div_1 == div_2 }
  end
#!end_panel!
=begin
<code>xpath().text</code>

<code>xpath()</code> returns the first matching 
<a href='http://ruby-doc.org/core/classes/REXML/Node.html'><code>REXML::Node</code></a> object 
(or <code>nil</code> if it found none). The object has a useful method, <code>.text</code>,
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
<code>xpath()</code> Attribute Accessors

Raw <code>REXML::Node</code>s require a cluttered syntax
to access node attributes. Because <code>xpath()</code>
supports expedient queries, it adds a Hash-like accessor
to returned nodes:
=end
  def test_indent_xml
    return # TODO
   _assert_xml '<a href="http://www.youtube.com/watch?v=lWqr3mFAJ0Y"
                    >YouTube - UB40 - Sardonicus</a>'
    xpath '/a' do |a|

      a.attributes['href'] =~ /youtube/ and #  raw REXML::Node
      a['href']            =~ /youtube/ and #  permitted by <code>xpath()</code>
      a[:href ]            =~ /youtube/     #  convenient!

    end
  end
#!end_panel!
#!no_doc!
  #  the assert2_xpath.html file passed http://validator.w3.org/check
  #  with flying colors, the first time I ran it. However,
  #  something in these tests blows Ruby1.8's REXML's mind,
  #  so these tests gotta be blocked out
  if RUBY_VERSION >= '1.9.0'
#!doc!
=begin
Nested <code>xpath{}</code>

<code>xpath{}</code> takes a block, and passes this to 
<code>assert{}</code>. Any further <code>xpath()</code> calls, inside this
block, evaluate within the XML context set by the outer block.

This is useful because if you have a huge web page (such as the one you are reading)
you need assertions that operate on one small region alone - the place where a feature
must appear. You can typically give all your <code><div></code> regions 
useful <code>id</code>s, then use <code>xpath(:div, :my_id)</code> to restrict further
<code>xpath{}</code> calls:
=end
  def test_nested_xpaths
    assert_xhtml (DocPath + 'assert2_xpath.html').read
    assert 'this tests the panel you are now reading' do

      xpath :a, :name => :Nested_xpath do  #  finds the panel's anchor
        xpath '../following-sibling::div[1]' do   #  finds that <code>a</code> tag's adjacent sibling
          xpath :'pre/span', ?. => 'test_nested_xpaths' do |span|
            span.text =~ /nested/  #  the block passes the target node thru the <code>|</code>goalposts<code>|</code>
          end
        end
      end

    end
  end
#!end_panel!

=begin
<code>xpath{ <em>block</em> }</code> Calls <code>assert{ <em>block</em> }</code>

When <code>xpath{}</code> has a block, it passes its 
detected <code>|</code>node<code>|</code> into
the block. If the
block returns <code>nil</code> or <code>false</code>, it will <code>flunk()</code>
the block, using <code>assert{}</code>'s inner mechanics:
=end
  def test_xpath_passes_its_block_to_assert_2
   _assert_xml '<tag>contents</tag>'
    assert_flunk /text.* --> "contents"/ do

      xpath '/tag' do |tag|
        tag.text == 'wrong contents!'
      end

    end
  end
#!end_panel!
=begin
Nested <code>xpath{}</code> Faults

When an inner <code>xpath{}</code> fails, the diagnostic's "<code>xml context:</code>" 
field contains only the inner XML. This prevents excessive spew when testing entire
web pages:
=end
  def test_nested_xpath_faults
    assert_xhtml (DocPath + 'assert2_xpath.html').read
    diagnostic = assert_flunk /BAD.*CONTENTS/ do
      xpath :a, :name => :Nested_xpath_Faults do

         # the <code>../</code> finds this entire panel, the <code>div[1]</code> finds its content area,
         # and the <code>pre</code> finds the code sample you are reading
        xpath '../following-sibling::div[1]/pre' do
          
            # this will fail because that text ain't found in a <code>span</code>
            # (the <code>concat()</code> makes it into two <code>span</code>s!)
          xpath :'span[ . = concat("BAD", " CONTENTS") ]'
        end

      end
    end
#    puts diagnostic  
      # the diagnostic won't cantain the string "excessive spew", from
      # the top of the panel, because the second <code>xpath{}</code> call excluded it
    deny{ diagnostic =~ /excessive spew/ } #  FIXME  uh, this is the wrong context!!
  end
#!end_panel!
#!no_doc!
  end # if RUBY_VERSION >= '1.9.0'
#!doc!
=begin
<code>xpath( ?. )</code> Matches Recursive Text

When an XML node contains child nodes with text, 
the XPath predicate <code>[ . = "</code>...<code>" ]</code> matches
all their text, concatenated together. <code>xpath()</code>'s 
DSL converts <code>?.</code> into that notation:
=end
  def test_nested_xpath_text
   _assert_xml '<boats><a>frig</a><b>ates</b></boats>'

    assert{ xpath :boats, ?. => 'frigates' }
  end
#!end_panel!
=begin
<code>xpath( ?. )</code> Notation Is not the Same as <code>xpath().text</code>

<code>xpath()</code> returns the first node, in document order, which
matches its XPath arguments. So <code>?.</code> will
force <code>xpath()</code> to keep searching for a hit.

<code>xpath().text</code> will find the first matching node, then offer
its <code>.text</code> for comparison. These assertions explicate 
the difference:
=end
  def test_xpath_text_is_not_the_same_as_question_dot_notation
    _assert_xml '<Mean>
                  <Woman>Blues</Woman>
                  <Woman>Dub</Woman>
                </Mean>'
    assert do

      xpath(:Woman).text == 'Blues' and
      xpath(:Woman, ?. => :Dub).text == 'Dub'
                   # use a symbol ^ to match a string here, as a convenience

    end
  end
#!end_panel!
=begin
Use <code>indent_xml</code> to Help Build your XPath

To see what region <code>xpath{}</code> has selected in
a big document, temporarily add <code>puts</code> 
<code>indent_xml</code> <code>and</code>
to <code>xpath</code>'s block, then run your tests:
=end
  def test_indent_xml
    #  TODO  disambiguate with other test_indent_xml
    return
    assert_xhtml (DocPath + 'assert2_xpath.html').read
    xpath :span, ?. => :test_indent_xml do
      xpath '..' do
        
        # <code>puts indent_xml and</code>  #  Decomment this to see where you are in the document now
        
        indent_xml.match("<pre>\n") and
        ! indent_xml.match('<html')
      end
    end
  end
#!end_panel!
#!no_doc!

# FIXME  assert_tidy

# TODO  inner_text should use ?.
        #  TODO  colorize stuff in <code> tags already!!!
        #  TODO  which back-ends support . = '' matching recursive stuff?
        #  TODO  which back-ends support . =~ '' matching regices?
#  fim  replace libxml with rexml in the documentation
#  TODO  split off the tests that hit assert2_utilities.rb...
# TODO  the explicit diagnostic message of the top-level assertion should 
#         appear in any nested assertion failures
#  TODO optional alias assert_xpath, and dorkument it
#  TODO  ripdoc should lint your work as it goes
#  TODO  :class => :symbol should do the trick contains(concat(' ', @class, ' '), ' w0 ')
#  TODO  :class => [] should do the trick contains(concat(' ', @class, ' '), ' w0 ') && contains(concat(' ',@class, ' '), ' g ')
#  TODO  :class => a string should be raw.

  if defined? Ripdoc
    def test_document_self
      doc = Ripdoc.generate(HomePath + 'test/assert2_xpath_suite.rb', 'assert{ xpath }')
      assert_xhtml doc
      assert{ xpath '/html/head/title', ?. => 'assert{ xpath }' }
      assert{ xpath :big, ?. => 'assert{ xpath }' }
      luv = HomePath + 'doc/assert2_xpath.html'
      File.write(luv, doc)
      reveal luv, '' #, '#Nested_xpath_Faults'
    end
  end
  
  def test_deny_xpath
   _assert_xml '<foo/>'
   # p 'rexml'
#    p @xdoc.find('/foo')
    #puts @xdoc.document.public_methods.sort.map{|m| m + ":noko"}
    
    deny{ xpath :bar }
  end

  def test_nokogiri_xpath
   _assert_xml_ '<foo/>'
    assert{ xpath_:foo }
  end

  class NokoMatcher
    def initialize hash = {}
      @hash = hash
    end

    def __evalerate(node)
      @hash.each do |k, v|
        return false unless q = node[k.to_s] and
        case v
          when Symbol ; q == v.to_s
          when String ; q.index(v)
          when Regexp ; q =~ v
          when NilObject; true
          else        ; false # TODO raise bad arg error
        end
      end
    end   #  TODO  are entities substituted?
    
    def _search(nodes)
      nodes.find_all{|node| __evalerate(node) }
    end
  end

  def test_nokogiri_custom_matcher
    _assert_xml_ '<body>
                    <a href="whatever">whatevs</a>
                    <a id="one" href="http://zeroplayer.com/">zp.com</a>
                  </body>'

    nm = NokoMatcher.new(:href => /zeroplayer/, :id => 'one' )
    @xdoc.xpath('//a[_search(.)]', nm)   
  end

  def test_xpath_converts_symbols_to_ids
   _assert_xml '<x><a id="wrong_one"/><a id="b"/></x>'
    assert{ xpath(:a, :b) == xpath('//a[ @id = "b" ]') }
  end

#  TODO  deal with horizontal overflow in panels!

  def test_xpath_converts_silly_notation_to_text_matches
   _assert_xml '<x><a>wrong one</a><a>b</a></x>'
    assert{ xpath(:a, :'.' => :b) == xpath('//a[ . = "b" ]') }
  end

  def test_xpath_wraps_assert
    return if RUBY_VERSION < '1.9' # FIXME  fix!
    assert_xhtml '<html/>'

    assert_flunk /node.name --> "html"/ do
      xpath '/html' do |node|
        node.name != 'html'
      end
    end
  end

  def test_deny_diagnoses_its_xpath
    assert_xhtml '<html><body/></html>'

    spew = assert_flunk /xml context/ do
      deny{ xpath '/html/body' }
    end

    assert{ spew =~ /xpath: "\/html\/body"/ }
  end

  def test_failing_xpaths_indent_their_xml_contexts
    return if RUBY_VERSION < '1.9' # TODO  fix!
    assert_xhtml '<html><body/></html>'
    
    assert_flunk "xml context:\n<html>\n  <body/>\n</html>" do
      assert{ xpath('yack') }
    end
  end
   
  def test_nested_diagnostics  #  TODO  put a test like this inside assert2_suite.rb
   _assert_xml '<a><b><c/></b></a>'
   
    diagnostic = assert_flunk 'xpath: "descendant-or-self::si"' do
      xpath :a do
        xpath :b do
          xpath :si
        end
      end
    end
    
    deny{ diagnostic.match('<a>') }
  end

  def test_a_missing_xpath_with_a_block_should_fault
   _assert_xml '<foo/>'
    
    diagnostic = assert_flunk /this xpath cannot find a node/i do
      xpath(:bar){ true }  #  an xpath that misses its node, and has a block, flunks
    end
    
    assert{ diagnostic =~ /xml context:.*foo/m }
  end

  def test_nested_contexts
   _assert_xml '<a><b/></a>'
   
    xpath :a do
      xpath :b do
        deny{ xpath :a }
      end
    end
  end

  def test_deny_nested_diagnostics
    return if RUBY_VERSION < '1.9.0'
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
    apa = AssertXPathArguments.new
    apa.to_predicate(:zone, {})
    assert{ apa.xpath == "[ @id = $id ]" }
    apa.to_predicate(:zone, :foo => :bar)
    predicate = apa.xpath
    assert{ apa.subs == { "id" => 'zone', "foo" => 'bar' } }
    
    assert do    
      predicate.index('[ ') == 0 and
      predicate.match(/@id = \$id/) and
      predicate.match(" and ")        and
      predicate.match(/@foo = \$foo/) and
      predicate.match(/ \]$/)
    end  #  TODO  this should stop repeating the predicate part in the reflection
  end

  def test_xpath_takes_both_a_symbolic_id_and_options
   _assert_xml '<div id="zone" foo="bar">yo</div>'
    assert{ xpath(:div, :zone, {}).text == 'yo' }
    assert{ xpath(:div, :zone, :foo => :bar).text == 'yo' }
  end

  def test_xpath_converts_hashes_into_predicates
   _assert_xml '<a class="b"/>'
    expected_node = REXML::XPath.first(@xdoc, '/a[ @class = "b" ]')
    assert{ xpath(:a, :class => :b) == expected_node }
  end  #  TODO  use this in documentation

  def test_xpath_substitutions
   _assert_xml '<div id="zone" foo="bar">yo</div>'
    assert{ REXML::XPath.first(@xdoc, '/div[ @id = $id ]', nil, { 'id' => 'zone' }) }
  end

  def test_to_xpath
    apa = AssertXPathArguments.new
    apa.to_xpath(:a, { :href=> 'http://www.sinfest.net/', ?. => 'SinFest' }, {})

    assert do
      apa.xpath == "descendant-or-self::a[ @href = $href and . = $_text ]" or
      apa.xpath == "descendant-or-self::a[ . = $_text and @href = $href ]"
    end
    assert{ apa.subs == { 'href' => 'http://www.sinfest.net/', '_text' => 'SinFest' } }
  end

  def test_apos_does_not_freak_rexml_out
    assert_xhtml '<html><body>&apos;</body></html>'
    assert{ xpath('/html/body').text == "'" }
  end

  def test_apos_does_not_freak_rexml_out_even_in_xml_mode
   _assert_xml '<xml>&apos;</xml>'
    assert{ xpath('/xml').text == "'" }
  end

  def reveal(filename, anchor)
    # File.write('yo.html', xhtml)
#    system 'konqueror yo.html &'
    path = filename.relative_path_from(Pathname.new(Dir.pwd)).to_s.inspect
    system '"C:/Program Files/Mozilla Firefox/firefox.exe" ' + path + anchor + ' &'
  end

  def test_indent_xml_indents
   _assert_xml '<a><b><c/></b></a>'
    assert{ indent_xml == '<a>
  <b>
    <c/>
  </b>
</a>' }
  end

#  TODO  become a new suite

  def test_assert_xhtml_for_forms
    assert_xhtml SAMPLE_FORM do
      form :action => '/users' do
        fieldset do
          legend 'Personal Information'
          label 'First name'
          input :type => 'text', :name => 'user[first_name]'
        end
      end
    end
  end

  def test_prototype_recursive_algorithm
    bhw = BeHtmlWith.new(SAMPLE_FORM)

    doc = Nokogiri::HTML::Builder.new do
      div do
        form do  label 'not me'  end
        form :action => '/us"ers' do
          label 'not me either'
          fieldset do  label 'First \'name\''  end
        end
      end
    end
 
 #  TODO  publish this ability as a Nokogiri patch when I figure it out
 #  TODO  can we skip an earlier descendant who is a near miss?
    hits = [nil, form = doc.doc.root.xpath("//form[2]").first, form.xpath("./descendant::label[2]").first]

    node = doc.doc.root.xpath("//form[hit(., 1)]/descendant::label[hit(., 2)]", Class.new {
 
      def initialize(hits = [])
        @hits = hits
      end
 
      def match_text(node, hit)
        node_text = node.xpath('text()').map{|x|x.to_s.strip}
        hits_text = hit. xpath('text()').map{|x|x.to_s.strip}
          #  TODO regices? zero-len strings?
        ( hits_text - node_text ).length == 0
      end
 
      def hit(nodes, index)  #  TODO  low-level test on this; merge with test-side copy
        nodes.find_all{|node|
          all_match = true
          if all_match = match_text(node, @hits[index])
            @hits[index].attribute_nodes.each do |attr|
              break unless all_match = node[attr.name] == attr.value
            end
          end
          all_match
        }
      end
 
    }.new(hits)).first
    assert{ node.text == 'First \'name\'' }
  end

  def test_node_matcher_matches_node_text
    doc = Nokogiri::HTML('<ul>
                            <li>strange<ul><li>magic</li></ul>
                            <li>strangemagic</li>
                            <li>strangemagic</li>
                          </ul>')
    node_1 = doc.xpath('//ul/li[1]').first
    node_2 = doc.xpath('//ul/li[2]').first
    node_3 = doc.xpath('//ul/li[3]').first
    matcher = BeHtmlWith.create('<yo>')
    denigh{ matcher.match_text(node_1, node_2) }
    denigh{ matcher.match_text(node_2, node_1) }
    assert{ matcher.match_text(node_2, node_3) }
    assert{ matcher.match_text(node_3, node_2) }
  end

  def test_node_matcher_extracts_node_lists
    reference = Nokogiri::XML(SAMPLE_FORM)
    node      = reference.xpath('//input[ @id = "user_first_name" ]').first
    bhw       = BeHtmlWith.create(SAMPLE_FORM)
    path      = bhw.pathmark(node)

    assert do
      path.map{|n|n.name} == [
        'form',
        'fieldset',
        'ol',
        'li',
        'input'
      ]
    end
  end

  def test_node_matcher_turns_node_lists_into_decorated_paths
    reference = Nokogiri::XML(SAMPLE_FORM)
    bhw       = BeHtmlWith.create(SAMPLE_FORM)
    terminal  = reference.xpath('//input[ @id = "user_first_name" ]').first
    node_list = bhw.pathmark(terminal)
    path = bhw.decorate_path(node_list)

    expect = '//form[refer(., 0)]' +
       '/descendant::fieldset[refer(., 1)]' +
       '/descendant::ol[refer(., 2)]' +
       '/descendant::li[refer(., 3)]' +
       '/descendant::input[refer(., 4)]'

    assert path do 
      path == expect
    end
  end

  def test_find_terminal_nodes
    doc    = Nokogiri::XML(SAMPLE_FORM)
    legend = doc.xpath('//legend').first
    label  = doc.xpath('//label' ).first
    input  = doc.xpath('//input' ).first
    bhw    = BeHtmlWith.new(SAMPLE_FORM)
    assert{ [legend, label, input] == bhw.find_terminal_nodes(doc) }
  end

#   def test_use_each_terminals_marked_path
#     doc = Nokogiri::XML(SAMPLE_LIST)
#     bhw = BeHtmlWith.new(SAMPLE_LIST)
#     terminals = bhw.find_terminal_nodes(doc)
# 
#     terminals.each do |terminal|
#       nodes = bhw.pathmark(terminal)
#       path = bhw.decorate_path(nodes)
#       nm = BeHtmlWith::NodeMatcher.new(nodes)
#       assert{ doc.xpath(path, nm).any? }
#     end
#   end

#   def test_node_matcher_reports_lowest_match
#     reference = Nokogiri::XML('<a><b><c><d/></c></b></a>')
#     bhw       = BeHtmlWith.create('<a><b><e><o/></e></b></a>')
#     terminal  = bhw.find_terminal_nodes(reference).first
#     nodes     = bhw.pathmark(terminal)
#     path      = bhw.decorate_path(nodes)
#     nm        = BeHtmlWith::NodeMatcher.new(nodes)
#     deny{ bhw.doc.xpath(path, nm).any? }
#     assert{ nm.lowest_samples.first.name == bhw.doc.xpath('//a/b').first.name }
#   end

  def test_match_one_terminal
    reference = Nokogiri::XML('<b><c><d/></c></b>')
    bhw       = BeHtmlWith.create('<a><b><c><d/></c></b></a>')
    terminal  = bhw.find_terminal_nodes(reference).first
    got = bhw.match_one_terminal(terminal)
    assert{ got == nil }
  end

  def test_cant_match_one_terminal
    reference = Nokogiri::XML('<a><b><c><d/></c></b></a>')
    bhw       = BeHtmlWith.create('<a><b><e><o/></e></b></a>')
    terminal  = bhw.find_terminal_nodes(reference).first
    #  TODO  rename hits, matcher
    hits, matcher = bhw.match_one_terminal(terminal)
    assert{ nodes_equal(hits.first, bhw.doc.xpath('//a/b').first) }
    assert{ nodes_equal(matcher, reference.xpath('//a/b').first) }
  end

  def test_match_one_terminal_with_text
    reference = Nokogiri::XML('<b><c>d</c></b>')
    bhw       = BeHtmlWith.create('<a><b><c>d</c></b></a>')
    terminal  = bhw.find_terminal_nodes(reference).first
    got = bhw.match_one_terminal(terminal)
    assert{ got == nil }
  end

  def test_cant_match_one_terminal_because_of_bad_text
    reference = Nokogiri::XML('<b><c>d</c></b>')
    bhw       = BeHtmlWith.create('<a><b><c>o</e></b></a>')
    terminal  = bhw.find_terminal_nodes(reference).first
    hits, matcher = bhw.match_one_terminal(terminal)
    assert{ nodes_equal(hits.first, bhw.doc.xpath('//a/b').first) }
    assert{ nodes_equal(matcher, reference.xpath('//b/c').first) }
  end

  def test_match_one_terminal_with_an_attribute
    reference = Nokogiri::XML('<b><c d="e"></c></b>')
    bhw       = BeHtmlWith.create('<a><b><c d="e"></c></b></a>')
    terminal  = bhw.find_terminal_nodes(reference).first
    got = bhw.match_one_terminal(terminal)
    assert{ got == nil }
  end

  def test_cant_match_one_terminal_because_of_a_bad_attribute
    reference = Nokogiri::XML('<b><c d="e"></c></b>')
    bhw       = BeHtmlWith.create('<a><b><c d="f"></c></b></a>')
    terminal  = bhw.find_terminal_nodes(reference).first
    hits, matcher = bhw.match_one_terminal(terminal)
    assert{ nodes_equal(hits.first, bhw.doc.xpath('//a/b').first) }
    assert{ nodes_equal(matcher, reference.xpath('//b/c').first) }
  end

  def nodes_equal(node_1, node_2)
    node_1.document == node_2.document and node_1.path == node_2.path
  end

#  TODO  rename lowest_samples to matched_nodes

  def test_assert_xhtml_counts_its_shots
    assert_xhtml SAMPLE_LIST do
      ul :style => 'font-size: 18' do
        li 'model' do
          li 'Billings report'
          li 'Sales report'
          li 'Billings criteria'
        end
      end
    end    
  end

  def test_assert_xhtml_queries_by_complete_path
    assert_xhtml SAMPLE_LIST do
      ul{ li{ ul{ li 'Sales report'              } } }
      ul{ li{ ul{ li 'All Sales report criteria' } } }
    end    
  end

end


SAMPLE_FORM = <<EOH
<form action="/users">
  <fieldset>
    <legend>Personal Information</legend>
    <ol>
      <li id="control_user_first_name">
        <label for="user_first_name">First name</label>
        <input type="text" name="user[first_name]" id="user_first_name" />
      </li>
    </ol>
  </fieldset>
</form>
EOH

SAMPLE_LIST = <<EOH
<html>
  <body>
    <ul style='font-size: 18'>
      <li>model
        <ul>
          <li>Billings report</li>
          <li>Sales report</li>
          <li>Billings criteria</li>
          <li>Common system</li>
        </ul>
      </li>
      <li>controller
        <ul>
          <li>All Sales report criteria</li>
          <li>All Billings reports</li>
        </ul>
      </li>
    </ul>
  </body>
</html>
EOH

#  TODO  document we do strings correctly now

#  TODO  test when this fails the outermost diagnostic appears!
    #~ assert 'this tests the panel you are now reading' do

      #~ xpath :a, :name => :Nested_xpath do  #  finds the panel's anchor
        #~ xpath '../following-sibling::div[1]' do   #  find that A tag's immediate sibling
          #~ xpath :'pre/span', ?. => 'test_nested_xpaths' do |span|
            #~ span.text =~ /nested/  #  the block passes the target node thru the |goalposts|
          #~ end
        #~ end
      #~ end
