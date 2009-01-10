require 'fileutils'

task :default do
  FileUtils.cd 'ruby1.8' do
    return false unless sh('rake')
  end
  
  FileUtils.cd 'ruby1.9' do
    return false unless sh('rake')
  end
end

task :int => :default do
  sh 'svn commit --message development ruby1.8/lib/assert2/common'
  sleep 1
  sh 'svn commit --message development ruby1.9/lib/assert2/common'
  sleep 1
  sh 'svn commit --message development'
  sleep 1
  sh 'svn update --quiet'
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

