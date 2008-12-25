require 'fileutils'

task :int do
  FileUtils.cd 'ruby1.8' do
    system 'rake'
  end
  
  FileUtils.cd 'ruby1.9' do
    system 'rake'
  end
  
  sh 'svn commit --message development'
  sh 'svn update --quiet'
end