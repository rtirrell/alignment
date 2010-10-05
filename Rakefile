require 'rubygems'
require 'rake'
require 'lib/alignment'
require 'test/helper'
require 'fileutils'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

task :question_1 do |t|
  a = Alignment.align_file('data/for_quiz/alignment0.input')
  f = open('data/for_quiz/Question1.txt', 'w')
  f.puts("M")
  Alignment.print_matrix(a.m, f)
  
  f.puts("\nIx")
  Alignment.print_matrix(a.ix, f)
  
  f.puts("\nIy")
  Alignment.print_matrix(a.iy, f)
  
  f.puts("TM")
  Alignment.print_matrix(a.tm, f)
  
  f.puts("\nTx")
  Alignment.print_matrix(a.tx, f)
  
  f.puts("\nTy")
  Alignment.print_matrix(a.ty, f)
  
  a.alignments.each do |alignment|
    f.puts("\n" + alignment[0])
    f.puts(alignment[1])
  end
end
  
task :gather_quiz do |n|
  (Dir.glob('data/for_quiz/*output.mine') + 
   Dir.glob('data/for_quiz/*.input')).each do |filepath|
    FileUtils.cp(
      filepath, 
      File.join('data/for_quiz/alignments', File.basename(filepath, '.mine'))
    )
  end
end

task :align, :filepath do |t, args|
  if args.filepath.nil?
    puts "No filepath given, exiting."
    exit(-1)
  end
  Alignment.align_file(args.filepath)
end
