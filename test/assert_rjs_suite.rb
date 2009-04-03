$:.unshift '~/projects/ruby/rkelly/lib'  #  TODO  correct path!
require 'rkelly'
require 'test/unit'
require 'ostruct'

class AssertRjsSuite < Test::Unit::TestCase

  def assert_rjs(command, target)
    @_js = RKelly::Parser.new
    p @_js.parse(@response.body)
      #  TODO  visit the parsed code via the command, and assert it, here
  end
  
  def test_assert_rjs
    @response = OpenStruct.new(:body => "Element.update(\"label_7\", \"<input checked=\\\"checked\\\" id=\\\"Top_Ranking\\\" name=\\\"Top_Ranking\\\" type=\\\"checkbox\\\" value=\\\"Y\\\" \\/>I want a pet &lt; than a chihuahua<input id=\\\"cross_sale_1\\\" name=\\\"cross_sale_1\\\" type=\\\"hidden\\\" value=\\\"7\\\" \\/>\");")
    
    assert_rjs :replace_html, :label_7
  end
  
end
