require File.dirname(__FILE__) + '/test_helper'
require 'assert2/rjs'
require 'ostruct'

class AssertRjsSuite < Test::Unit::TestCase
  
  def test_assert_rjs
    @response = OpenStruct.new(:body => "Element.update(\"label_7\", \"<input checked=\\\"checked\\\" id=\\\"Top_Ranking\\\" name=\\\"Top_Ranking\\\" type=\\\"checkbox\\\" value=\\\"Y\\\" \\/>I want a pet &lt; than a chihuahua<input id=\\\"cross_sale_1\\\" name=\\\"cross_sale_1\\\" type=\\\"hidden\\\" value=\\\"7\\\" \\/>\");")
    
    assert_rjs :replace_html, :label_7
    assert_rjs :replace_html, :label_7, /Top_Ranking/
  end
  
end
