require File.dirname(__FILE__) + '/test_helper'
require 'ostruct'
require 'assert2/xhtml'

#  ERGO ripdoc:  given :' why is the tick not colored?

class AssertXhtmlSuite < Test::Unit::TestCase

  def setup
    colorize(false)
  end

  def assemble_form_example
    lambda do
      form :action => '/users' do
        fieldset do
          legend 'Personal Information'
          li do
            label 'First name'
            input :type => 'text', :name => 'user[name]'
          end
        end
      end
    end
  end

  #  TODO  use the xdoc if available

  def test_assert_xhtml_for_forms
    assert_xhtml SAMPLE_FORM, &assemble_form_example
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
    denigh{ matcher.match_text(node_1, node_2) } # CONSIDER some matches are hysteretic?
    denigh{ matcher.match_text(node_2, node_1) }
    assert{ matcher.match_text(node_2, node_3) }
    assert{ matcher.match_text(node_3, node_2) }
  end
  
  def nodes_equal(node_1, node_2)
    node_1.document == node_2.document and node_1.path == node_2.path
  end

  def test_node_complaint
    reference = Nokogiri::XML('<b><c d="e"></c></b>')
    bhw       = BeHtmlWith.create('<a><b><c d="f"></c>
                                        <c d="g"></c></b></a>')
    samples   = bhw.doc.xpath('//a/b/c')
    refered   = reference.xpath('//b/c').first
    complaint = bhw.complain(refered, samples)

    assert complaint do
      complaint =~ /Could not find this reference.../ and
      complaint.index(refered.to_html)
    end
    
    assert complaint do
      complaint =~ /...in this sample.../
    end
  end

  def test_complain_about
    reference = Nokogiri::XML('<b><c d="e"></c></b>')
    bhw       = BeHtmlWith.create('<a><b><c d="f"></c>
                                        <c d="g"></c></b></a>')
    samples   = bhw.doc.xpath('//a/b/c')
    refered   = reference.xpath('//b/c').first
    complaint = bhw.complain(refered, samples)

    assert complaint do
      complaint =~ /Could not find this reference.../ and
        complaint.index(refered.to_html)
    end
  end
  
  def test_assert_xhtml_returns_its_node
    node = assert_xhtml SAMPLE_LIST do
      ul :style => 'font-size: 18'
    end  #  TODO  blog you can't name the outer node the same as ul

    assert{ node[:style] == 'font-size: 18' }
  end  #  TODO blog that we return the first top node!
 
  def test_assert_xhtml_counts_its_shots
    assert_xhtml SAMPLE_LIST do
      ul :style => 'font-size: 18' do
        li 'model' do
          li :xpath! => 'position() = 1' do  text 'Billings report'    end
          li :xpath! => 'position() = 2' do  text /sales report/i      end
          li :xpath! => '1'              do  text 'Billings report'    end
          li :xpath! => '3'              do  text 'Billings criteria'  end
        end
      end
    end
    
    @teh_scope_bug_be_fixed = 'Billings report'
    
    assert_xhtml SAMPLE_LIST do |x|
      x.li /model/ do
        x.without! do
          x.li :xpath! => 'position() = 2' do
            x.text @teh_scope_bug_be_fixed
          end
        end
      end
    end
    
    assert_xhtml_flunk SAMPLE_LIST do
      ul :style => 'font-size: 18' do
        li 'model' do
          li(:xpath! => '1'){ text 'Sales report'  }
          li(:xpath! => '2'){ text 'Billings report' }
          li(:xpath! => '3'){ text 'Billings criteria' }
        end
      end
    end
  end

  def test_bad_text_flunks
    assert_xhtml SAMPLE_LIST do
      li 'model'
    end
      
    assert_xhtml_flunk SAMPLE_LIST do
      li 'not found'
    end

    assert_xhtml_flunk SAMPLE_FORM do
      li 'not found'
    end
  end

  def test_bad_attributes_flunk
    diagnostic = assert_xhtml_flunk SAMPLE_FORM do
      legend
      input :type => :text, :name => 'user[first_nome]'
    end
    deny(diagnostic){ diagnostic =~ /\<\!DOCTYPE/ }
    assert(diagnostic){ diagnostic =~ /first_nome/ }
  end

  def test_diagnostic_message
    assert_flunk /whatever .* moodel/mx do
      assert_xhtml SAMPLE_LIST, 'whatever' do
        li 'moodel'
      end
    end
    
    @response = OpenStruct.new(:body => SAMPLE_LIST)

    assert_flunk /whatever .* moodel/mx do
      assert_xhtml 'whatever' do
        li 'moodel'
      end
    end

    assert_flunk /whatever .* moodel/mx do
      assert_xhtml SAMPLE_LIST, 'whatever' do
        li 'moodel'
      end
    end
  end  #  TODO  diagnostic message for be_html_with!

  def test_censor_bangs
    assert_xhtml '<select/>' do  select! end

    assert_xhtml_flunk SAMPLE_FORM do
      select! :id => 42
    end
  end

  def test_xpath
    bhw  = BeHtmlWith.create(SAMPLE_FORM)
    path = bhw.build_xpaths{ legend :xpath! => 'parent::fieldset' }.first
    denigh{ path == "//descendant::legend[ refer(., '0') ][ parent::fieldset ]" }
    
    assert_xhtml SAMPLE_FORM do
      legend :xpath! => 'parent::fieldset'
    end
    
    assert_xhtml_flunk SAMPLE_FORM do
      legend :xpath! => 'parent::noodles'
    end

#  TODO  without! xpath! ? top level without! xpath! ?

  end

  def test_any_element
    bhw = assemble_BeHtmlWith{ any :attribute => 'whatever' }
    element = bhw.builder.doc.root
    assert{ bhw.translate_tag(element) == 'any' }
    bhw = assemble_BeHtmlWith{ any! :attribute => 'whatever' }
    element = bhw.builder.doc.root
    assert{ bhw.translate_tag(element) == '*' }
  end

  def test_xpath_matcher_does_not_use_refer
    bhw  = assemble_BeHtmlWith
    path = bhw.build_xpaths{ legend :xpath! => 'parent::fieldset' }.first
    reference = bhw.builder.doc.root
    bhw.sample = bhw.doc.xpath('//legend').first
    bhw.reference = reference
    assert('skip the xpath!'){ bhw.match_attributes }
  end  #  ERGO  this test does not actually cover anything...

  def toast_verbosity
    assert_xhtml SAMPLE_FORM do
      fieldset do
        legend 'Personal Information'
        li :verbose! => true do
          label 'First name', :for => :user_name
          input :type => :text, :name => 'user[name]'
          br
        end
      end
    end
    
    #  TODO  verbose is supposed to work even if the inner html has a bug!
    
  end

  def test_build_xpath
    bhw = BeHtmlWith.create(SAMPLE_FORM)
    built = Nokogiri::HTML::Builder.new do  #  TODO  use build_xpaths
      fieldset do
        legend 'Personal Information'
        li :verbose => true do
          label 'First name', :for => :user_name
          input :type => :text, :name => 'user[name]'
          br
        end
      end
    end

    path = bhw.build_deep_xpath(built.doc.root)
    assert{ path.index("//descendant::fieldset[ refer(., '0') and descendant::legend") == 0 }
    assert(path){ path.index("label[ refer(., '3') ]") }
    assert{ path =~ / \]/ }
    assert{ built.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.length == 1 }
    assert{ bhw.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.length == 1 }
    path = bhw.build_xpath(built.doc.root.xpath('//br').first)
    assert{ path == "descendant::br[ refer(., '6') ]" }
    assert{ bhw.references[0].path == built.doc.root.xpath('//fieldset').first.path }
    assert{ bhw.references[1] == built.doc.root.xpath('//legend' ).first }
    assert{ bhw.references[3] == built.doc.root.xpath('//label' ).first }
    assert{ bhw.references[4] == built.doc.root.xpath('//input').first }
  end
  
  def assert_xhtml_flunk(sample, &block)
    assert_flunk /Could not find/ do
      assert_xhtml sample, &block
    end
  end
  
  def test_nokogiri_builder_likes_bangs
    built = Nokogiri::HTML::Builder.new{ harlequin! }
    assert{ built.doc.to_html =~ /harlequin\!/ }
  end
  
  def test_without!
    assert_xhtml SAMPLE_FORM do
      fieldset do
        legend 'Personal Information'
        li do
          without! do
            libel 
          end
        end
      end
    end
    
    assert_xhtml SAMPLE_FORM do
      without!{ fieldset 'naba' }
    end

    assert_xhtml_flunk SAMPLE_FORM do
      without!{ fieldset }
    end
    
    assert_xhtml_flunk SAMPLE_FORM do
      form{ without!{ fieldset } }
    end
    
    assert_xhtml_flunk SAMPLE_FORM do
      without!{ fieldset }
      form{ without!{ fieldset } }
    end
    
    bhw = BeHtmlWith.create(SAMPLE_FORM)

    paths = bhw.build_xpaths do
              without! do  
                fieldset
                wax_museum
              end
            end

    path = paths.first
    assert{ path =~ /or descendant::wax_museum/ }
    
    assert_xhtml_flunk SAMPLE_FORM do
      without! do
        fieldset
        wax_museum
      end
    end
    
    assert_xhtml_flunk SAMPLE_FORM do
      form{ without!{ fieldset } }
      without!{ fieldset }
    end
    
    assert_xhtml_flunk SAMPLE_FORM do
      form
      without!{ fieldset }
    end
    
    assert_xhtml_flunk SAMPLE_FORM do
      fieldset do
        legend 'Personal Information'
        li do
          without! do  label  end
        end
      end
    end
  end

  def test_in_denial
    bhw = BeHtmlWith.create(SAMPLE_FORM)
    built = Nokogiri::HTML::Builder.new do
      fieldset do
        legend 'Personal Information'
        li do
          without! do  libel  end
        end
      end
    end
    
    #  TODO  more reality-check tests on without!
    
    path = bhw.build_deep_xpath(built.doc.root)
    deny{ path =~ /descendant::without/ }
    assert(path){ path =~ / not\( descendant\:\:libel/ }
#     p path
#     assert{ built.doc.root.xpath_with_callback(path, :refer){|nodes, index| 
# p    nodes.map{|q|q.name}
#       nodes}.length == 1 }
  end

  def test_build_xpath_too
    return # ERGO await fix from libxml2!
    bhw = BeHtmlWith.create(SAMPLE_FORM)
    built = Nokogiri::HTML::Builder.new do
      fieldset do
        legend 'Personal Information'
        li do
          label 'First name', :for => :user_name
          br
          input :type => :text, :name => 'user[name]'
        end
      end
    end

    path = bhw.build_deep_xpath_too(built.doc.root)
    p path
    assert{ built.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.length == 1 }
    assert{ path.index("//fieldset[ ./descendant::legend") == 0 }
    
    path = "//fieldset[ 
               descendant::legend[ 
                following-sibling::*[ 
                 descendant-or-self::li[ 
                  descendant::label[ 
                   following-sibling::*[ 
                    descendant-or-self::br[ 
                     following-sibling::*[ 
                      descendant-or-self::input ] ] ] ] ] ] ] ]"
    
    path = "//li[ 
                  descendant::label[ 
                   following-sibling::*[ 
                    descendant-or-self::br[ 
                     following-sibling::*[ 
                      descendant-or-self::input ] ] ] ] ]"
    
    assert{ built.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.length == 1 }
