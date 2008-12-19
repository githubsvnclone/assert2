require 'test/unit'
#require 'xml'
require 'rexml/document'
require 'rexml/entity'
require 'rexml/formatters/pretty'

module Test; module Unit; module Assertions
  
  def assert_xhtml(xhtml)
    return _assert_xml(xhtml) # , XML::HTMLParser)
  end 

  def _assert_xml(xml) #, parser = XML::Parser)
    if false
      xp = parser.new()
      xp.string = xml
      
      if XML.respond_to? :'default_pedantic_parser='
        XML.default_pedantic_parser = true
      else
        XML::Parser.default_pedantic_parser = true
      end  #  CONSIDER  uh, figure out the best libxml-ruby??
      
      @xdoc = xp.parse.root
      return @sauce = xml
    else
      #  CONSIDER  figure out how entities are supposed to work!!
      xml = xml.gsub('&mdash;', '--')
      doc = REXML::Document.new(xml)
      @xdoc = doc.root
      return @sauce = xml  #  TODO  still need this??
    end
  end 

  class AssertXPathArguments
    
    def initialize()
      @subs = {}
      @xpath = ''
    end
    
    attr_reader :subs
    attr_reader :xpath
    
    def to_conditions(hash)
      xml_attribute_name = /^[a-z][_a-z0-9]+$/i  #  CONSIDER is that an XML attribute name match?
      
      @xpath << hash.map{|k, v|
                  sk = k.to_s
                  sk = '_text' if sk == '.'
                  @subs[sk] = v.to_s
                  "#{ '@' if k.to_s =~ xml_attribute_name }#{k} = $#{sk}" 
                }.join(' and ')
    end
    
    def to_predicate(hash, options)
      hash = { :id => hash } if hash.kind_of? Symbol
      hash.merge! options
      @xpath << '[ '
      to_conditions(hash)
      @xpath << ' ]'
    end

    def to_xpath(path, id, options)
      @xpath = path
      @xpath = "descendant-or-self::#{ @xpath }" if @xpath.kind_of? Symbol
      to_predicate(id, options) if id
    end

  end

    # if node = @xdoc.find_first(path) ## for libxml
    #  def node.text
    #    find_first('text()').to_s
    #  end

  def xpath(path, id = nil, options = {}, &block)
    former_xdoc = @xdoc
    apa = AssertXPathArguments.new
    apa.to_xpath(path, id, options)
    node = REXML::XPath.first(@xdoc, apa.xpath, nil, apa.subs)
    
    add_diagnostic :clear do
      bar = REXML::Formatters::Pretty.new
      out = String.new
      bar.write(@xdoc, out)
      diagnostic = "xpath: #{ apa.xpath.inspect }\n"
      diagnostic << "arguments: #{ apa.subs.pretty_inspect }\n" if apa.subs.any?
      diagnostic + "xml context:\n" + out
    end
    
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

require '../../test/assert_xhtml_suite.rb' if $0 == __FILE__ and File.exist?('../../test/assert_xhtml_suite.rb')
