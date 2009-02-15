require 'test/unit'
require 'pathname'

HomePath = (Pathname.new(__FILE__).dirname + '..').expand_path
DocPath = HomePath + 'doc'  #  TODO  use in more places

$:.unshift((HomePath + 'lib').to_s)
require 'assert2'
require 'assert2/flunk'  #  FIXME  assert_flunk{} could reflect (-:
