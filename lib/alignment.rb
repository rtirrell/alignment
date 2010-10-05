require "set"

class Alignment
  attr_reader :align_globally, :alignments, :score
  attr_reader :m, :ix, :iy, :tm, :tx, :ty
  
  def initialize(a, b, align_globally, gap_penalties, nx, ax, ny, ay, s)
    # First sequence.
    @a = a.split("")
    @nx = @a.size

    # Second sequence.
    @b = b.split("")
    @ny = @b.size

    # Alignment parameters.
    @align_globally = align_globally
    @dx, @ex, @dy, @ey = gap_penalties

    # Alphabet for each sequence.
    @ax = ax
    @ay = ay

    # Match matrix.
    @s = s
    
    # All alignments.
    @alignments = []
      
    # M tracks the best score of an alignment ending in A[i], B[j]
    # Then M[i, j] = max(
    #                      M [i - 1, j - 1] + s(A[i], B[j])
    #                      Ix[i - 1, j - 1] + s(A[i], B[i])
    #                      Iy[i - 1, j - 1] + s(A[i], B[i])
    #                   )
    @m  = matrix {0}
    @tm = matrix {[]}

    # Ix tracks the best score when A[< i] aligns to B[j]
    # Then Ix[i, j] = max(
    #                       M [i - 1, j] - d
    #                       Ix[i - 1, j] - e
    #                    )
    @ix = matrix {0}
    @tx = matrix {[]}

    # Ix tracks the best score when A[i] aligns to B[< j]
    # Then Iy[i, j] = max(
    #                       M [i, j - 1] - d
    #                       Iy[i, j - 1] - e
    #                    )
    @iy = matrix {0}
    @ty = matrix {[]}
      
    @ts = {:m => [@m, @tm], :x => [@ix, @tx], :y => [@iy, @ty]}
    
    # Initialization code seems to be unnecessary.
