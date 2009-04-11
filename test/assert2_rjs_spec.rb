require 'rubygems'
require 'test/spec'
require File.dirname(__FILE__) + '/../lib/assert2/rjs'

js = "Element.update(\"label_7\", \"<input checked=\\\"checked\\\" id=\\\"Top_Ranking\\\" name=\\\"Top_Ranking\\\" type=\\\"checkbox\\\" value=\\\"Y\\\" \\/>I want a pet &lt; than a chihuahua<input id=\\\"cross_sale_1\\\" name=\\\"cross_sale_1\\\" type=\\\"hidden\\\" value=\\\"7\\\" \\/>\");"

context 'send_js_to' do

  include Spec::Matchers

  specify 'a simple passing assertion works' do
    js.should send_js_to(:replace_html, 'label_7'){
                input.Top_Ranking!
                }
#     js.should not_send_js_to(:replace_html, 'label_6')
  end
  
end


