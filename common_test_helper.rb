require 'pathname'

HomePath = (Pathname.new(__FILE__).dirname + '..').expand_path
Ruby186 = (HomePath + '../ruby1.8').expand_path
Ruby190 = (HomePath + '../ruby1.9').expand_path

if RUBY_VERSION < '1.9.0'
  $:.unshift Ruby186 + 'lib'  #  reach out to ruby1.8's assert{ 2.0 }
else
  $:.unshift Ruby190 + 'lib'  #  reach out to ruby1.9's assert{ 2.1 }
  require 'ripdoc'
end

require 'assert2'
