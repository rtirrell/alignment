require 'rubygems'
require 'rake'
require 'lib/alignment'


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

task :align, :filepath do |t, args|
  if args.filepath.nil?
    puts "No filepath given, exiting."
    exit(-1)
  end
  Alignment.parse(args.filepath)
end
