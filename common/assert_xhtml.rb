require 'test/unit'
require 'xml'
# TODO  require 'pp'?

module Test; module Unit; module Assertions
  
  def assert_xhtml(xhtml)
    return _assert_xml(xhtml, XML::HTMLParser) #  TODO  if this bombs invoke the XML parser 
                                #         but explain stuff might not work
  end 

  def _assert_xml(xml, parser = XML::Parser)
    xp = parser.new()
    xp.string = xml
    if XML.respond_to? :'default_pedantic_parser='
      XML.default_pedantic_parser = true
    else
      XML::Parser.default_pedantic_parser = true
    end  #  CONSIDER  uh, figure out the best libxml-ruby??
    @xdoc = xp.parse.root
    return @sauce = xml
  end 

  class AssertXPathArguments
    
    def to_conditions(hash)
      xml_identifier = /^[a-z][_a-z0-9]+$/i  #  CONSIDER is that an XML identifier match?
      return hash.map{|k, v| 
                "#{ '@' if k.to_s =~ xml_identifier }#{k} = '#{v}'" 
              }.join(' and ')
    end
    
    def to_predicate(hash, options)
      hash = { :id => hash } if hash.kind_of? Symbol
      hash.merge! options
      return "[ #{ to_conditions(hash) } ]"
    end

    def to_xpath(path, id, options)
      path = "descendant-or-self::#{path}" if path.kind_of? Symbol
        #  TODO  cover id, hash
             #  TODO  escape ' and " correctly - if possible!
      path << to_predicate(id, options) if id
      return path
    end

  end

  def xpath(path, id = nil, options = {}, &block)
    former_xdoc = @xdoc
    path = AssertXPathArguments.new.to_xpath(path, id, options)
    if node = @xdoc.find_first(path)
      def node.text
        find_first('text()').to_s
      end
    end

    add_diagnostic :clear
    add_diagnostic "xpath context:\n" + @xdoc.to_s
    assert_ nil, :args => [@xdoc = node], &block if node and block
    return node
    # TODO raid http://thebogles.com/blog/an-hpricot-style-interface-to-libxml/
  ensure
    @xdoc = former_xdoc
  end  #  TODO trap LibXML::XML::XPath::InvalidPath and explicate it's an XPath problem
 
  def indent_xml
    @xdoc.write($stdout, 2)
  end
  
end; end; end

require '../test/assert_xhtml_test.rb' if $0 == __FILE__ and File.exist?('../test/assert_xhtml_test.rb')
