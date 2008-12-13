require 'test/unit'
$:.unshift 'lib'; $:.unshift '../lib'
require 'assert2'
require 'ripdoc'
require 'assert_xhtml'

HomePath = RipDoc::HomePath

#  TODO  at scroll time keep the target panel in the viewport!
#  TODO  help stickmanlabs get a macbook pro (or help talk him out of it;)
#  CONSIDER  think of a use for the horizontal accordion, and for nesting them
#  TODO  Ruby 1.9 should link out
#  TODO evaluate mashed strings
#   TODO intersticial string mashers still don't color correctly
#   TODO make function names bigger
#  TODO  respect linefeeds in parsed source when reflecting
#  TODO  get everything working in Ruby 1.8.6, excuse 1.8.7, and get all but xpath working in 1.9.1
#  TODO  ahem. Abstract the f---ing xml library, and get working in 1.9.1 anyway!!

class RipDocSuite < Test::Unit::TestCase

  def setup
    @rip = RipDoc.new('')
    @output = ''
    @f = StringIO.new(@output)
  end

  def _test_generate_accordion_with_test_file
    assert_xhtml RipDoc.generate(HomePath + 'test/assert2_suite.rb', 'assert{ 2.1 }')
    assert{ xpath('/html/head/title').text == 'assert{ 2.1 }' }
    assert{ xpath(:span, style: 'display: none;').text.index('=begin') }
   
    assert do
      xpath :div, :vertical_container do
        xpath(:'h1[ @class = "accordion_toggle accordion_toggle_active" ]').text =~ 
                  /reinvents assert/
      end
    end

    # reveal
  end  #  TODO  why we crash when any other tests generate a ripped doc?

#  TODO  pay for Staff Benda Bilili  ALBUM: Très Très Fort (Promo Sampler) !

  def _test_a_ripped_doc_contains_no_empty_pre_tags
    assert_xhtml RipDoc.generate(HomePath + 'test/assert2_suite.rb', 'assert{ 2.1 }')
    
#    xpath :div, :content do
#      deny{ xpath(:'pre').text == "\n" }
  #  end
  end  #  TODO how to constrain the context and then deny inside it?
  
  #  TODO  something is snarfing the first space in a pre in a embdoc
  #  TODO  snarf all #! commentry
  #  TODO  better keyword color
  
  def test_embdocs_form_accordions_with_contents
    assert_xhtml RipDoc.generate(HomePath + 'test/assert2_suite.rb', 'assert{ 2.1 }')
   reveal
