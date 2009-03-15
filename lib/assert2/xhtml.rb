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

  def xpath_callback(path, method_name, &block)
    xpath path, XPathYielder.new(method_name, &block)
  end

end

  class BeHtmlWith
    
    def find_terminal_nodes(doc)
      @terminal_map = []
      doc.xpath('//*[ not(./descendant::*) ]').map{|n|n}
    end

    def pathmark(node = @terminal)
      node.xpath('ancestor-or-self::*').map{|n|n}
    end  #  TODO  stop throwing away NodeSet abilities!

    def decorate_path(node_list = @references)
      index = -1
      
      '//' + node_list.map{|node|
                         node.name + "[refer(.,'#{ index += 1 }')]"
                       }.join('/descendant::')
    end

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

    def match_all_by_attributes_and_text(nodes)
      samples = nodes.find_all do |sample|
        @reference = @references[@index]
        match_attributes_and_text(@reference, sample)
      end
      
      @lowest_samples ||= samples if samples.any?
      samples
    end

    def match_one_terminal(terminal)
      @terminal = terminal
      @references = pathmark
      @lowest_samples = nil
      @reference = nil

      @matches = @doc.xpath_callback decorate_path, :refer do |nodes, index_|
        @index = index_.to_i
          #  ^  because the libraries pass raw numbers as float, which 
          #     might have rounding errors... CONSIDER complain?
        match_all_by_attributes_and_text(nodes)
      end

      #  CONSIDER  raise an error if more than one matches found?
      return nil if @matches.any? and all_mapped_terminals_are_congruent
      return @lowest_samples || [@doc.root], @reference
    end

    def all_mapped_terminals_are_congruent
      tuple = [@terminal, @matches.first]
      
      @terminal_map.each do |tuple_2|
        congruent(tuple_2, tuple) and next
        @reason ||= 'nodes found in different contexts'
        return false
      end
      
      @terminal_map << tuple  #  you win - join the club
      return true
    end

    def nodes_equal(node_1, node_2)
      raise 'programming error: mismatched nodes' unless node_1.document == node_2.document
      node_1.path == node_2.path
    end
    
    def congruent( tuple_a, tuple_b )
      a_ref, a_sam = tuple_a
      b_ref, b_sam = tuple_b

      if count_elements_to_node(a_sam.document, a_sam) >
         count_elements_to_node(b_sam.document, b_sam)
        @reason = 'elements are out of order'
        return false
      end  #  TODO  more "elements" less "nodes"
      
        #  TODO  complain if tuple_1 == tuple_2, or tuple_1.position < tuple_2

      while a_ref and b_ref and a_sam and b_sam
        nodes_equal(a_ref, b_ref) == 
          nodes_equal(a_sam, b_sam) or
            return false
        a_ref = (a_ref.parent rescue nil)
        b_ref = (b_ref.parent rescue nil)
        a_sam = (a_sam.parent rescue nil)
        b_sam = (b_sam.parent rescue nil)
      end
      return true
    end
    
    attr_accessor :doc,
                  :terminal_map
    
    def matches?(stwing, &block)
   #   @scope.wrap_expectation self do  #  TODO  put that back online
        begin
          bwock = block || @block || proc{}
          @builder = Nokogiri::HTML::Builder.new(&bwock)
          @doc = Nokogiri::HTML(stwing)
          @reason = nil
          
          #  TODO  complain if no terminals?
          terminals = find_terminal_nodes(@builder.doc)
          #  TODO  complain if found paths don't have the same root!
          
          terminals.each do |terminal|
            samples, refered = match_one_terminal(terminal)  #  TODO  return in different order
            if samples and refered
              @failure_message = complain_about(refered, samples, @reason)
              return false
            end
          end

          return true
        end
  #    end
    end

    def build_deep_xpath(element)
      return '//' + build_xpath(element)
    end

    def build_xpath(element)
      path = element.name

      node_kids = element.children.grep(Nokogiri::XML::Element)
      if node_kids.any?
        path << '[ '
        
        path << node_kids.map{|child|
          './descendant::' + build_xpath(child)
        }.join(' and ')
        
        path << ' ]'
      end

      return path
    end







    def complain_about(refered, samples, reason = nil)
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
    end

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
