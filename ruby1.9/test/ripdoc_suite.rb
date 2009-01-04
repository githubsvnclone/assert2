require File.dirname(__FILE__) + '/../../test_helper'
require 'assert2/ripdoc'
require 'assert2/xpath'

HomePath = Ripdoc::HomePath

#  TODO  at scroll time keep the target panel in the viewport!
#  CONSIDER  think of a use for the horizontal accordion, and for nesting them
#   TODO intersticial string mashers still don't color correctly
#   TODO make function names bigger
# FIXME  complete paths on image URLs 


class RipdocSuite < Test::Unit::TestCase

  def setup
    @rip = Ripdoc.new('')
    @output = ''
    @f = StringIO.new(@output)
  end

  def _test_generate_accordion_with_test_file
    assert_xhtml Ripdoc.generate(HomePath + 'test/assert2_suite.rb', 'assert{ 2.1 }')
    assert{ xpath('/html/head/title').text == 'assert{ 2.1 }' }
    assert{ xpath(:span, style: 'display: none;').text.index('=begin') }

    xpath :div, :vertical_container do
      xpath(:'h1[ @class = "accordion_toggle accordion_toggle_active" ]').text =~ 
                /reinvents assert/
    end

    # reveal
  end  #  CONSIDER  why we crash when any other tests generate a ripped doc?

  def test_a_ripped_doc_contains_no_empty_pre_tags
    assert_xhtml Ripdoc.generate(HomePath + 'test/assert2_suite.rb', 'assert{ 2.1 }')
    
    xpath :div, :content do
      deny{ @xdoc.to_s =~ /<pre>\s*<\/pre>/m }
    end
  end
  
  #  CONSIDER  something is snarfing the first space in a pre in a embdoc
  
  def test_snarf_all_shebang_commentary
    @rip.on_comment('#!whatever', @f)
    @rip.on_comment('  #!whatever', @f)
    deny{ @output.match('whatever') }
  end

  def test_mark_comments_up
    @rip.on_comment('# ooh girl I t\'ink ya need a <code>Rasta</code>man!', @f)
   _assert_xml @output
   
    xpath '/span' do |span|
      span.attributes['style'] =~ /font-family: Times;/ and #  attributes[] comes from raw REXML
      span[:style] =~ /font-family: Times;/ and #  FIXME  document these shortcuts
      xpath 'code', ?. => :Rasta
    end  #  TODO  also test these attributes in assert2_xpath_suite.rb
  end  #  TODO  forgive a broken tag in a comment!!!

  def test_embdocs_form_accordions_with_contents
    xhtml = Ripdoc.generate(HomePath + 'test/assert2_suite.rb', 'assert{ 2.1 }')
    assert_xhtml xhtml
    
    xpath :div, :vertical_container do
      xpath(:'div[ @class = "accordion_content" ]/p').text =~ 
                /complete, formatted report/
    end

    deny{ xhtml.match('<p><p>') }
    deny{ xhtml.match('<pre></div>') }
    reveal xhtml, 'assert21.html'
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

  def test_name_toggle
   _assert_xml @rip.name_toggle('proficy')
    assert{ xpath :a, :proficy_, :name => 'proficy' }
  end

  def test_name_toggle_with_spaces
   _assert_xml @rip.name_toggle('bingi drum')
    assert{ xpath :a, :bingi_drum_, :name => :bingi_drum }
  end

  def test_name_toggle_with_underbars
   _assert_xml @rip.name_toggle('bingi drum')
    assert{ xpath :a, :bingi_drum_, :name => :bingi_drum }
  end

  def test_name_toggle_censors_tags
   _assert_xml @rip.name_toggle('bingi <em>drum</em>')
    assert{ xpath :a, :bingi_drum_, :name => :bingi_drum }
  end

  def test_name_toggle_censors_entities
   _assert_xml @rip.name_toggle('bingi &amp; drum')
    assert{ xpath :a, :bingi_drum_, :name => :bingi_drum }
  end

  def test_name_toggle_censors_trailing_spaces
   _assert_xml @rip.name_toggle('jus seh di word ')
    assert{ xpath :a, :jus_seh_di_word_, :name => :jus_seh_di_word }
  end

  def test_on_embdoc_end
    @rip.embdocs = ['banner', 'yo', 'dude', "\r\n", 'what', 'up?']
    @rip.on_embdoc_end('=end', @f)
    denigh{ @output =~ /=end/ }
    assert{ @output =~ /\<pre>/ }
    assert{ @rip.embdocs == [] }
  end

  def assert_embdoc(array)
    @rip.embdocs = array
    @rip.on_embdoc_end('=end', @f)
    @output.sub!(/<pre>$/, '')
    @output << '</div>'
    assert_xhtml "<html><body>#{ @output }</body></html>"
  end

  def test_internal_links_in_shorthand
    assert_embdoc ['yo', '#!link!froot!lo<em>op</em>', 'dude']

    assert do
      xpath :a, :href => '#froot',
             :onclick => 'raise("froot")'
    end

    xpath :a, :href => '#froot', 
     # CONSIDER  :onclick => 'raise("froot")', # should not emit NoMethodError: undefined method `inject' for true:TrueClass>".
           :'.' => :loop do
      xpath :em, :'.' => :op
    end
  end

  def test_embdoc_two_indented_lines_have_no_p_between_them
    assert_embdoc ['yo', ' first indented', ' also indented', 'dude']
    denigh{ xpath(:'p[ contains(., "indented") ]') }
    assert{ xpath(:'pre[ contains(., "first indented") and contains(., "also indented") ]') }
    denigh{ xpath(:'p[ . = " " ]') }
  end

  def test_embdocs_link_out
    assert_embdoc(['yo <a href="http://antwrp.gsfc.nasa.gov/apod/">apod</a> dude'])
    assert{ xpath :a, :href => 'http://antwrp.gsfc.nasa.gov/apod/' }
  end

  def test_a_names_in_toggle_bars
    assert_embdoc(['yo', 'dude'])
    assert{ xpath :a, :name => :yo }
    denigh{ xpath :a, :name => :dude }
  end

  def test_re_html_ize_embdoc_lines
    assert{ @rip.enline('foo') == 'foo' }
    assert{ @rip.enline('f<code>o</code>o') =~ /^f<code style.*>o<\/code>o/ }
  end

  def test_on_embdoc_end_breaks_paragraphs
    assert_embdoc ['banner', 'yo', 'dude', "\r\n", 'what', 'up?']
    assert{ xpath :'p[ . = "yo dude"  ]' }
    denigh{ xpath :"p[ . = '\r\n'     ]" }
    assert{ xpath :'p[ . = "what up?" ]' }
    assert{ @rip.embdocs == [] }
  end

  def test_on_embdoc_end_with_unix_style_linefeeds
    assert_embdoc ['banner', 'yo', 'dude', "\n", 'what', 'up?']
    assert{ xpath :'p[ . = "yo dude"  ]' }
    denigh{ xpath :"p[ . = '\n'       ]" }
    assert{ xpath :p, ?. => 'what up?' }
  end

  def test_embdoc_with_indented_samples
    assert_embdoc ['banner', 'yo', ' indented', 'dude']
    assert('note we need that little space there!'){ xpath :p, ?. => 'yo ' }
    denigh{ xpath(:'p[ contains(., "indented") ]') }
    assert{ xpath :p, :'.' => 'dude' }
  end

  def assert_rip(line)
    xhtml = Ripdoc.compile_fragment(line)
    assert_xhtml xhtml
    return xhtml
  end
  
  def assert_rip_page(line)
    @sauce = Ripdoc.compile(line)
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
    assert{ xpath :span, ?. => 'x'  }
    assert{ xpath :span, ?. => '42' }
    denigh{ xpath :span, ?. => '#!nodoc!' }
    denigh{ xpath :span, ?. => 'y'  }
    denigh{ xpath :span, ?. => '43' }
  end

  def test_nodoc_tags_end_at_doc_tags
    line = assert_rip( "#!nodoc!\n" +
                       "y = 43\n" +
                       "# miss me\n" +
                       "#!doc!\n" +
                       "x = 42\n"
                     )
    denigh{ xpath :span, ?. => '#!nodoc!' }
    denigh{ xpath :span, ?. => 'y'  }
    denigh{ xpath :span, ?. => '43' }
    denigh{ xpath :span, ?. => '# miss me' }
    assert{ xpath :span, ?. => 'x'  }
    assert{ xpath :span, ?. => '42' }
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
    assert{ xpath :span, ?. =>    'rev'  }
    assert{ xpath :span, ?. =>     'o'   }
    assert{ xpath :span, ?. =>  'lution' }
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
    
    xpath :div, :content do
      xpath 'pre/span'
    end
  end

  def style(kode)
    "@style = '#{Ripdoc::STYLES[kode]}'"
  end
  
  def test_string_patterns
    assert_rip('foo "bar"')
    denigh{ xpath :'span[ @class = "string" ]' }

    assert do
      xpath :"span[ #{style(:string)} and contains(., 'bar') ]" and
      xpath(:"span[ #{style(:string_delimiter)} ]").text == '"'
    end
  end

  def test_string_mashers
    assert_rip 'x = "b#{ \'ar\' }"'

    xpath :"span[ #{style(:string)} and contains(., 'b')  ]" do
      xpath(:"span[ #{style(:embexpr)} ]").text.index('#{') == 0
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
    
    assert do  #  FIXME  take out many assert do calls like this
      xpath :"span[ #{style(:regexp)} and contains(., 'bar')  ]" do
        xpath "span[ #{style(:regexp_delimiter)} and contains(., '/') ]"
      end
    end
  end

  def test_regexps_are_purple
    assert_rip('foo /bar/')
    
    xpath :span, ?. => :bar do |span|
      span[:style] == 'background: url(images/hot_pink.png);'
    end
  end  #  FIXME  now nest them recursively

  def reveal(xhtml = @sauce || @output, filename)  #  TODO  take out the default arguments
    path = HomePath + 'doc' + filename
    File.write(path, xhtml)  
    path = path.relative_path_from(Pathname.pwd)
    system "\"C:/Program Files/Mozilla Firefox/firefox.exe\" #{path} &"
  end
  
end

