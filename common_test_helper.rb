require 'pathname'

TopPath = Pathname.new(__FILE__).dirname
Ruby186 = (TopPath + 'ruby1.8').expand_path
Ruby190 = (TopPath + 'ruby1.9').expand_path
DocPath = Ruby190 + 'doc'  #  TODO  use in more places

if RUBY_VERSION < '1.9.0'
  HomePath = Ruby186  #  reach out to ruby1.8's assert{ 2.0 }
else
  HomePath = Ruby190  #  reach out to ruby1.9's assert{ 2.1 }
end

$:.unshift((HomePath + 'lib').to_s)
require 'assert2'
