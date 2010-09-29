###
# TODO: initialization.
###
require "set"

class Alignment
  attr_reader :alignments
  attr_reader :max_score
  alias :score :max_score
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
      
    align
#    output
    
#    p @max_score
#    p @max_cells
    p @s
    write_traceback(@tm, :m)
    write_traceback(@tx, :x)
    write_traceback(@ty, :y)

  end

  def align
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
    
#    if @align_globally
#      (1..@nx).each do |i|
#        @ix[i][0] = -@dx * [i, 1].min - @ex * [i - 1, 0].max
#      end
#      (1..@ny).each do |j|
#        @iy[0][j] = -@dy * [j, 1].min - @ey * [j - 1, 0].max
#      end
#    end
      
    (1..@nx).each do |i|
      (1..@ny).each do |j|
        m_choices = [
          [@m [i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :m]],
          [@ix[i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :x]],
          [@iy[i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :y]]
        ]
        choose_top(i, j, :m, m_choices)
       
        ix_choices = [
          [@m [i - 1][j] - @dx, [i - 1, j, :m]],
          [@ix[i - 1][j] - @ex, [i - 1, j, :x]]
        ]
        choose_top(i, j, :x, ix_choices)

        iy_choices = [
          [@m [i][j - 1] - @dy, [i, j - 1, :m]],
          [@iy[i][j - 1] - @ey, [i, j - 1, :y]]
        ]
        choose_top(i, j, :y, iy_choices)
      end
    end

    # Since we don't allow endgaps, we find the highest-scoring alignment in
    # the last row or column of M. 
    @max_score = @m[@nx][@ny]
    @max_cells = Set.new

    if @align_globally
      # Check last row.
      (0..@ny).each do |j|
        if @m[@nx][j] >= @max_score
          if @m[@nx][j] > @max_score
            @max_cells.clear
            @max_score = @m[@nx][j]
          end
          @max_cells << [@nx, j]
        end
      end

      # Check last column.
      (0..@nx).each do |i|
        if @m[i][@ny] >= @max_score
          if @m[i][@ny] > @max_score
            @max_cells.clear
            @max_score = @m[i][@ny]
          end
          @max_cells << [i, @ny]
        end
      end
      
    else
      # Check everything.
      (0..@nx).each do |i|
        (0..@ny).each do |j|
          if @m[i][j] >= @max_score
            if @m[i][j] > @max_score
              @max_cells.clear
              @max_score = @m[i][j]
            end
            @max_cells << [i, j]
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
  # Starting from each max cell, traceback returns a list of alignments
  # beginning from that cell. Whenever a branching cell is encountered, call
  # recursively to get a list of alignments from each branch separately.
  def traceback(i, j, tn) 
    alignment = ["", ""]
      
    loop do
      t = @ts[tn][1]
      puts [[i, j, tn], t[i][j]].inspect
      puts alignment.inspect
      
      return [alignment] if i == 0 || j == 0
      return [alignment] if !@align_globally && @ts[tn][0][i][j] <= 0
      
      if t[i][j][0][0] == i - 1
        alignment[0].insert(0, @a[i - 1])
      else
        alignment[0].insert(0, "_")
      end
      if t[i][j][0][1] == j - 1
        alignment[1].insert(0, @b[j - 1])
      else
        alignment[1].insert(0, "_")
      end
      
      if t[i][j].size > 1
        c = 0
        puts "BRANCHING"
        subalignments = []
        t[i][j].each do |cell|
          puts "BRANCHING #{c += 1}."
          traceback(cell[0], cell[1], cell[2]).each do |subalignment|
            subalignments << subalignment
          end
        end
        p subalignments.inspect
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
  
  def output
    open("1.output", "w") do |f|
      f.puts(@max_score)
      f.puts
      @alignments.uniq.each do |alignment|
        f.puts(alignment[0])
        f.puts(alignment[1])
        f.puts
      end
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
      if in_delta(choice[0], @ts[tn][0][i][j])
        @ts[tn][1][i][j] << choice[1]
      end
    end
  end

  def matrix(&f)
    (0..@nx).map {|i| (0..@ny).map {|j| f.call}}
  end
  
  def in_delta(a, b, delta = 0.001)
    return (a - b).abs < delta ? true : false
  end

  def self.align_file(filepath)
    lines = open(filepath).readlines
    Alignment.new(
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
  end

  def self.print_matrix(t)
    t.each_with_index do |r, i|
      puts "#{i}: #{r.inspect}"
    end
  end
  
  def write_traceback(t, tn)
    open("Traceback#{tn.to_s.upcase}.tsv", "w") do |f|
      max_length = t.flatten.max {|a, b| a.inspect.size <=> b.inspect.size}.inspect.size
      t.each do |r|
        r.each do |c|
          f.print("%#{max_length}s\t" % [c.inspect])
        end
        f.puts
      end
    end
  end
end