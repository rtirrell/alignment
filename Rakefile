require 'rubygems'
require 'rake'
require 'lib/alignment'
require 'test/helper'


require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

task :align_example do |t|
  Alignment.print_matrix(
    Alignment.align_file("data/ExampleInput.txt").alignments.uniq
  )
end

task :align_problem do |t|
  as = Set.new(parse_output('data/examples/alignment_example3.output')[1].uniq.sort) - 
  Set.new(Alignment.align_file('data/examples/alignment_example_bad.input').alignments.uniq.sort)
  p as
end

task :align, :filepath do |t, args|
  if args.filepath.nil?
    puts "No filepath given, exiting."
    exit(-1)
  end
  Alignment.align_file(args.filepath)
end
