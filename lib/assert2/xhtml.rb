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

First, we take care of the paperwork. This spec works with Yuri's
sample website. I add Nokogiri, for our XML engine:
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
      node.xpath('ancestor-or-self::*').
        map{|n|n}
    end  #  TODO  stop throwing away NodeSet abilities!
    
    def decorate_path(node_list) # pathmark(node)
      index = -1
      
      return '//' + node_list.map{|node|
                        node.name + "[refer(., #{ index += 1 })]"
                      }.join('/descendant::')
    end

    def match_attributes
      @reference.attribute_nodes.each do |attr|
        @sample[attr.name] == attr.value or return false
      end
            
      return true
    end

    def match_one_terminal(terminal)
      references = pathmark(terminal)
      path = decorate_path(references)
      lowest_samples = []
      @reference = nil
      
      matches = @doc.xpath_callback(path, :refer) do |nodes, index|
        samples = nodes.find_all{|sample|
          @reference = references[index]
          @sample = sample
          match_text and match_attributes
        }
        lowest_samples = samples if samples.any?
        samples
      end

      return nil if matches.any?
      return lowest_samples, @reference
    end
     
    def match_text(sam = @sample, ref = @reference)  #  TODO  better testing
      ref_text = ref.xpath('text()').map{|x|x.to_s.strip}
      sam_text = sam.xpath('text()').map{|x|x.to_s.strip}
        #  TODO regices? zero-len strings?
      ( sam_text - ref_text ).empty?
    end

    attr_accessor :doc
    
    def matches?(stwing, &block)
   #   @scope.wrap_expectation self do  #  TODO  put that back online
        begin
          bwock = block || @block || proc{}
          builder = Nokogiri::HTML::Builder.new(&bwock)
          match = builder.doc.root
          @doc = Nokogiri::HTML(stwing)
          
          #  TODO  complain if no terminals?
          terminals = find_terminal_nodes(builder.doc)
          #  TODO  complain if found paths don't have the same root!
          
          terminals.each do |terminal|
            match_one_terminal(terminal)
          end
          
          @last_match = 0
          @failure_message = match_nodes(match, @doc)
          return @failure_message.nil?
        end
  #    end
    end

    def complain_about(refered, samples)
      "\n\nCould not find this reference...\n\n" +
      refered.to_html +
      "\n\n...in these reference(s)...\n\n" +
      samples.map{|s|s.to_html}.join("\n\n...or...\n\n")
    end
 
 #  TODO does a multi-modal top axis work?
 
    def match_nodes(match, doc)
      tag = match.name.sub(/\!$/, '')
      
      node = doc.xpath("descendant::#{tag}").
                select{|n| resemble(match, n) }.
                first or return complaint(match, doc)

      this_match = node.xpath('preceding::*').length
      
      if @last_match > this_match
        return complaint(match, doc, 'node is out of specified order!')
      end

      @last_match = this_match

      match.xpath('*').each do |child|
        issue = match_nodes(child, node) and 
          return issue
      end

      return nil
    end

      # http://www.zvon.org/xxl/XPathTutorial/Output/example18.html
      # The preceding axis contains all nodes in the same document 
      # as the context node that are before the context node in 
      # document order, excluding any ancestors and excluding 
      # attribute nodes and namespace nodes 

#p [node.name, node.text]
# p node.path if lastest
#p node.text
# p lastest.path if lastest
    
=begin
At any point in that recursion, if we can't find a match,
we build a string describing that situation, and pass it
back up the call stack. This immediately stops any iterating
and recursing underway!

Two nodes "resemble" each other if their names are the
same (naturally!); if your matching element's
attributes are a subset of your page's element's 
attributes, and if their text is similar:
=end

    def resemble(match, node)
      keys = match.attributes.keys
      node_keys = valuate(node.attributes.select{|k,v| keys.include? k })
      match_keys = valuate(match.attributes)
      node_keys == match_keys or return false
        
    #  TODO  try
#       match_text = match.xpath('text()').map{|x|x.to_s}
#        node_text = match.xpath('text()').map{|x|x.to_s}

      match_text = match.children.grep(Nokogiri::XML::Text).map{|t| t.to_s.strip }
       node_text = node .children.grep(Nokogiri::XML::Text).map{|t| t.to_s.strip }
      match_text.empty? or 0 == ( match_text - node_text ).length
    end

=begin
That method cannot simply compare node.text, because Nokogiri
conglomerates all that node's descendants' texts together, and
these would gum up our search. So those elaborate lines with
grep() and map() serve to extract all the current node's 
immediate textual children, then compare them as sets.

Put another way, <form> does not appear to contain "First name".
Specifications can only match text by declaring their immediate 
parent.

The remaining support methods are self-explanatory. They
prepare Node attributes for comparison, build our diagnostics,
and plug our matcher object into RSpec:
=end
 
    def valuate(attributes)
      attributes.inject({}) do |h,(k,v)| 
        h.merge(k => v.value) 
      end  #  this converts objects to strings, so our Hashes
    end    #  can compare for equality

    def complaint(node, match, berate = nil)
      "\n    #{berate}".rstrip +
      "\n\n#{node.to_html}\n" +
          "    does not match\n\n" +
           match.to_html
    end

    attr_accessor :failure_message
 
    def negative_failure_message
      "yack yack yack"
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
    else
     _assert_xml(xhtml) # , XML::HTMLParser)
      return @xdoc
    end
  end
end
