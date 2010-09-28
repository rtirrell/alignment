require "set"

class Alignment
  attr_accessor :alignments
  def initialize(a, b, align_globally, gap_penalties,
    nx, ax, ny, ay, s, debug = false)
    @a = a.split("")
    @nx = @a.size

    @b = b.split("")
    @ny = @b.size

    @align_globally = align_globally
    #@align_globally = true
    @dx, @ex, @dy, @ey = gap_penalties

    @ax = ax
    @ay = ay

    @s = s
    @alignments = []

    align
    output

    if @debug
      p @m [@nx][@ny]
      p @ix[@nx][@ny]
      p @iy[@nx][@ny]
      Alignment.print_matrix(@m)
      Alignment.print_matrix(@ix)
      Alignment.print_matrix(@iy)
      Alignment.print_matrix(@tm)
      Alignment.print_matrix(@tx)
      Alignment.print_matrix(@ty)
      p @alignments[0], @alignments[1]
    end
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
      
    #    if !@global
    #      (@nx + 1).times do |i|
    #        @f[i][0] = -@dx * [i, 1].min + -@ex * [i - 1, 0].max
    #      end
    #      (@ny + 1).times do |j|
    #        @matrix[0][j] = -@dy * [j, 1].min + -@ey * [j - 1, 0].max
    #      end
    #    end

    (1..@nx).each do |i|
      (1..@ny).each do |j|
        m_choices = [
          [@m [i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :m]],
          [@ix[i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :x]],
          [@iy[i - 1][j - 1] + @s[@a[i - 1] + @b[j - 1]], [i - 1, j - 1, :y]]
        ]
        m_choices << [0, nil] if !@align_globally
        choose_top(i, j, :m, m_choices)
       
        ix_choices = [
          [@m [i - 1][j] - @dx, [i - 1, j, :m]],
          [@ix[i - 1][j] - @ex, [i - 1, j, :x]]
        ]
        ix_choices << [0, nil] if !@align_globally
        choose_top(i, j, :x, ix_choices)

        iy_choices = [
          [@m [i][j - 1] - @dy, [i, j - 1, :m]],
          [@iy[i][j - 1] - @ey, [i, j - 1, :y]]
        ]
        iy_choices << [0, nil] if !@align_globally
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
        if @m[@nx][j] >= max_score
          if @m[@nx][j] > max_score
            @max_cells.clear
            @max_score = @m[@nx][j]
          end
          max_cells << [@nx, j]
        end
      end

      # Check last column.
      (0..@nx).each do |i|
        if @m[i][@ny] >= max_score
          if @m[i][@ny] > max_score
            @max_cells.clear
            @max_score = @m[i][@ny]
          end
          @max_cells << [i, @ny]
        end
      end
    else
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

    if @debug
      Alignment.print_matrix(@m)
      Alignment.print_matrix(@tm)
      Alignment.print_matrix(@tx)
      Alignment.print_matrix(@ty)
    end
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
      if @debug
        p "Current position: #{[i, j, tn].inspect}."
        p "Current alignment: #{alignment.inspect}."
        p "Considering: #{t[i][j].inspect}."
      end
      
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
        subalignments = []
        t[i][j].each do |cell|
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
  
  def choose_top(i, j, tn, choices)
    @ts[tn][0][i][j] =  choices.max {|a, b| a[0] <=> b[0]}[0]
    choices.each do |choice|
      if choice[0] == @ts[tn][0][i][j]
        @ts[tn][1][i][j] << choice[1]
      end
    end
  end

  def matrix(&f)
    (0..@nx).map {|i| (0..@ny).map {|j| f.call}}
  end

  def self.align_file(filepath)
    lines = open(filepath).readlines
    Alignment.new(
      lines[0].strip,
      lines[1].strip,
      lines[2].strip == "1",
      lines[3].strip.split(" ").map {|v| v.to_i},
      lines[4].strip.to_i,
      Set.new(lines[5].strip.split),
      lines[6].strip.to_i,
      Set.new(lines[7].strip.split),
      Hash[
        lines[8..-1].map do |line|
          tokens = line.strip.split
          [tokens[2] + tokens[3], tokens[4].to_i]
        end
      ]
    )
  end

  def self.print_matrix(t)
    t.each_with_index do |r, i|
      puts "#{i}: #{r.inspect}"
    end
  end

end