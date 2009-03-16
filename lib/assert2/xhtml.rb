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
     such as the <ol> and <li> fields. They can change
     freely as our website upgrades
 - at fault time, the matcher prints out the failing elements
     and their immediate context.

=end

require 'nokogiri'

class Nokogiri::XML::Node

  class XPathYielder
    def initialize(method_name, &block)
      self.class.send :define_method, method_name do |*args|
        raise 'must call with block' unless block
        block.call(*args)
      end
    end
  end

  def xpath_with_callback(path, method_name, &block)
    xpath path, XPathYielder.new(method_name, &block)
  end

end

  class BeHtmlWith

    def get_texts(node)
      node.xpath('text()').map{|x|x.to_s.strip}.reject{|x|x==''}.compact
    end
    
    def match_text(ref, sam)
      ref_text = get_texts(ref)
        #  TODO regices?
      ref_text.empty? or ( ref_text - get_texts(sam) ).empty?
    end

    def match_attributes_and_text(reference, sample)
      reference.attribute_nodes.each do |attr|
        sample[attr.name] == attr.value or return false
      end

      return match_text(reference, sample)
    end

    def nodes_equal(node_1, node_2)
      raise 'programming error: mismatched nodes' unless node_1.document == node_2.document
      node_1.path == node_2.path
    end
    
#       end  #  TODO  more "elements" less "nodes"
    
    attr_accessor :doc
    
    def matches?(stwing, &block)
   #   @scope.wrap_expectation self do  #  TODO  put that back online
        begin
          bwock = block || @block || proc{} #  TODO  what to do with no block? validate?
          builder = Nokogiri::HTML::Builder.new(&bwock)
          @doc = Nokogiri::HTML(stwing)
          @reason = nil
          @first_samples = []
          path = build_deep_xpath(builder.doc.root)

          matchers = doc.root.xpath_with_callback path, :refer do |nodes, index|
                       samples = nodes.find_all do |node|
                         match_attributes_and_text(@references[index.to_i], node)
                       end

                       @first_samples += samples if samples.any? and index = '0'
                       samples
                     end
          
          if matchers.empty?
            @first_samples << doc.root if @first_samples.empty?  #  TODO  test the first_samples system
            @failure_message = complain_about(builder.doc.root, @first_samples)
          end  #  TODO  use or lose @reason
          
          # TODO complain if too many matchers or not enough!

          return matchers.any?
        end
  #    end
    end

    def build_deep_xpath(element)
      @references = []
      return '//' + build_xpath(element)
    end

    attr_reader :references

    def build_xpath(element)
      path = element.name
      node_kids = element.children.grep(Nokogiri::XML::Element)
      path << '[ '
      path << "refer(., '#{@references.length}')"
      @references << element

      if node_kids.any?
        path << ' and ' +
                node_kids.map{|child|
                  './descendant::' + build_xpath(child)
                }.join(' and ')
      end        
      path << ' ]'

      return path
    end

    def complain_about(refered, samples, reason = nil)  #  TODO  put argumnets in order
      reason = " (#{reason})" if reason
      "\nCould not find this reference#{reason}...\n\n" +
        refered.to_html +
        "\n\n...in these sample(s)...\n\n" +  #  TODO  how many samples?
        samples.map{|s|s.to_html}.join("\n\n...or...\n\n")
    end

    def count_elements_to_node(container, element)
      return 0 if nodes_equal(container, element)
      count = 0
      
      container.children.each do |child|
        sub_count = count_elements_to_node(child, element)
        return count + sub_count if sub_count        
        count += 1
      end
      
      return nil
    end  #  TODO  use or lose these

  #  TODO does a multi-modal top axis work?
  # TODO      this_match = node.xpath('preceding::*').length
      
      # http://www.zvon.org/xxl/XPathTutorial/Output/example18.html
      # The preceding axis contains all nodes in the same document 
      # as the context node that are before the context node in 
      # document order, excluding any ancestors and excluding 
      # attribute nodes and namespace nodes 

    attr_accessor :failure_message
 
    def negative_failure_message
      "TODO"
    end
    
    def initialize(scope, &block)
      @scope, @block = scope, block
    end

    def self.create(stwing)
      bhw = BeHtmlWith.new(nil)
      bhw.doc = Nokogiri::HTML(stwing)
      return bhw
    end

  end

module Test::Unit::Assertions
  def assert_xhtml(xhtml = @response.body, &block)  # TODO merge
    if block
     # require 'should_be_html_with_spec'
      matcher = BeHtmlWith.new(self, &block)
      matcher.matches?(xhtml, &block)
      message = matcher.failure_message
      flunk message if message.to_s != ''
#       return matcher.builder.doc.to_html # TODO return something reasonable
    else
     _assert_xml(xhtml) # , XML::HTMLParser)
      return @xdoc
    end
  end
end
