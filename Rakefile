require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

ProjectName = 'hammock'
Version = '0.2.5'

module Rake::TaskManager
  def delete_task(task_class, *args, &block)
    task_name, deps = resolve_args(args)
    @tasks.delete(task_class.scope_name(@scope, task_name).to_s)
  end
end
class Rake::Task
  def self.delete_task(args, &block) Rake.application.delete_task(self, args, &block) end
end
def delete_task(args, &block) Rake::Task.delete_task(args, &block) end

begin
  require 'rubygems'
  gem 'echoe', '>=2.7'
  ENV['RUBY_FLAGS'] = ""
  require 'echoe'

  Echoe.new(ProjectName, Version) do |p|
    p.summary        = "Radically RESTful Rails."
    p.description    = "Hammock replaces redundant controller code with model-style callbacks that hook model-agnostic restful actions, tackles security, resource lookups and context-aware link generation in one movement, and makes drop-on-top XHR too easy not to use."
    p.url            = "http://github.com/benhoskings/#{ProjectName}"
    p.author         = 'Ben Hoskings'
    p.email          = "ben@hoskings.net"
    p.ruby_version   = '~>1.8.6'
    p.ignore_pattern = /^(\.git).+/
    p.test_pattern   = 'test/*_test.rb'
    p.dependencies ||= []
    p.dependencies  << 'ambition ~>0.5.4'
    p.dependencies  << 'ambitious_activerecord ~>0.1.3'
  end

rescue LoadError
  puts "Not doing any of the Echoe gemmy stuff, because you don't have the specified gem versions"
end

delete_task :test
delete_task :install_gem

Rake::TestTask.new('test') do |t|
  t.pattern = 'test/*_test.rb'
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Generate RDoc documentation'
Rake::RDocTask.new(:rdoc) do |rdoc|
  files = ['README.rdoc', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main     = "README.rdoc"
  rdoc.title    = ProjectName
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--inline-source'
end

desc 'Generate coverage reports'
task :rcov do
  `rcov -e gems test/*_test.rb`
  puts 'Generated coverage reports.'
end

desc 'Install as a gem'
task :install_gem do
  puts `rake manifest package && gem install pkg/#{ProjectName}-#{Version}.gem`
end
