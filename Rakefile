require 'fileutils'

task :default do
  FileUtils.cd 'ruby1.8' do
    sh 'rake'
  end
  
  FileUtils.cd 'ruby1.9' do
    sh 'rake'
  end
end

task :int => :default do
  sh 'svn commit --message development'
  sh 'svn update --quiet'
end