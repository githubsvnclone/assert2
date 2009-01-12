require 'fileutils'

task :default do
  sh 'ruby1.8.6 test/rubynode_reflector_suite.rb'
  sh 'ruby1.9.0 test/ripper_reflector_suite.rb'
  sh 'ruby1.9.1 test/ripper_reflector_suite.rb'
  sh 'ruby1.8.6 test/assert2_suite.rb'
  sh 'ruby1.9.0 test/assert2_suite.rb'
  sh 'ruby1.9.1 test/assert2_suite.rb'
  sh 'ruby1.8.6 test/assert2_xpath_suite.rb'
  sh 'ruby1.9.0 test/assert2_xpath_suite.rb'
  sh 'ruby1.9.1 test/assert2_xpath_suite.rb'
  sh 'ruby1.8.6 test/assert2_utilities_suite.rb'
  # FIXME sh 'ruby1.8.7 test/assert2_utilities_suite.rb'
  sh 'ruby1.9.0 test/assert2_utilities_suite.rb'
  sh 'ruby1.9.1 test/assert2_utilities_suite.rb'
  sh 'ruby1.9.0 test/ripdoc_suite.rb'
  sh 'ruby1.9.1 test/ripdoc_suite.rb'
  
  # assert2_spec.rb   
 
#  #sh 'ruby1.8.6 test/assert2_shoulda_suite.rb'

end

task :int => :default do
  sh 'svn commit --message development'
end

task :zip => :default do
  sh 'zip assert21.zip -f'
end

task :todo do
  sh 'find . -name \*rb | xargs grep TODO'
end

task :fixme do
  sh 'find . -name \*rb | xargs grep FIXME'
end

task :fixme_files do
  sh 'find . -name \*rb | xargs grep FIXME -l'
end


# TODO  learn and install and use this!
#~ ruby crash.rb
#~ crash.rb:6:in `go2': unhandled exception
        #~ from crash.rb:11:in `go'
        #~ from crash.rb:15

#~ The new backtracer, however:

#~ ruby -rbacktracer crash.rb

#~ unhandled exception: crash.rb:6:   raise
        #~ locals: {"a"=>"3", "b"=>3, "within_go2"=>4}
          #~ from:
        #~ crash.rb:1 go2(a=>3, b=>55)
                #~ locals: {"a"=>"3", "b"=>3, "within_go2"=>4}
        #~ crash.rb:8 go(a=>3)
                #~ locals: {"a"=>"3", "within_go"=>2}