p built.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.first.name
    return
    assert{ path.index("./descendant::legend[ ./following-sibling::*[ ./descendant-or-self::li") == 0 }
    assert(path){ path.index("label[ refer(., '3') ]") }
    assert{ path =~ / \]/ }
    
    return
    assert{ built.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.length == 1 }
    assert{ bhw.doc.root.xpath_with_callback(path, :refer){|nodes, index| nodes}.length == 1 }
    path = bhw.build_xpath(built.doc.root.xpath('//br').first)
    assert{ path == "br[ refer(., '6') ]" }
    bhw.references[0] = built.doc.root.xpath('//fieldset').first
    bhw.references[1] = built.doc.root.xpath('//legend' ).first
    bhw.references[3] = built.doc.root.xpath('//label' ).first
    bhw.references[4] = built.doc.root.xpath('//input').first
  end

  def test_regices_where_you_least_expect_them
    assert_xhtml SAMPLE_LIST do
      ul{ li /Sales/ }
    end

    assert_xhtml SAMPLE_FORM do
      li{ input :name => /(user.name)/i }
    end
  end

#  TODO does the latest assert_raise take a Regexp

  def test_assert_xhtml_queries_by_complete_path
    assert_xhtml SAMPLE_LIST do
      ul{ li{ ul{ li 'Sales report'              } }
          li{ ul{ li 'All Sales report criteria' } } }
    end
  end

  def test_class_is_magic
    assert_xhtml SAMPLE_LIST do
      ul.kalika do  #  goddess
        li 'Billings report'  #  passes despite other ul :class => :kalika
      end
    end
  end

  def test_anybang_is_magic
    assert_xhtml SAMPLE_LIST do
      ul.kalika do
        any! 'Billings report'
      end
    end
    
    assert_xhtml_flunk SAMPLE_LIST do
      without! do
        any! 'Billings report'
      end
    end
  end

  def test_assert_xhtml_matches_ampersandage
    uri = 'http://kexp.org/playlist/newplaylist.aspx?t=1&year=2009&month=3&day=19&hour=7'
    sample_1 = "<div><a href='#{ uri }'>King Khan &amp; The Shrines</a></div>"
    
