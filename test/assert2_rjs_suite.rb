require File.dirname(__FILE__) + '/test_helper'
require 'assert2/rjs'
require 'ostruct'
require 'action_controller'

# faux controller & tests SHAMELESSLY ripped off from Rich Poirier's assert_rjs test code!
require 'action_controller/test_process'  #  thanks, bra!


class AssertRjsSuite < Test::Unit::TestCase
  def setup
    @response = OpenStruct.new(:body => "Element.update(\"label_7\", \"<input checked=\\\"checked\\\" id=\\\"Top_Ranking\\\" name=\\\"Top_Ranking\\\" type=\\\"checkbox\\\" value=\\\"Y\\\" \\/>I want a pet &lt; than a chihuahua<input id=\\\"cross_sale_1\\\" name=\\\"cross_sale_1\\\" type=\\\"hidden\\\" value=\\\"7\\\" \\/>\");")
  end
  
  def test_assert_rjs_passes
    assert_rjs :replace_html, :label_7
    assert_rjs :replace_html, :label_7, /Top_Ranking/
    assert_rjs :replace_html, :label_7, /pet &lt; than a chihuahua/ # ERGO ouch!
    
    assert_rjs :replace_html, :label_7 do
      input.Top_Ranking! :type => :checkbox, :value => :Y
      input.cross_sale_1! :type => :hidden, :value => 7
    end
  end

  def test_assert_rjs_flunks
    assert_flunk /replace_html.for.ID.lay_belle_7.not.found.in .*
                       Top_Ranking/mx do
      assert_rjs :replace_html, :lay_belle_7
    end
    
    assert_flunk /replace_html.for.ID.label_7.has.incorrect.payload .*
                       Top_Ranking/mx do
      assert_rjs :replace_html, :label_7, /Toop_Roonking/
    end

    assert_flunk /replace_html.for.ID.label_7.has.incorrect.payload .*
                  Could.not.find.this.reference .* 
                     Top_Ranking/mx do
      assert_rjs :replace_html, :label_7 do
        input.Top_Ranking! :type => :checkbox, :value => :Y
        input.cross_sale_1! :type => :hidden, :valyoo => 7
      end
    end
  end

end


ActionController::Base.logger = nil
# ActionController::Base.ignore_missing_templates = false
ActionController::Routing::Routes.reload rescue nil
 
class AssertRjsStubController < ActionController::Base
  def alert
    render :update do |page|
      page.alert 'This is an alert'
    end
  end
  
  def assign
    render :update do |page|
      page.assign 'a', '2'
    end
  end
  
  def call
    render :update do |page|
      page.call 'foo', 'bar', 'baz'
    end
  end
  
  def draggable
    render :update do |page|
      page.draggable 'my_image', :revert => true
    end
  end
  
  def drop_receiving
    render :update do |page|
      page.drop_receiving "my_cart", :url => { :controller => "cart", :action => "add" }
    end
  end
    
  def hide
    render :update do |page|
      page.hide 'some_div'
    end
  end
  
  def insert_html
    render :update do |page|
      page.insert_html :bottom, 'content', 'Stuff in the content div'
    end
  end
  
  def redirect
    render :update do |page|
      page.redirect_to :controller => 'sample', :action => 'index'
    end
  end
  
  def remove
    render :update do |page|
      page.remove 'offending_div'
    end
  end
  
  def replace
    render :update do |page|
      page.replace 'person_45', '<div>This replaces person_45</div>'
    end
  end
  
  def replace_html
    render :update do |page|
      page.replace_html 'person_45', 'This goes inside person_45'
    end
  end
  
  def show
    render :update do |page|
      page.show 'post_1', 'post_2', 'post_3'
    end
  end
  
  def sortable
    render :update do |page|
      page.sortable 'sortable_item'
    end
  end
  
  def toggle
    render :update do |page|
      page.toggle "post_1", "post_2", "post_3"
    end
  end
  
  def visual_effect
    render :update do |page|
      page.visual_effect :highlight, "posts", :duration => '1.0'
    end
  end
  
  def page_with_one_chained_method
    render :update do |page|
      page['some_id'].toggle
    end
  end
  
  def page_with_assignment
    render :update do |page|
      page['some_id'].style.color = 'red'
    end
  end
  
  def rescue_errors(e) raise e end
 
end


class AssertRjsStubControllerSuite < ActionController::TestCase
  tests AssertRjsStubController
  
  def test_assert_rjs_misses_its_response_body
     #  TODO  test that a missing response_body provides a good error
  end

  # ERGO add "interrupt-and-integrate" to autotask
  # TODO  test all their return values

  def test_alert
    get :alert
    rjs = AssertRjs.new(js = @response.body)
    text = rjs.alert :alert, 'This is an alert'
    assert{ text == 'This is an alert' }
    text = rjs.alert :alert, 'This is not an alert'
    deny{ text }
    
    assert_rjs :alert, 'This is an alert'
    
  end


  def test_assign
    get :assign
    
#     assert_nothing_raised { assert_rjs :assign, 'a', '2' }
#     assert_raises(Test::Unit::AssertionFailedError) do
#       assert_rjs :assign, 'a', '3'
#     end
#     
#     assert_nothing_raised { assert_no_rjs :assign, 'a', '3' }
#     assert_raises(Test::Unit::AssertionFailedError) do
#       assert_no_rjs :assign, 'a', '2'
#     end
  end
  
  def test_call
    get :call
    
#     assert_nothing_raised { assert_rjs :call, 'foo', 'bar', 'baz' }
#     assert_raises(Test::Unit::AssertionFailedError) do
#       assert_rjs :call, 'foo', 'bar'
#     end
#     
#     assert_nothing_raised { assert_no_rjs :call, 'foo', 'bar' }
#     assert_raises(Test::Unit::AssertionFailedError) do
#       assert_no_rjs :call, 'foo', 'bar', 'baz'
#     end
  end
  
  def test_draggable
    get :draggable
    
#     assert_nothing_raised { assert_rjs :draggable, 'my_image', :revert => true }
#     assert_raises(Test::Unit::AssertionFailedError) do
#       assert_rjs :draggable, 'not_my_image'
#     end
#     
#     assert_nothing_raised { assert_no_rjs :draggable, 'not_my_image' }
#     assert_raises(Test::Unit::AssertionFailedError) do
#       assert_no_rjs :draggable, 'my_image', :revert => true
#     end
  end

end

# "It's a big house this, and very peculiar.  Always a bit more to discover,
#  and no knowing what you'll find around a corner.  And Elves, sir!" --Samwise

# "Sam? Would you please STFU??" --Frodo