#    if @align_globally
#      (1..@nx).each do |i|
#        @ix[i][0] = -@dy * [i, 1].min - @ey * [i - 1, 0].max
#      end
#      (1..@ny).each do |j|
#        @iy[0][j] = -@dx * [j, 1].min - @ex * [j - 1, 0].max
#      end
#    end
      
    # Iterate over columns. Collect traceback information now, to be used after
    # we're done aligning. Pretty straightforward, I hope.
    (1..@nx).each do |i|
      (1..@ny).each do |j|
        m_choices = [
          [@m [i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :m]],
          [@ix[i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :x]],
          [@iy[i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :y]]
        ]
        choose_top(i, j, :m, m_choices)
       
        ix_choices = [
          [@m [i - 1][j] - @dy, [i - 1, j, :m]],
          [@ix[i - 1][j] - @ey, [i - 1, j, :x]]
        ]
        choose_top(i, j, :x, ix_choices)

        iy_choices = [
          [@m [i][j - 1] - @dx, [i, j - 1, :m]],
          [@iy[i][j - 1] - @ex, [i, j - 1, :y]]
        ]
        choose_top(i, j, :y, iy_choices)
      end
    end

    @score = @m[@nx][@ny]
    @max_cells = Set.new

    if @align_globally
      # Check last row.
      (0..@ny).each do |j|
        if in_delta?(@m[@nx][j], @score)
          @max_cells << [@nx, j]
        elsif @m[@nx][j] > @score
          @max_cells.clear
          @max_cells << [@nx, j]
          @score = @m[@nx][j]
        end
      end

      # Check last column.
      (0..@nx).each do |i|
        if in_delta?(@m[i][@ny], @score)
          @max_cells << [i, @ny]
        elsif @m[i][@ny] > @score
          @max_cells.clear
          @max_cells << [i, @ny]
          @score = @m[i][@ny]
        end
      end
      
    else
      # This is local, so check every cell.
      (0..@nx).each do |i|
        (0..@ny).each do |j|
          if in_delta?(@m[i][j], @score)
            @max_cells << [i, j]
          elsif @m[i][j] > @score
            @max_cells.clear
            @max_cells << [i, j]
            @score = @m[i][j]
          end
        end
      end
    end

    # Collect the tracebacks starting from each max-score cell.
    @max_cells.to_a.each do |max_cell|
      traceback(max_cell[0], max_cell[1], :m).each do |alignment|
        @alignments << alignment
      end
    end
  end
  
  ##
  # Starting from an [i, j, tn] cell, traceback returns a list of alignments
  # beginning from that cell. Whenever a branching cell is encountered, call
  # recursively to get a list of alignments from each branch separately.
  def traceback(i, j, tn) 
    alignment = ["", ""]
      
    loop do
      t = @ts[tn][1]
      
      # Are we at the end?
      return [alignment] if i == 0 || j == 0
      # If performing a local alignment, has the score dropped below 0?
      return [alignment] if !@align_globally && @ts[tn][0][i][j] <= 0
      
      # Insert as appropriate.
      if t[i][j][0][0] == i - 1
        alignment[0].insert(0, @a[i - 1])
      else
        alignment[0].insert(0, '_')
      end
      if t[i][j][0][1] == j - 1
        alignment[1].insert(0, @b[j - 1])
      else
        alignment[1].insert(0, '_')
      end
      
      # During local alignment, you must implement the following simplification. 
      # If you trace back to a cell that contains pointers to a zero in the M 
      # matrix and a pointer to a zero in the Ix or Iy matrix, you should only 
      # follow the pointer to the zero in the M matrix and terminate your 
      # traceback there only. This will prevent you from having alignments 
      # that are right-sided substrings.
      
      # If there are multiple possible traceback paths originating in this cell,
      # recurse and follow them individually.
      if t[i][j].size > 1
        # If we are tracing back to a cell with a 0 in the M matrix, we ignore
        # other possible tracebacks.
        if t[i][j].any? {|c| c[2] == :m && @m[c[0]][c[1]] == 0}
          tracebacks = t[i][j].select {|c| c[2] == :m}
        else
          tracebacks = t[i][j]
        end
        
        subalignments = []
        tracebacks.each do |cell|
          traceback(cell[0], cell[1], cell[2]).each do |subalignment|
            subalignments << subalignment
          end
        end
        return subalignments.map do |subalignment|
          [
            subalignment[0] + alignment[0],
            subalignment[1] + alignment[1]
          ]
        end
      end
      
      i, j, tn = t[i][j][0]
    end
  end
  
  ##
  # For the given set of choices for the score at i, j in the score matrix 
  # named by tn, pick all max-scores, set the score matrix to that value and 
  # update the traceback matrix with with all max-score choices.
  def choose_top(i, j, tn, choices)
    choices << [0, nil] if !@align_globally
    @ts[tn][0][i][j] =  choices.max {|a, b| a[0] <=> b[0]}[0]
    choices.each do |choice|
      if in_delta?(choice[0], @ts[tn][0][i][j])
        @ts[tn][1][i][j] << choice[1]
      end
    end
  end

  def matrix(&f)
    (0..@nx).map {|i| (0..@ny).map {|j| f.call}}
  end
  
  def in_delta?(a, b, delta = 0.00000001)
    return (a - b).abs < delta ? true : false
  end
  
  def self.align_file(filepath)
    lines = open(filepath).readlines
    alignment = Alignment.new(
      lines[0].strip,
      lines[1].strip,
      lines[2].strip == "0",
      lines[3].strip.split(" ").map {|v| v.to_f},
      lines[4].strip.to_i,
      Set.new(lines[5].strip.split),
      lines[6].strip.to_i,
      Set.new(lines[7].strip.split),
      Hash[
        lines[8..-1].reject {|line| line =~ /^$/}.map do |line|
          tokens = line.strip.split
          [tokens[2] + tokens[3], tokens[4].to_f]
        end
      ]
    )
    open(filepath[0...(filepath.rindex("."))] + ".output.mine", "w") do |f|
      f.puts("#{alignment.score}\n\n")
      alignment.alignments.uniq.each do |a|
        f.puts(a[0])
        f.puts("#{a[1]}\n\n")
      end
    end
    print "File: #{File.basename(filepath)}\tscore: #{alignment.score}\t" 
    puts "global: #{alignment.align_globally}"
    return alignment
  end

  def self.print_matrix(t, f = $stdout)
    t.each_with_index do |r, i|
      f.puts "#{i}: #{r.inspect}"
    end
  end
  
  def self.write_traceback(t, tn)
    open("Traceback#{tn.to_s.upcase}.tsv", "w") do |f|
      t.each do |r|
        r.each do |c|
          f.print(c.inspect)
        end
        f.puts
      end
    end
  end
end

if __FILE__ == $0
  Alignment.align_file(ARGV[0])
end