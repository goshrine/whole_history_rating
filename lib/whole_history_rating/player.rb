require 'matrix'

module WholeHistoryRating
  class Player
    attr_accessor :name, :anchor_gamma, :days, :w2, :debug, :id
  
    def initialize(name, config)
      @name = name
      @debug = config[:debug]
      @w2 = (Math.sqrt(config[:w2])*Math.log(10)/400)**2  # Convert from elo^2 to r^2
      @days = []
    end
  
    def inspect
      "#{self}:(#{name})"
    end
  
    def log_likelihood
      sum = 0.0
      sigma2 = compute_sigma2
      n = days.count
      0.upto(n-1) do |i|
        prior = 0
        if i < (n-1)
          rd = days[i].r - days[i+1].r
          prior += (1/(Math.sqrt(2*Math::PI*sigma2[i]))) * Math.exp(-(rd**2)/2*sigma2[i]) 
        end
        if i > 0
          rd = days[i].r - days[i-1].r
          prior += (1/(Math.sqrt(2*Math::PI*sigma2[i-1]))) * Math.exp(-(rd**2)/2*sigma2[i-1]) 
        end
        if prior == 0
          sum += days[i].log_likelihood
        else
          if (days[i].log_likelihood.infinite? || Math.log(prior).infinite?) 
            puts "Infinity at #{inspect}: #{days[i].log_likelihood} + #{Math.log(prior)}: prior = #{prior}, days = #{days.inspect}"
            exit
          end
          sum += days[i].log_likelihood + Math.log(prior)
        end
      end
      sum
    end
  
    def hessian(days, sigma2)
      n = days.count
      Matrix.build(n) do |row,col|
        if row == col
          prior = 0
          prior += -1.0/sigma2[row] if row < (n-1)
          prior += -1.0/sigma2[row-1] if row > 0
          days[row].log_likelihood_second_derivative + prior - 0.001
        elsif row == col-1
          1.0/sigma2[row]
        elsif row == col+1
          1.0/sigma2[col]
        else
          0
        end
      end
    end
  
    def gradient(r, days, sigma2)
      g = []
      n = days.count
      days.each_with_index do |day,idx|
        prior = 0
        prior += -(r[idx]-r[idx+1])/sigma2[idx] if idx < (n-1)
        prior += -(r[idx]-r[idx-1])/sigma2[idx-1] if idx > 0
        if @debug
          puts "g[#{idx}] = #{day.log_likelihood_derivative} + #{prior}"
        end
        g << day.log_likelihood_derivative + prior
      end
      g
    end
  
    def run_one_newton_iteration
      days.each do |day|
        day.clear_game_terms_cache
      end
    
      if days.count == 1
        days[0].update_by_1d_newtons_method
      elsif days.count > 1
        update_by_ndim_newton
      end
    end
  
    def compute_sigma2
      sigma2 = []
      days.each_cons(2) do |d1,d2|
        sigma2 << (d2.day - d1.day).abs * @w2
      end
      sigma2
    end
  
    def update_by_ndim_newton
      # r
      r = days.map(&:r)
    
      if @debug
        puts "Updating #{inspect}"
        days.each do |day|
          puts "day[#{day.day}] r = #{day.r}"
          puts "day[#{day.day}] win terms = #{day.won_game_terms}"
          puts "day[#{day.day}] win games = #{day.won_games}"
          puts "day[#{day.day}] lose terms = #{day.lost_game_terms}"
          puts "day[#{day.day}] lost games = #{day.lost_games}"
          puts "day[#{day.day}] log(p) = #{day.log_likelihood}"
          puts "day[#{day.day}] dlp = #{day.log_likelihood_derivative}"
          puts "day[#{day.day}] dlp2 = #{day.log_likelihood_second_derivative}"
        end
      end
    
      # sigma squared (used in the prior)
      sigma2 = compute_sigma2
    
      h = hessian(days, sigma2)
      g = gradient(r, days, sigma2)
    
      a = []
      d = [h[0,0]]
      b = [h[0,1]]
    
      n = r.size    
      (1..(n-1)).each do |i|
        a[i] = h[i,i-1] / d[i-1]
        d[i] = h[i,i] - a[i] * b[i-1]
        b[i] = h[i,i+1]
      end
    
    
      y = [g[0]]
      (1..(n-1)).each do |i|
        y[i] = g[i] - a[i] * y[i-1]
      end
    
      x = []
      x[n-1] = y[n-1] / d[n-1]
      (n-2).downto(0) do |i|
        x[i] = (y[i] - b[i] * x[i+1]) / d[i]
      end    
    
      new_r = r.zip(x).map {|ri,xi| ri-xi}
    
      new_r.each do |r|
        if r > 650
          raise UnstableRatingException, "Unstable r (#{new_r}) on player #{inspect}"
        end
      end
    
      if @debug
        puts "Hessian = #{h}"
        puts "gradient = #{g}"
        puts "a = #{a}"
        puts "d = #{d}"
        puts "b = #{b}"
        puts "y = #{y}"
        puts "x = #{x}"
        puts "#{inspect} (#{r}) => (#{new_r})"
      end
    
      days.each_with_index do |day,idx|
        day.r = day.r - x[idx]
      end
    end
  
    def covariance
      r = days.map(&:r)
    
      sigma2 = compute_sigma2
      h = hessian(days, sigma2)
      g = gradient(r, days, sigma2)
    
      n = days.count
    
      a = []
      d = [h[0,0]]
      b = [h[0,1]]
    
      n = r.size    
      (1..(n-1)).each do |i|
        a[i] = h[i,i-1] / d[i-1]
        d[i] = h[i,i] - a[i] * b[i-1]
        b[i] = h[i,i+1]
      end
    
      dp = []
      dp[n-1] = h[n-1,n-1]    
      bp = []
      bp[n-1] = h[n-1,n-2]
      ap = []
      (n-2).downto(0) do |i|
        ap[i] = h[i,i+1] / dp[i+1]
        dp[i] = h[i,i] - ap[i]*bp[i+1]
        bp[i] = h[i,i-1]
      end
    
      v = []
      0.upto(n-2) do |i|
        v[i] = dp[i+1]/(b[i]*bp[i+1] - d[i]*dp[i+1])
      end
      v[n-1] = -1/d[n-1]
    
      #puts "a = #{a}"
      #puts "b = #{b}"
      #puts "bp = #{bp}"
      #puts "d = #{d}"
      #puts "dp = #{dp}"
      #puts "v = #{v}" 
    
      Matrix.build(n) do |row,col|
        if row == col
          v[row]
        elsif row == col-1
          -1*a[col]*v[col]
        else
          0
        end
      end
    end
    
    def update_uncertainty
      if days.count > 0
        c = covariance
        u = (0..(days.count-1)).collect{|i| c[i,i]} # u = variance
        days.zip(u) {|d,u| d.uncertainty = u}
      else
        5
      end
    end
  
    def add_game(game)
      if days.last.nil? || days.last.day != game.day
        new_pday = PlayerDay.new(self, game.day)
        if days.empty?
          new_pday.is_first_day = true
          new_pday.gamma = 1
        else
          new_pday.gamma = days.last.gamma
        end
        days << new_pday
      end
      if (game.white_player == self)
        game.wpd = days.last
      else 
        game.bpd = days.last
      end
      days.last.add_game(game)
    end
  end
end