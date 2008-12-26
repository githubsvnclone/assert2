require 'fileutils'

task :default do
  FileUtils.cd 'ruby1.8' do
    p '########################################## 1.8'
    return false unless sh('rake')
  end
  
  FileUtils.cd 'ruby1.9' do
    p '########################################## 1.9'
    return false unless sh('rake')
  end
end

task :int => :default do
  sh 'svn commit --message development'
  sh 'svn update --quiet'
end