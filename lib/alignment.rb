require "set"

class Alignment
  def self.parse(filepath)
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
  
  def matrix(v)
    (0..@nx).map {|i| Array.new(@ny + 1, v)}
  end
  
  def print_matrix(t)
    t.each_with_index do |r, i|
      puts "#{i}: #{r.inspect}"
    end
  end
  
  def initialize(a, b, align_globally, gap_penalties, nx, ax, ny, ay, s)
    @a = a.split("")
    @nx = @a.size
    
    @b = b.split("")
    @ny = @b.size
    
    @align_globally = align_globally
    @dx, @ex, @dy, @ey = gap_penalties
    
    @ax = ax
    @ay = ay
    
    @s = s
    @alignment = [[], []]
    
    align
    p @m [@nx][@ny]
    p @ix[@nx][@ny]
    p @iy[@nx][@ny]
    print_matrix(@m)
    print_matrix(@ix)
    print_matrix(@iy)
    print_matrix(@tm)
    print_matrix(@tx)
    print_matrix(@ty)
    p @alignment[0], @alignment[1]
  end
  
  def align
    # M tracks the best score of an alignment ending in A[i], B[j]
    # Then M[i, j] = max(
    #                      M(i - 1, j - 1) + s(A[i], B[j])
    #                      Ix[i - 1, j - 1] + s(A[i], B[i])
    #                      Iy[i - 1, j - 1] + s(A[i], B[i])
    #                   )
    @m  = matrix(0)
    @tm = matrix(nil)
      
    # Ix tracks the best score when A[< i] aligns to B[j]
    # Then Ix[i, j] = max(
    #                       M[i - 1, j] - d
    #                       Ix[i - 1, j] - e
    #                    )
    @ix = matrix(0)
    @tx = matrix(nil)
    
    # Ix tracks the best score when A[i] aligns to B[< j]
    # Then Iy[i, j] = max(
    #                       M[i, j - 1] - d
    #                       Iy[i, j - 1] - e
    #                    )
    @iy = matrix(0)
    @ty = matrix(nil)
     
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
        m_choice = m_choices.max {|a, b| a[0] <=> b[0]}
        @m [i][j] = m_choice[0]
        @tm[i][j] = m_choice[1]
        
        ix_choices = [
          [@m [i - 1][j] - @dx, [i - 1, j, :m]],
          [@ix[i - 1][j] - @ex, [i - 1, j, :x]]
        ]
        ix_choice = ix_choices.max {|a, b| a[0] <=> b[0]}
        @ix[i][j] = ix_choice[0]
        @tx[i][j] = ix_choice[1]
          
        iy_choices = [
          [@m [i][j - 1] - @dy, [i, j - 1, :m]],
          [@iy[i][j - 1] - @ey, [i, j - 1, :y]]
        ]
        iy_choice = iy_choices.max {|a, b| a[0] <=> b[0]}
        @iy[i][j] = iy_choice[0]
        @ty[i][j] = iy_choice[1]
      end
    end
    
    i, j = @nx, @ny
    _, t = [[@m, @tm], [@ix, @tx], [@iy, @ty]].max do 
      |a, b| a[0][@nx][@ny] <=> b[0][@nx][@ny]
    end
      
    loop do
      if t[i][j][0] == i - 1
        @alignment[0].insert(0, @a[i - 1])
      else
        @alignment[0].insert(0, "-")
      end
      if t[i][j][1] == j - 1
        @alignment[1].insert(0, @b[j - 1])
      else
        @alignment[1].insert(0, "-")
      end
      
      i, j = t[i][j][0], t[i][j][1]
      
      if t[i][j].nil?
        while i > 0
          @alignment[0].insert(0, @a[i - 1])
          @alignment[1].insert(0, "-")
          i -= 1
        end
        while j > 0
          @alignment[0].insert(0, "-")
          @alignment[1].insert(0, @b[j - 1])
          j -= 1
        end
        break
      end
      
      if    t[i][j][2] == :m
        t = @tm
      elsif t[i][j][2] == :x
        t = @tx
      elsif t[i][j][2] == :y
        t = @ty
      end
    end
  end
end