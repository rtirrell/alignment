require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'alignment'

class Test::Unit::TestCase
end

def parse_output(filepath)
  score = 0
  alignments = open(filepath).map do |line|
    score = line.strip.to_f if line =~ /^[\d\.]+$/
    line.strip if line =~ /^[A-Z_]+$/
  end
  
  [score, alignments.compact.each_slice(2).to_a]
#  alignments = []
#  open(filepath).each do |line|
#    if line =~ /^[\d\.]+$/
#    elsif line =~ /^$/
#      alignments << []
#    else
#      alignments[-1] << line.strip
#    end
#  end
#  p "lines", alignments
#  return alignments
end