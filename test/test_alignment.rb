require 'helper'
require 'lib/alignment'

class TestAlignment < Test::Unit::TestCase
  def test_examples
    Dir.glob("data/{examples,for_quiz}/*.input").each do |in_filepath|
      alignment = Alignment.align_file(in_filepath)
      out_filepath = get_out_filepath(in_filepath)
      next if !File.exists?(out_filepath)
      cscore, calignments = parse_output(out_filepath)
      
      assert_equal(
        calignments.uniq.sort, 
        alignment.alignments.uniq.sort,
        "Alignments not equal at #{in_filepath}."
      )
      assert_in_delta(
        cscore, 
        alignment.score, 
        0.001,
        "Scores not equal at #{in_filepath}."
      )
    end
  end
end
