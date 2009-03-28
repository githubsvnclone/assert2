=begin
One Yury Kotlyarov recently this Rails project as a question:

  http://github.com/yura/howto-rspec-custom-matchers/tree/master

It asks: How to write an RSpec matcher that specifies an HTML
<form> contains certain fields, and enforces their properties
and nested structure? He proposed [the equivalent of] this:

    get :new  # a Rails "functional" test - on a controller

    assert_xhtml do
      form :action => '/users' do
        fieldset do
          legend 'Personal Information'
          label 'First name'
          input :type => 'text', :name => 'user[first_name]'
        end
      end
    end

The form in question is a familiar user login page:

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

If that form were full of <%= eRB %> tags, testing it would be 
mission-critical. (Adding such eRB tags is left as an exercise for 
the reader!)

This post creates a custom matcher that satisfies the following 
requirements:

 - the specification <em>looks like</em> the target code
    * (except that it's in Ruby;)
 - the specification can declare any HTML element type
     _without_ cluttering our namespaces
 - our matcher can match attributes exactly
 - our matcher strips leading and trailing blanks from text
 - the matcher enforces node order. if the specification puts
     a list in collating order, for example, the HTML's order
     must match
 - the specification only requires the attributes and structural 
     elements that its matcher demands; we skip the rest - 
     such as the <ol> and <li> elements. They can change
     freely as our website upgrades
 - at fault time, the matcher prints out the failing elements
     and their immediate context.

=end

require 'nokogiri'

class BeHtmlWith

  def initialize(scope, &block)
    @scope, @block = scope, block
    @references = []
    @spewed = {}
  end

  attr_accessor :builder,
                :doc,
                :failure_message,
                :scope
  attr_reader   :references
  attr_writer   :reference,
                :sample

  def matches?(stwing, &block)
    @block = block

    @scope.wrap_expectation self do
      @doc = Nokogiri::HTML(stwing)
      return run_all_xpaths(build_xpaths)
    end
  end
 
  def build_xpaths(&block)
    bwock = block || @block || proc{} #  CONSIDER  what to do with no block? validate?
    @builder = Nokogiri::HTML::Builder.new(&bwock)

    elemental_children.map do |child|
      build_deep_xpath(child)
    end
  end

  def elemental_children(element = @builder.doc)
    element.children.grep(Nokogiri::XML::Element)
  end

  def build_deep_xpath(element)
    path = build_xpath(element)
    path.index('not(') == 0 and return '/*[ ' + path + ' ]'
    return '//' + path
  end

  def build_xpath(element)
    count = @references.length
    @references << element  #  note we skip the without @reference!
    
    if element.name == 'without!'
      return 'not( ' + build_predicate(element, 'or') + ' )'
    else  #  TODO  SHORTER!!
      target = element.name.sub(/\!$/, '')
      path = "descendant::#{ target }[ refer(., '#{ count }') "
        #  refer() is first so we collect many samples, despite boolean short-circuiting
      path << 'and '  if elemental_children(element).any?
      path << build_predicate(element)
      path << ']'
      return path
    end
  end

  def build_predicate(element, conjunction = 'and')
    conjunction = " #{ conjunction } "
    element_kids = elemental_children(element)
    return element_kids.map{|child|  build_xpath(child)  }.join(conjunction)
  end

  def run_all_xpaths(xpaths)
    xpaths.each do |path|
      if match_xpath(path).empty?
        complain_about
        return false
      end
    end
    
    return true
  end
  
  def match_xpath(path, &refer)
    @doc.root.xpath_with_callback path, :refer do |element, index|
      collect_samples(element, index.to_i)
    end
  end

#  ERGO  match text with internal spacies?

  def collect_samples(elements, index)
    samples = elements.find_all do |element|
                match_attributes_and_text(@references[index], element)
              end
    
    collect_best_sample(samples, index)
    samples
  end

  def match_attributes_and_text(reference, sample)
    @reference, @sample = reference, sample
    match_attributes and match_text
  end

#  TODO  document without! and xpath! in the diagnostic
#  TODO  uh, indenting mebbe?

  def match_attributes
    sort_nodes.each do |attr|
      case attr.name
        when 'verbose!' ;  verbose_spew(attr)
        when 'xpath!'   ;  match_xpath_predicate(attr) or return false
        else            ;  match_attribute(attr)       or return false
      end
    end

    return true
  end

  def sort_nodes
    @reference.attribute_nodes.sort_by do |q|
      { 'verbose!' => 0,  #  put this first, so it always runs, even if attributes don't match
        'xpath!' => 2  #  put this last, so if attributes don't match, it does not waste time
        }.fetch(q.name, 1)
    end 
  end

#  TODO  why we have no :css! yet??

  def match_xpath_predicate(attr)
    @sample.parent.xpath("*[ #{ attr.value } ]").each do |m|
      m.path == @sample.path and 
        return true
    end

    return false
  end

  def verbose_spew(attr)
    if attr.value == 'true' and @spewed[yo_path = @sample.path] == nil
      puts
      puts '-' * 60
      p yo_path
      puts @sample.to_xhtml
      @spewed[yo_path] = true
    end
  end  #   ERGO  this could use a test...

  def match_attribute(attr)
    (ref = deAmpAmp(attr.value)) ==
    (sam = deAmpAmp(@sample[attr.name])) or 
      match_regexp(ref, sam)            or 
      match_class(attr.name, ref, sam)
  end

  def deAmpAmp(stwing)
    stwing.to_s.gsub('&amp;amp;', '&').gsub('&amp;', '&')
  end  #  ERGO await a fix in Nokogiri, and hope nobody actually means &amp;amp; !!!

  def match_regexp(reference, sample)
    reference.index('(?') == 0 and 
      Regexp.new(reference) =~ sample
  end

  def match_class(attr_name, ref, sam)
    return false unless attr_name == 'class'
    return " #{ sam } ".index(" #{ ref } ")
  end  #  NOTE  if you call it a class, but ref contains 
       #        something fruity, you are on your own!
  
  def match_text(ref = @reference, sam = @sample)
    (ref_text = get_texts(ref)).empty? or 
      (ref_text - (sam_text = get_texts(sam))).empty? or
        (ref_text.length == 1 and match_regexp(ref_text.first, sam_text.join) )
  end

  def get_texts(element)
    element.xpath('text()').map{|x|x.to_s.strip}.select{|x|x.any?}
  end

  def collect_best_sample(samples, index)
    sample = samples.first or return

    if index == 0 or @best_sample.nil? or depth(@best_sample) > depth(sample)
      @best_sample = sample
    end
  end

  def depth(e)
    e.xpath('ancestor-or-self::*').length
  end
  
  def complain_about( refered = @builder.doc.root, 
                       sample = @best_sample || @doc.root )
    @failure_message = "\nCould not find this reference...\n\n" +
                         refered.to_html +
                         "\n\n...in this sample...\n\n" +
                         sample.to_html
  end

  def build_deep_xpath_too(element)
    return '//' + build_xpath_too(element)
  end

  def build_xpath_too(element)
    path = element.name.sub(/\!$/, '')
    element_kids = element.children.grep(Nokogiri::XML::Element)
    path << '[ '
    count = @references.length
    @references << element
    brackets_owed = 0

    if element_kids.length > 0
      child = element_kids[0]
      path << './descendant::' + build_xpath_too(child)
    end

    if element_kids.length > 1
      path << element_kids[1..-1].map{|child|
                '[ ./following-sibling::*[ ./descendant-or-self::' + build_xpath_too(child) + ' ] ]'
               }.join #(' and .')
    end
       path << ' and ' if element_kids.any?

    path << "refer(., '#{ count }') ]"  #  last so boolean short-circuiting optimizes
    return path
  end

  def negative_failure_message
    "please don't negate - use without!"
  end
  
end


module Test; module Unit; module Assertions

  def wrap_expectation whatever;  yield;  end unless defined? wrap_expectation

  def assert_xhtml(xhtml = @response.body, &block)  # ERGO merge
    if block
      matcher = BeHtmlWith.new(self, &block)
      matcher.matches?(xhtml, &block)
      message = matcher.failure_message
      flunk message if message.to_s != ''
#       return matcher.builder.doc.to_html # TODO return something reasonable
    else
     _assert_xml(xhtml)
      return @xdoc
    end
  end

end; end; end

module Spec; module Matchers
  def be_html_with(&block)
    BeHtmlWith.new(self, &block)
  end
end; end

class Nokogiri::XML::Node
      def content= string
        self.native_content = encode_special_chars(string.to_s)
      end
end

class Nokogiri::XML::Builder
      def text(string)
        node = Nokogiri::XML::Text.new(string.to_s, @doc)
        insert(node)
      end
end  #  ERGO  retire these monkey patches as Nokogiri catches up

class Nokogiri::XML::Node

  class XPathPredicateYielder
    def initialize(method_name, &block)
      self.class.send :define_method, method_name do |*args|
        raise 'must call with block' unless block
        block.call(*args)
      end
    end
  end

  def xpath_with_callback(path, method_name, &block)
    xpath path, XPathPredicateYielder.new(method_name, &block)
  end

end

