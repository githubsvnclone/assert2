require 'fileutils'

task :default do
  sh 'ruby186 test/rubynode_reflector_suite.rb'
#  sh 'ruby190 test/ripper_reflector_suite.rb'
  sh 'ruby191 test/ripper_reflector_suite.rb'
  
  sh 'ruby186 test/assert2_suite.rb'
#  sh 'ruby190 test/assert2_suite.rb'
  sh 'ruby191 test/assert2_suite.rb'
  
  sh 'ruby186 test/assert2_xpath_suite.rb'
#  sh 'ruby187 test/assert2_xpath_suite.rb'
#  sh 'ruby190 test/assert2_xpath_suite.rb'
#  sh 'ruby191 test/assert2_xpath_suite.rb'
  
  sh 'ruby186 test/assert2_utilities_suite.rb'
#  sh 'ruby187 test/assert2_utilities_suite.rb'
#  sh 'ruby190 test/assert2_utilities_suite.rb'
  sh 'ruby191 test/assert2_utilities_suite.rb'
  
#  sh 'ruby190 test/ripdoc_suite.rb'
#  sh 'ruby191 test/ripdoc_suite.rb'
  
  # assert2_spec.rb   
 
# TODO  solve MiniTest too!
 
#  #sh 'ruby186 test/assert2_shoulda_suite.rb'

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

desc 'send docs to rubyforge.org'
task :publish do
 # sh 'scp -r rdoc/* phlip@assertxpath.rubyforge.org:/var/www/gforge-projects/assertxpath/'
  sh 'rsync -av -e ssh --exclude "*.svn" doc/* phlip@assert2.rubyforge.org:/var/www/gforge-projects/assert2/'
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
