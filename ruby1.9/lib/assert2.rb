#  this is assert{ 2.1 }, the Ruby 1.9+ rewrite of assert{ 2.0 }, using Ripper
#   note we only work with Ruby >= 1.9 !

if RUBY_VERSION < '1.9.0'
  puts "\nWarning: This version of assert{ 2.0 } only works\n" +
       "with Ripper, which requires a Ruby version >= 1.9\n\n"
end

require 'assert2/common/assert2_utilities'

#  TODO  install Coulor
#  TODO  add :verbose => option to assert{}
#  TODO  pay for Staff Benda Bilili  ALBUM: Tr�s Tr�s Fort (Promo Sampler) !
#  FIXME  express linefeeds in string results correctly

module Test; module Unit; module Assertions

  def colorize(whatever)
    # TODO stop ignoring this and start colorizing v2.1!
  end

  def __reflect_assertion(called, options, block, got)
    effect = RubyReflector.new(called)
    effect.args = *options[:args]
    return [effect.reflect_assertion(block, got)]
  end

  #!doc!
  def diagnose(diagnostic = nil, got = nil, called = caller[0],
                options = {}, block = nil)                    #  FIXME  make this directly callable
    options = { :args => [] }.merge(options)
     # CONSIDER only capture the block_vars if there be args?
    @__additional_diagnostics.unshift diagnostic
    __evaluate_diagnostics
    report = @__additional_diagnostics.uniq + __reflect_assertion(called, options, block, got)
    return report.compact.join("\n")
  end

end; end; end

require '../test/assert2_suite.rb' if $0 == __FILE__ and File.exist?('../test/assert2_suite.rb')
#require 'ripdoc_suite.rb' if $0 == __FILE__ and File.exist?('ripdoc_suite.rb')

class File
  def self.write(filename, contents)
    open(filename, 'w'){|f|  f.write(contents)  }
  end
end
