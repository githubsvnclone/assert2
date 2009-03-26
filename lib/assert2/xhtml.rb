=begin
One Yury Kotlyarov recently posted this Rails project as a question:

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

class BeHtmlWith

  def initialize(scope, &block)
    @scope, @block = scope, block
    @references = []  #  TODO  soften this!
  end

  attr_accessor :doc,
                :scope,
                :builder

  def deAmpAmp(stwing)
    stwing.to_s.gsub('&amp;amp;', '&').gsub('&amp;', '&')
  end  #  ERGO await a fix in Nokogiri, and hope nobody actually means &amp;amp; !!!

  def get_texts(element)
    element.xpath('text()').map{|x|x.to_s.strip}.select{|x|x.any?}
  end

  def match_regexp(reference, sample)
    reference.index('(?') == 0 and 
      Regexp.new(reference) =~ sample
  end

  def match_text(ref, sam)
    (ref_text = get_texts(ref)).empty? or 
      (ref_text - (sam_text = get_texts(sam))).empty? or
        (ref_text.length == 1 and match_regexp(ref_text.first, sam_text.join) )
  end

  def verbose_spew(reference, sample)
    if reference['verbose!'] == 'true' and
       @spewed[yo_path = sample.path] == nil
      puts
      puts '-' * 60
      p yo_path
      puts sample.to_xhtml
      @spewed[yo_path] = true
    end
  end

  def match_class(attr_name, ref, sam)
    return false unless attr_name == 'class'
    return " #{sam} ".index(" #{ref} ")
  end  #  NOTE  if you call it a class, but ref contains 
       #        something fruity, you are on your own!
  
  def match_attributes(reference, sample)
    reference.attribute_nodes.each do |attr|
      next if %w( xpath! verbose! ).include? attr.name       
      (ref = deAmpAmp(attr.value)) ==
      (sam = deAmpAmp(sample[attr.name])) or 
        match_regexp(ref, sam)            or 
        match_class(attr.name, ref, sam)  or
        return false
    end

    return true
  end

  def match_xpath(reference, sample)
    return true unless value = reference['xpath!']

    sample.parent.xpath("*[ #{value} ]").each do |m|
      m.path == sample.path and return true
    end

    return false
  end

  def match_attributes_and_text(reference, sample)
    if match_attributes(reference, sample) and
        match_text(reference, sample)     and
        match_xpath(reference, sample)
      verbose_spew(reference, sample)
      return true
    end

    return false
  end

  def collect_samples(elements, index)
    samples = elements.find_all do |element|
      match_attributes_and_text(@references[index], element)
    end

    @first_samples += elements # if index == 0  
      #  TODO  this could use more testage, and it could enforce a link to the parent
    return samples
  end

  def assemble_complaint
    @first_samples << @doc.root if @first_samples.empty?  #  TODO  test the first_samples system
    @failure_message = complain_about(@builder.doc.root, @first_samples)
  end

  def elemental_children
    @builder.doc.children.grep(Nokogiri::XML::Element)
  end

  def build_xpaths(&block)
    bwock = block || @block || proc{} #  TODO  what to do with no block? validate?
    @builder = Nokogiri::HTML::Builder.new(&bwock)
    @references = []

    elemental_children.map do |child|
      build_deep_xpath(child)
    end
  end

  def match_path(path)
    @first_samples = []

    @doc.root.xpath_with_callback path, :refer do |elements, index|
      collect_samples(elements, index.to_i)
    end
  end

  def matches?(stwing, &block)
    @scope.wrap_expectation self do
      @doc = Nokogiri::HTML(stwing)
      @spewed = {}

      build_xpaths(&block).each do |path|
        if match_path(path).empty?
          assemble_complaint
          return false
        end
      end
      
      return true
    end
  end

  def build_shallow_xpath(root = @builder.doc)
    return '//*[ ' +
      root.children.reject{|kid|kid.name=='html'}.map{|kid|
        index = kid.xpath('ancestor::*').length +
                kid.xpath('preceding::*').length
      
        "descendant::#{kid.name}[ refer(., '#{index}') ]"
      }.join(' or ') + ' ]'
  end
  
  def build_deep_xpath(element)
    path = build_xpath(element)
    if path.index('not') == 0
      return '/*[ ' + path + ' ]'   #  ERGO  uh, is there a cleaner way?
    end
    return '//' + path
  end

  def build_deep_xpath_too(element)
    return '//' + build_xpath_too(element)
  end

  attr_reader :references

  def build_predicate(element, conjunction = 'and')
    path = ''
    conjunction = " #{ conjunction } "
    element_kids = element.children.grep(Nokogiri::XML::Element)

    if element_kids.any?
      path << element_kids.map{|child|  build_xpath(child)  }.join(conjunction)
      path << ' and '
    end

    return path
  end

  def build_xpath(element)
    count = @references.length
    @references << element  #  note we skip the without @reference!
    
    if element.name == 'without!'
      return 'not( ' + build_predicate(element, 'or') + '1=1 )'
    else
      path = 'descendant::'
      path << element.name.sub(/\!$/, '')
      path << '[ '
      path << build_predicate(element)
      path << "refer(., '#{count}') ]"  #  last so boolean short-circuiting optimizes
#       xpath = element['xpath!']
#       path << "[ #{ xpath } ]" if xpath
      return path
    end
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

    path << "refer(., '#{count}') ]"  #  last so boolean short-circuiting optimizes
    return path
  end

  def complain_about(refered, samples)  #  TODO  put argumnets in order
    "\nCould not find this reference...\n\n" +
      refered.to_html +
      "\n\n...in these sample(s)...\n\n" +  #  TODO  how many samples?
      samples.map{|s|s.to_html}.join("\n\n...or...\n\n")
  end

  attr_accessor :failure_message

  def negative_failure_message
    "TODO"
  end
  
end


module Test; module Unit; module Assertions

  def wrap_expectation whatever;  yield;  end unless defined? wrap_expectation

  def assert_xhtml(xhtml = @response.body, &block)  # TODO merge
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
end
