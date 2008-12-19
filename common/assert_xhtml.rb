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

  class AssertXPathArguments  #  TODO  another refactor party!
    
    def initialize()
      @subs = {}
    end
    
    attr_reader :subs
    
    def to_conditions(hash)
      xml_identifier = /^[a-z][_a-z0-9]+$/i  #  CONSIDER is that an XML identifier match?
      
      pred = hash.map{|k, v|
                sk = k.to_s
                sk = '_text' if sk == '.'
                @subs[sk] = v.to_s
                "#{ '@' if k.to_s =~ xml_identifier }#{k} = $#{sk}" 
              }.join(' and ')
              
      return pred
    end
    
    def to_predicate(hash, options)
      hash = { :id => hash } if hash.kind_of? Symbol
      hash.merge! options
      path = to_conditions(hash)
      return "[ #{ path } ]"
    end

    def to_xpath(path, id, options)
      path = "descendant-or-self::#{path}" if path.kind_of? Symbol
        #  TODO  cover id, hash
      path << to_predicate(id, options) if id
      return path
    end

  end

    # if node = @xdoc.find_first(path) ## for libxml
    #  def node.text
    #    find_first('text()').to_s
    #  end

  def xpath(path, id = nil, options = {}, &block)
    former_xdoc = @xdoc
    apa = AssertXPathArguments.new
    xpath = apa.to_xpath(path, id, options)
    # p xpath, apa.subs
    node = REXML::XPath.first(@xdoc, xpath, nil, apa.subs)
    
    add_diagnostic :clear do
      bar = REXML::Formatters::Pretty.new
      out = String.new
      bar.write(@xdoc, out)
#  TODO  spew the replacers if they b relevant
      "xpath: #{ xpath.inspect }\n" +
      "xml context:\n" + out
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
