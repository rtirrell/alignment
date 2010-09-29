require 'helper'
require 'lib/alignment'

class TestAlignment < Test::Unit::TestCase
  def test_examples
    [0, 1, 2, 3, 4, 5, 6].each do |i|
      puts "Testing alignment #{i}."
      in_filepath = File.join('data/examples', "alignment_example#{i}.input")
      out_filepath = File.join('data/examples', "alignment_example#{i}.output")
      
      alignment = Alignment.align_file(in_filepath)
      correct_score, correct_alignments = parse_output(out_filepath)
      assert_equal(correct_alignments.sort, alignment.alignments.uniq.sort)
      #assert_in_delta(correct_score, alignment.score, 0.001)
    end
  end
end
