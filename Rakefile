require 'fileutils'

task :int do
  FileUtils.cd 'ruby1.8' do
    sh 'rake'
  end
  
  FileUtils.cd 'ruby1.9' do
    sh 'rake'
  end
  
  sh 'svn commit --message development'
  sh 'svn update --quiet'
end