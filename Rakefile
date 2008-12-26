require 'fileutils'

task :default do
  got = false 
  
  FileUtils.cd 'ruby1.8' do
    p '########################################## 1.8'
    got ||= sh('rake')
  end
  
  FileUtils.cd 'ruby1.9' do
    p '########################################## 1.9'
    got ||= sh('rake')
  end
end

task :int => :default do
  sh 'svn commit --message development'
  sh 'svn update --quiet'
end