require 'fileutils'

task :default do
  got = false 
  
  FileUtils.cd 'ruby1.8' do
    got ||= sh('rake')
  end
  
  FileUtils.cd 'ruby1.9' do
    got ||= sh('rake')
  end
end

task :int => :default do
  sh 'svn commit --message development'
  sh 'svn update --quiet'
end