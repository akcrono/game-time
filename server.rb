require 'sinatra'
require 'csv'
require 'pry'
require 'sinatra/reloader'

def find_or_build_team(teams, name)
  if teams[name].nil?
    teams[name] = { wins: 0, losses: 0 }
  end

  teams[name]
end

def game_results
  game_results = []

  CSV.foreach('game_results.csv', headers: true, header_converters: :symbol, converters: :all) do |game|
    game_results << game.to_hash
  end

  game_results
end

def build_standings
  teams = Hash.new

  game_results.each do |game|
    home_team = find_or_build_team(teams, game[:home_team])
    away_team = find_or_build_team(teams, game[:away_team])

    if game[:home_score] > game[:away_score]
      home_team[:wins] += 1
      away_team[:losses] += 1
    else
      away_team[:wins] += 1
      home_team[:losses] += 1
    end
  end

  teams
end

def get_history team
  team_history = []
  CSV.foreach('game_results.csv', headers: true, header_converters: :symbol, converters: :all) do |row|
    if row[:home_team] == team
      if row[:home_score] > row[:away_score]
        team_history << {location: "vs.", opponent: row[:away_team], result: 'win', score1: row[:home_score], score2: row[:away_score]}
      else
        team_history << {location: "vs.", opponent: row[:away_team], result: 'loss', score1: row[:home_score], score2: row[:away_score]}
      end
    elsif row[:away_team] == team
      if row[:home_score] > row[:away_score]
        team_history << {location: "at", opponent: row[:home_team], result: 'loss', score1: row[:away_score], score2: row[:home_score]}
      else
        team_history << {location: "at.", opponent: row[:home_team], result: 'win', score1: row[:away_score], score2: row[:home_score]}
      end
    end
  end
  team_history
end

def get_record(team)
  build_standings[team]
end

get '/' do
  @standings = build_standings
  @standings = @standings.sort_by do |name, record|
    [-record[:wins], record[:losses]]
  end

  erb :index
end

get '/teams/:team' do
  @this_team = params[:team]
  @team_history = get_history(@this_team)
  @team_record = get_record(@this_team)

  erb :teams
end
