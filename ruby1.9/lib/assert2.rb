require 'assert2/assertion_ripper'  #   note we only work with Ruby >= 1.9 !

  # note there's more requires down there --V

#  TODO  feel the need for serious ncursage
#  TODO  add :verbose => option to assert{}
#  TODO  ripdoc and RDoc should peacibly coexist
#  TODO  express linefeeds in string results correctly
#  TODO  assertion ripper tests

module Test; module Unit; module Assertions

  def __reflect_assertion(called, options, block, got)
    effect = AssertionRipper.new(called)
    effect.args = *options[:args]
    return [effect.reflect_assertion(block, got)]
  end
    
  #!doc!
  def diagnose(diagnostic = nil, got = nil, called = caller[0],
                options = {}, block)
    options = { :args => [], :diagnose => lambda{''} }.merge(options)
     #  only capture the block_vars if there be args?
    @__additional_diagnostics.unshift diagnostic
    __evaluate_diagnostics
    report = @__additional_diagnostics.uniq + __reflect_assertion(called, options, block, got)
    more_diagnostics = options.fetch(:diagnose, lambda{''}).call.to_s
    report << more_diagnostics if more_diagnostics.length > 0
    return report.compact.join("\n")
  end

  def assert_(diagnostic = nil, options = {}, &block)
    @__additional_diagnostics = []
    
    begin
      got = block.call(*options[:args]) and return got
    rescue => got
      add_exception got
    end    

    flunk diagnose(diagnostic, got, caller[1], options, block)
  end

  def add_exception(ex)
    ex.backtrace[0..10].each do |line|
      add_diagnostic '  ' + line
    end
  end

  #  This assertion replaces:
  #  
  #  - +assert_nil+
  #  - +assert_no_match+
  #  - +assert_not_equal+
  #
  #  It faults, and prints its block's contents and values,
  #  if its block returns non-+false+ and non-+nil+.
  #  
  def deny(diagnostic = nil, options = {}, &block)
      #  "None shall pass!" --the Black Knight
    
    @__additional_diagnostics = []
    
    begin
      got = block.call(*options[:args]) or return
    rescue => got
      add_exception got
    end
  
    flunk diagnose(diagnostic, got, caller[0], options, block)
  end  #  "You're a looney!"  -- King Arthur
  
end; end; end

require File.dirname(__FILE__) + '/common/assert2_utilities'

require '../test/assert2_suite.rb' if $0 == __FILE__ and File.exist?('../test/assert2_suite.rb')
#require 'ripdoc_suite.rb' if $0 == __FILE__ and File.exist?('ripdoc_suite.rb')

class File
  def self.write(filename, contents)
    open(filename, 'w'){|f|  f.write(contents)  }
  end
end
