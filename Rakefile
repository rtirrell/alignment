require 'rubygems'
require 'rake'
require 'lib/alignment'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "alignment"
    gem.summary = %Q{TODO: one-line summary of your gem}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email = "rpt@stanford.edu"
    gem.homepage = "http://github.com/rtirrell/alignment"
    gem.authors = ["Rob Tirrell"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

task :read_example_input do |t|
  Alignment.parse("data/ExampleInput2.txt")
end
