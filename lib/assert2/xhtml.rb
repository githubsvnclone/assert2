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
      doc.xpath('//*[ not(./descendant::*) ]').map{|n|n}
    end

    def pathmark(node)
      node.xpath('ancestor-or-self::*').map{|n|n}
    end  #  TODO  stop throwing away NodeSet abilities!

    def decorate_path(node_list = @references)
      index = -1
      
      return '//' + node_list.map{|node|
                        node.name + "[refer(.,'#{ index += 1 }')]"
                      }.join('/descendant::')
    end

    def match_attributes
      @reference.attribute_nodes.each do |attr|
        @sample[attr.name] == attr.value or return false
      end  #  TODO   restore ability to skip unreferenced nodes

      return true
    end

    def match_one_terminal(terminal)
      @references = pathmark(terminal)
      @lowest_samples = nil
      @reference = nil

      matches = @doc.xpath_callback decorate_path, :refer do |nodes, index_|
        @index = index_.to_i
          #  ^  because the libraries pass a float, which 
          #     might have rounding errors...
        samples = nodes.find_all{|sample|
          @reference, @sample = @references[@index], sample
          match_text and match_attributes
        }
        @lowest_samples ||= samples if samples.any?
        samples
      end
      return nil if matches.any?
      return (@lowest_samples || []), @reference
    end
    
    def get_texts(node)
      node.xpath('text()').map{|x|x.to_s.strip}.reject{|x|x==''}.compact
    end
    
    def match_text(sam = @sample, ref = @reference)  #  TODO  better testing
      ref_text = get_texts(ref)
        #  TODO regices?
      ref_text.empty? or ( get_texts(sam) - ref_text ).empty?
    end

    attr_accessor :doc
    attr_reader :builder # TODO  get rid of this
    
    def matches?(stwing, &block)
   #   @scope.wrap_expectation self do  #  TODO  put that back online
        begin
          bwock = block || @block || proc{}
          @builder = builder = Nokogiri::HTML::Builder.new(&bwock)
          @doc = Nokogiri::HTML(stwing)
          
          #  TODO  complain if no terminals?
          terminals = find_terminal_nodes(builder.doc)
          #  TODO  complain if found paths don't have the same root!
          
          terminals.each do |terminal|
            samples, refered = match_one_terminal(terminal)  #  TODO  return in different order
            if samples and refered
              @failure_message = complain_about(refered, samples)
              return false
            end
          end

          return true
        end
  #    end
    end

    def complain_about(refered, samples)
      "\nCould not find this reference...\n\n" +
        refered.to_html +
        "\n\n...in these sample(s)...\n\n" +  #  TODO  how many samples?
        samples.map{|s|s.to_html}.join("\n\n...or...\n\n")
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
      return matcher.builder.doc.to_html # TODO return something reasonable
    else
     _assert_xml(xhtml) # , XML::HTMLParser)
      return @xdoc
    end
  end
end
