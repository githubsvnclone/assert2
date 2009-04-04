$:.unshift '~/projects/ruby/rkelly/lib'  #  TODO  correct path!
require 'rkelly'

module Test; module Unit; module Assertions

  def assert_rjs(command, target)
    ast = RKelly.parse(@response.body)
      #  TODO  visit the parsed code via the command, and assert it, here
#puts ast.public_methods.sort

    p element = ast.pointcut('Element').matches.first
  end

end; end; end