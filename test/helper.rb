require 'rubygems'
require 'test/unit'
require 'lib/alignment'

def get_out_filepath(in_filepath)
  return in_filepath[0...in_filepath.rindex(".")] + ".output"
end

def parse_output(filepath)
  score = 0
  alignments = open(filepath).map do |line|
    score = line.strip.to_f if line =~ /^[\d\.]+$/
    line.strip if line =~ /^[A-Z_]+$/
  end
  
  [score, alignments.compact.each_slice(2).to_a]
end