return  #  TODO  nested xpath failures should obey their inner context...
    assert do
      xpath :div, :vertical_container do
        xpath(:'h1/following-sibling::div[ @class = "accordion_content" ]/p').text =~ 
                  /complete report/
      end
    end
    deny{ @sauce.match('<p><p>') }
    deny{ @sauce.match('<pre></div>') }
    # reveal
  end

  def test_embdoc_two_indented_lines_have_no_p_between_them
    assert_embdoc ['yo', ' first indented', ' also indented', 'dude']
    denigh{ xpath(:'p[ contains(., "indented") ]') }
    assert{ xpath(:'pre[ contains(., "first indented") and contains(., "also indented") ]') }
    denigh{ xpath(:'p[ . = " " ]') }
  end

  def test_on_embdoc_beg
    assert{ @rip.embdocs.nil? }
    @rip.on_embdoc_beg('=begin', @f)
    assert{ @output == '' }
    assert{ @rip.embdocs == [] }
  end

  def test_on_embdoc
    @rip.embdocs = []
    @rip.on_embdoc('yo', @f)
    denigh{ @output =~ /yo/ }
    assert{ @rip.embdocs == ['yo'] }
    denigh{ @rip.in_no_doc }
  end

  def test_nodoc_inside_embdoc
    @rip.embdocs = []
    @rip.on_embdoc('yo', @f)
    @rip.on_embdoc('#!nodoc!', @f)
    @rip.on_embdoc('dude', @f)
    assert{ @rip.embdocs == ['yo'] }
    assert{ @rip.in_no_doc }
  end

  def test_no_doc_inside_embdoc
    @rip.embdocs = []
    @rip.on_embdoc('yo', @f)
    @rip.on_embdoc('#!no_doc!', @f)
    @rip.on_embdoc('dude', @f)
    assert{ @rip.embdocs == ['yo'] }
    assert{ @rip.in_no_doc }
  end

  def test_end_panel_after_embdoc_inserts_end_of_div_tag
    @rip.embdocs = []
    @rip.on_comment('#!end_panel!', @f)
    assert{ @output.match('</div>') }
  end

  def test_comments_dont_always_turn_nodoc_off
    @rip.embdocs = []
    @rip.in_no_doc = true
    @rip.on_comment('# non-commanding comment', @f)
    assert{ @rip.in_no_doc }
  end

  def assert_embdoc(array)
    @rip.embdocs = array
    @rip.on_embdoc_end('=end', @f)
    assert_xhtml "<html><body>#{ @output }</body></html>"
  end

  def test_re_html_ize_embdoc_lines
    assert{ @rip.enline('foo') == 'foo' }
    assert{ @rip.enline('f&lt;code&gt;o&lt;/code&gt;o') =~ /^f<code style.*>o<\/code>o/ }
  end

  def test_on_embdoc_end
    assert_embdoc ['banner', 'yo', 'dude', "\r\n", 'what', 'up?']
    assert{ xpath :'p[ . = "yo dude"  ]' }
    denigh{ xpath :"p[ . = '\r\n'     ]" }
    assert{ xpath :'p[ . = "what up?" ]' }
    denigh{ @output =~ /=end/ }
    assert{ @output =~ /\<pre>/ }
    assert{ @rip.embdocs == [] }
  end

  def test_on_embdoc_end_with_unix_style_linefeeds
    assert_embdoc ['banner', 'yo', 'dude', "\n", 'what', 'up?']
    assert{ xpath :'p[ . = "yo dude"  ]' }
    denigh{ xpath :"p[ . = '\n'       ]" }
    assert{ xpath :p, :'.' => 'what up?' }
  end

  def test_embdoc_with_indented_samples
    assert_embdoc ['banner', 'yo', ' indented', 'dude']
    assert('TODO take out that little space'){ xpath :'p[ . = "yo " ]' }
    denigh{ xpath(:'p[ contains(., "indented") ]') }
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

  def test_no_ripping_between_nodoc_tags
    line = assert_rip( "x = 42\n" +
                       "#!nodoc!\n" +
                       "y = 43\n"
                      ) 
    assert{ xpath :span, :'.' => 'x'  }
    assert{ xpath :span, :'.' => '42' }
    denigh{ xpath :span, :'.' => '#!nodoc!' }
    denigh{ xpath :span, :'.' => 'y'  }
    denigh{ xpath :span, :'.' => '43' }
  end

  def test_nodoc_tags_end_at_doc_tags
    line = assert_rip( "#!nodoc!\n" +
                       "y = 43\n" +
                       "# miss me\n" +
                       "#!doc!\n" +
                       "x = 42\n"
                     )
    denigh{ xpath :span, :'.' => '#!nodoc!' }
    denigh{ xpath :span, :'.' => 'y'  }
    denigh{ xpath :span, :'.' => '43' }
    denigh{ xpath :span, :'.' => '# miss me' }
    assert{ xpath :span, :'.' => 'x'  }
    assert{ xpath :span, :'.' => '42' }
  end

  def test_rip_braces
    assert_rip 'hash = { :x => 42, 43 => 44 }'
    denigh{ xpath :'span[ contains( ., "{{" ) ]' }
    assert{ xpath :'span[ contains( ., "{"  ) ]' }
  end

  def test_rip_split_lines
    line = assert_rip( "p 'rev\n" +
                       "    o\n" +
                       " lution'\n"
                      ) 
    assert{ xpath :span, :'.' =>    'rev'  }
    assert{ xpath :span, :'.' =>     'o'   }
    assert{ xpath :span, :'.' =>  'lution' }
  end

  def test_on_tstring_end
    f = ''
    @rip.spans_owed = 0
    @rip.on_tstring_end("'", f)
   _assert_xml f
   
    assert do
      xpath("/span[ contains(@style, 'background-color') ]").text == "'"
    end

  end

  def test_on_tstring_end_dangles
    f = ''
    @rip.spans_owed = 0
    @rip.on_tstring_end("  bug'", f)
   _assert_xml "<x>#{f}</x>"
   
    assert do
      xpath("/x"        ).text == "  " and
      xpath("/x/span[1]").text == "bug" and
      xpath("/x/span[2]").text == "'"
    end
  end

  def test_on_tstring_end_bug
    f = ''
    @rip.spans_owed = 0
    @rip.on_tstring_end("bug'", f)
   _assert_xml "<x>#{f}</x>"
   
    assert do
      xpath("/x/span[1]").text == "bug" and
      xpath("/x/span[2]").text == "'"
    end
  end

  def test_comments_feed_lines
    lines = assert_rip('# comment
                        x = 42')
    assert{ lines =~ /comment<\/span>\n/ }
  end

  def test_put_every_thing_into_a_pre_block
    lines = assert_rip('x = 42')
    assert do
      xpath :div, :content do
        #puts(@xdoc.to_s) and
        xpath 'pre/span'
      end
    end
  end

  def style(kode)
    "@style = '#{RipDoc::STYLES[kode]}'"
  end
  
  def test_string_patterns
    assert_rip('foo "bar"')
    denigh{ xpath :'span[ @class = "string" ]' }

    assert do
      xpath :"span[ #{style(:string)} and contains(., 'bar') ]" and
      xpath :"span[ #{style(:string_delimiter)} and . = '\"' ]"
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

  def toast_embdoc
    assert_rip "=begin\nbanner\nWe be\nembdoc\n=end"
puts @xdoc.to_s
    assert{ xpath(:"span[ #{style(:embdoc)} ]/div/p").text =~ /We be/m }
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

  def reveal(xhtml = @sauce || @output)
    filename = HomePath + 'doc/yo.html'
    File.write(filename, xhtml)  
    filename = filename.relative_path_from(Pathname.pwd)
    system "\"C:/Program Files/Mozilla Firefox/firefox.exe\" #{filename} &"
  end
  
end

