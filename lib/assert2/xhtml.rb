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

=begin
That block after "response.body.should be_html_with" answers
Yuri's question. Any HTML we can think of, we can specify
it in there.

If we inject a fault, such as :name => 'user[first_nome]', we 
get this diagnostic:

  <input type="text" name="user[first_nome]">
  does not match
  <fieldset>
  <legend>Personal Information</legend>
      <ol>
  <li id="control_user_first_name">
          <label for="user_first_name">First name</label>
          <input type="text" name="user[first_name]" id="user_first_name">
  </li>
      </ol>
  </fieldset>

The diagnostic only reported the fault's immediate 
context - the <fieldset> where the matcher sought the 
errant <input> field. It would not, for example, spew
an entire website into our faces.

To support that specification, we will create a new
RSpec "matcher":
=end

  class BeHtmlWith
    
    class NodeMatcher
      def initialize(hits = [])
        @hits = hits
      end
 
      def match_text(node, hit)
        node_text = node.xpath('text()').map{|x|x.to_s.strip}
        hits_text = hit. xpath('text()').map{|x|x.to_s.strip}
          #  TODO regices? zero-len strings?
        ( hits_text - node_text ).length == 0
      end

    end
    
    def find_terminal_nodes(doc)
      doc.xpath('//*[ not(./descendant::*) ]').
        map{|n|n}
#           while n.class == Nokogiri::XML::Text 
#             n = n.parent
#           end
#           n }
    end

    def pathmark(node)
      path = node.xpath('ancestor-or-self::*')
      return path.map{|n|n}
    end  #  TODO  stop throwing away NodeSet abilities!
    
    def decorate_path(node_list) # pathmark(node)
      path = '//' + node_list[0].name + '[hits(., 0)]'
      
      node_list[1..-1].each_with_index do |node, index|
        index += 1
        path << '/descendant::' + node.name + "[hits(., #{index})]"
      end
      
      return path
    end

    def matches?(stwing, &block)
   #   @scope.wrap_expectation self do
        begin
          bwock = block || @block || proc{}
          builder = Nokogiri::HTML::Builder.new(&bwock)
          match = builder.doc.root
          doc = Nokogiri::HTML(stwing)
          
          #  TODO  complain if no terminals?
          terminals = find_terminal_nodes(builder)
          
          terminals.each do |terminal|
#            nodes = pathmark(terminal)
#             nm = NodeMatcher.new(nodes)
#             path = decorate_path(nodes)
#             p path
          end
          
          @last_match = 0
          @failure_message = match_nodes(match, doc)
          return @failure_message.nil?
        end
  #    end
    end

=begin
The trick up our sleeve is Nokogiri::HTML::Builder. We passed
the matching block into it - that's where all the 'form', 
'fieldset', 'input', etc. elements came from. And this trick 
exposes both our target page and our matched elements to the 
full power of Nokogiri. Schema validation, for example, would 
be very easy.

The matches? method works by building two DOMs, and forcing
our page's DOM to satisfy each element, attribute, and text
in our specification's DOM.

To match nodes, we first find all nodes, by name, below
the current node. Note that match_nodes() recurses. Then
we throw away all nodes that don't satisfy our matching
criteria.

We pick the first node that passes that check, and 
then recursively match its children to each child,
if any, from our matching node.
=end
 
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
  end

module Test::Unit::Assertions
  def assert_xhtml(xhtml = @response.body, &block)  # TODO merge
   _assert_xml(xhtml) # , XML::HTMLParser)
    if block
     # require 'should_be_html_with_spec'
      matcher = BeHtmlWith.new(self, &block)
      matcher.matches?(xhtml, &block)
      message = matcher.failure_message
      flunk message if message.to_s != ''
    end
    return @xdoc
  end
end