#      p RUBY_VERSION
    
    built = Nokogiri::HTML::Builder.new{
                   div{ a(:href => uri) { text 'King Khan & The Shrines' } }
                 }
    sample_2 = built.doc.to_html
#     puts sample_2
    
    # TODO durst we do &mdash; ?
    
    assert_xhtml sample_1 do  a 'King Khan & The Shrines'  end
    assert_xhtml sample_2 do  a 'King Khan & The Shrines'  end

    assert_xhtml sample_1 do  a :href => uri  end
    assert_xhtml sample_2 do  a :href => uri  end

    assert_xhtml_flunk sample_1 do
      a :href => uri + '_ringer' do text 'King Khan & The Shrines' end
    end
  end

  def test_assert_xhtml_queries_by_congruent_path
    assert_xhtml_flunk SAMPLE_LIST do
      ul{ li{ ul{ li 'Sales report'
                  li 'All Sales report criteria' } } }
    end
    
    assert_xhtml SAMPLE_LIST do
      ul{ li{ ul{ li 'Sales report'
          without!{ li 'All Sales report criteria ' } } } }
    end
  end

  def test_via_builder_shortcuts
    assert_xhtml SAMPLE_LIST do
      ul.kalika do
        li 'Billings report'
      end
    end
    assert_xhtml SAMPLE_FORM do
      li.control_user_name! do
        label 'First name', :for => :user_name
      end
    end
  end

  def test_disambiguate_diagnostic_elements
    diagnostic = assert_xhtml_flunk SAMPLE_LIST do
      li.kali!{ ul.kaluka }
    end
    assert(diagnostic){ diagnostic =~ /kalika/ }  #  it tells you HOW TO FIX IT!
    denigh{ diagnostic =~ /font-size/ } #  ERGO  fix assert{ 2.0 } it calls denigh "assert"...
  end

  def assemble_BeHtmlWith(stwing = SAMPLE_FORM, &block)
    @bhw = BeHtmlWith.new(nil)
    @bhw.doc = Nokogiri::HTML(stwing)
    @xpaths = @bhw.build_xpaths &block if block
    return @bhw
  end  #  TODO  use this more

end

SAMPLE_LIST = <<EOH
<html>
  <body>
    <ul style='font-size: 18'>
      <li id='zone'>model
        <ul class='kalika goddess'>
          <li>Billings report</li>
          <li>Sales report</li>
          <li>Billings criteria</li>
          <li>Common system</li>
        </ul>
      </li>
      <li id='kali'>controller
        <ul class='kalika'>
          <li>All Sales report criteria</li>
          <li>All Billings reports</li>
        </ul>
      </li>
    </ul>
  </body>
</html>
EOH

class BeHtmlWith  #  TODO  replace with internal version
  def self.create(stwing, &block)
    bhw = BeHtmlWith.new(nil)
    bhw.doc = Nokogiri::HTML(stwing)
    bhw.build_xpaths &block if block
    return bhw
  end
end

SAMPLE_FORM = <<EOH
<form action="/users">
  <fieldset>
    <legend>Personal Information</legend>
    <ol>
      <li id="control_user_name">
        <label for="user_name">First name</label>
        <input type="text" name="user[name]" id="user_name" />
        <br/>
      </li>
    </ol>
  </fieldset>
</form>
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
