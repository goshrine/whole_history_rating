require 'test/unit'
require 'whole_history_rating'

class WholeHistoryRatingTest < Test::Unit::TestCase
  
  def build_test_game(white_elo, black_elo, komi, handicap)
    @whr = WholeHistoryRating::Base.new
    game = @whr.create_game({
      'white'    => "white",
      'black'    => "black",
      'winner'   => "W",
      'komi'     => komi,
      'handicap' => handicap,
      'date'     => Date.parse('2010-11-07')
    })
    @whr.add_game(game)
    game.black_player.days[0].elo = black_elo
    game.white_player.days[0].elo = white_elo
    game
  end
  
  def test_even_game_between_equal_strength_players_should_have_white_winrate_of_50_percent
    game = build_test_game(500, 500, 6.5, 0)
    assert_in_delta 0.0001, 0.5, game.white_win_probability
  end

  def test_handicap_should_confer_advantage
    game = build_test_game(500, 500, 0, 1)
    assert game.black_win_probability > 0.5
  end

  def test_higher_rank_should_confer_advantage
    game = build_test_game(600, 500, 6.5, 0)
    assert game.white_win_probability > 0.5
  end
  
  def test_winrates_are_equal_for_same_elo_delta
    game = build_test_game(100, 200, 0, 0)
    game2 = build_test_game(200, 300, 0, 0)
    assert_in_delta 0.0001, game.white_win_probability, game2.white_win_probability
  end

  def test_winrates_for_twice_as_strong_player
    game = build_test_game(100, 200, 0, 0)
    assert_in_delta 0.0001, 0.359935, game.white_win_probability
  end

  def test_winrates_should_be_inversely_proportional_with_unequal_ranks
    game = build_test_game(600, 500, 6.5, 0)
    assert_in_delta 0.0001, game.white_win_probability, 1-game.black_win_probability
  end
  
  def test_winrates_should_be_inversely_proportional_with_handicap
    game = build_test_game(500, 500, 6.5, 4)
    assert_in_delta 0.0001, game.white_win_probability, 1-game.black_win_probability
  end
    
end

