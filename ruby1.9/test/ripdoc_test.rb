require 'test/unit'
$:.unshift 'lib'; $:.unshift '../lib'
require 'assert21'
require 'ripdoc'
require 'assert_xhtml'
require 'pathname'

HomePath = (Pathname.new(__FILE__).dirname + '..').expand_path
p HomePath

#  TODO  no <tt>&nbsp; yes <pre>
#  TODO  assert{} should catch and decorate errors
#  TODO  deny{ xpath } decorates?
#  TODO  make the add_diagnostic take a lambda
#  TODO  censor TODOs from the pretty rip!

class RipDocSuite < Test::Unit::TestCase

#  TODO  no mo <tt></tt><br/>

  def setup
    @rip = RipDoc.new('')
    @output = ''
    @f = StringIO.new(@output)
  end

  def test_generate_accordion
return # TODO
    assert_xhtml RipDoc.generate(HomePath + 'lib/assert21.rb', 'assert{ 2.1 }')
    assert{ xpath('/html/head/title').text == 'assert{ 2.1 }' }

    #~ assert do
      
    #~ <div id="vertical_container">
      #~ <%= @sauce %>
      #~ <h1 class="accordion_toggle">assert{ 2.1 } reinvents assert{ 2.0 } for Ruby 1.9</h1>
    
    
    assert{ xpath(:span, style: 'display: none;').text.index('=begin') }
#    rap = Ripper.sexp(File.read('assert21.rb'))
#    puts rap.pretty_inspect.split("\n").grep(/embdoc/)
#    reveal
  end

  def test_we_be_well_formed
    f = (HomePath + 'lib/assert21.rb').open
    sauce = assert_rip_page(f)
    assert{ xpath(:span, style: 'display: none;').text.index('=begin') }

#    reveal
#    @xdoc = Document.new(sauce)
  end

    #  TODO  are # markers leaking into the formatted outputs?

  def test_embdoc_two_indented_lines_have_no_p_between_them
    assert_embdoc ['yo', ' indented', ' also indented', 'dude']
    denigh{ xpath(:'p[ contains(., "indented") ]') }
      #  TODO  assert forgot how to diagnose that...
    assert do # the very next element must be the next tt, 
              #   with the next line of contents!
      xpath(:'tt[ contains(., "indented") ]/following-sibling::*[ position() = 1 and name() = "br" ]/following-sibling::*[ . = " also indented" and position() = 1 ]')
    end
    denigh{ xpath(:'p[ . = " " ]') }
  end

  def test_on_embdoc_beg
    assert{ @rip.embdocs.nil? }
    @rip.on_embdoc_beg('=begin', @f)
    assert{ @output =~ /=begin/ }
    assert{ @rip.embdocs == [] }
  end

  def test_on_embdoc
    @rip.embdocs = []
    @rip.on_embdoc('yo', @f)
    denigh{ @output =~ /yo/ }
    assert{ @rip.embdocs == ['yo'] }
  end

  def assert_embdoc(array)
    @rip.embdocs = array
    @rip.on_embdoc_end('=end', @f)
    assert_xhtml "<html><body>#{ @output }</body></html>"
  end

  def test_on_embdoc_end
    assert_embdoc ['yo', 'dude', "\r\n", 'what', 'up?']
    assert{ xpath :'p[ . = "yo dude"  ]' }
    denigh{ xpath :"p[ . = '\r\n'     ]" }
    assert{ xpath :'p[ . = "what up?" ]' }
    assert{ @output =~ /=end/ }
    assert{ @rip.embdocs == [] }
  end

  def test_on_embdoc_end_with_unix_style_linefeeds
    assert_embdoc ['yo', 'dude', "\n", 'what', 'up?']
    assert{ xpath :'p[ . = "yo dude"  ]' }
    denigh{ xpath :"p[ . = '\n'       ]" }
    assert{ xpath :p, :'.' => 'what up?' }
  end

  def test_embdoc_with_indented_samples
    assert_embdoc ['yo', ' indented', 'dude']
    assert('TODO take out that little space'){ xpath :'p[ . = "yo " ]' }
    denigh{ xpath(:'p[ contains(., "indented") ]') }
    assert{ xpath(:'tt[ contains(., "indented") ]') }
    assert{ xpath :'p[ . = "dude" ]' }
  end

  def assert_rip(line)
    assert_xhtml RipDoc.compile_fragment(line)
  end
  
  def assert_rip_page(line)
    @sauce = RipDoc.compile(line)
    line = @sauce
    assert_xhtml line
    return line
  end

  def test_nested_string_mashers_form_well
    line = assert_rip('return "#{ format_snip(width, snip) } --> #{ format_value(width, value) }"')
    deny{ line =~ />>/ }
  end

  def test_comments_feed_lines
    lines = assert_rip('# comment
                        x = 42')
    assert{ lines =~ /<\/span><\/tt><br\/>\n/ }
  end

  def style(kode)
    "@style = '#{RipDoc::STYLES[kode]}'"
  end
  
  def test_string_patterns
    assert_rip('foo "bar"')
    deny{ xpath :'span[ @class = "string" ]' }
return # TODO
    assert do # and 
      xpath :"span[ #{style(:string)} and . = 'bar'  ]" do
        xpath "span[ #{style(:string_delimiter)} and . = '\"' ]"
      end
    end
  end

  def test_string_mashers
    assert_rip 'x = "b#{ \'ar\' }"'

#  TODO  this really needs the silly args system?

    assert do # and 
      xpath :"span[ #{style(:string)} and contains(., 'b')  ]" do
        xpath(:"span[ #{style(:embexpr)} ]").text.index('#{') == 0
      end
    end
  end

  def test_embdoc
    assert_rip "=begin\nWe be\nembdoc\n=end"
    assert{ xpath(:"span[ #{style(:embdoc)} ]/p").text =~ /We be/m }
  end

  def test_color_backrefs
    assert_rip 'x = $1' #   and
    assert{ xpath :"span[ #{style(:backref)} and . = '$1' ]" }
  end

  def test_regexp_patterns
    assert_rip('foo /bar/')
    
    assert do
      xpath :"span[ #{style(:regexp)} and contains(., 'bar')  ]" do
        xpath "span[ #{style(:regexp_delimiter)} and contains(., '/') ]"
      end
    end
  end

#  TODO evaluate mashed strings
#  TODO  pick weird color for regices
#  TODO  when an assertion block throws an E, decorate it with the diagnostic text
#   TODO intersticial string mashers still don't color correctly
#   TODO make function names bigger
#  TODO  respect linefeeds in parsed source when reflecting

  def reveal(xhtml = @sauce || @output)
    File.write('yo.html', xhtml)
#    system 'konqueror yo.html &'
    system '"C:/Program Files/Mozilla Firefox/firefox.exe" yo.html &'
  end
  
end

