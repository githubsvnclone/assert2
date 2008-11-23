require 'rubygems'
require 'test/spec'
require File.dirname(__FILE__) + '/../lib/assert2'

class Test::Spec::TestCase
  module ClassMethods
    include Assert_2_0
    def specify(specname, &block)
      raise ArgumentError, "specify needs a block"  if block.nil?

      self.count += 1                 # Let them run in order of definition

      nu_block = proc{ |*args| 
                     begin

                      block.call

                   rescue Test::Unit::AssertionFailedError => e
                    p e.inspect
                    raise e
                  end
                  }
      define_method("test_spec {%s} %03d [%s]" % [name, count, specname], &nu_block)
        #~ block.call
      #~ end
    end
  end
end

context 'bond assert{ 2.0 } with test/spec' do


  setup{ colorize(true) }

  specify 'a simple passing assertion works' do
    x = 42
    assert{ x == 42 }
  end
  
  specify 'a simple passing deny works' do
    x = 42
    deny{ x == 43 }
  end

    #~ def messaging(message)
      #~ @message = message.to_s
      #~ self
    #~ end

  specify 'decorate should' do
#    assert_raise_message Test::Unit::AssertionFailedError, /foo.should.equal/ do
      foo = 42
      foo.should.equal 43
#    end
  end

end


