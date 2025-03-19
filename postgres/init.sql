-- Users table - simplified for core functionality
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    rfid_uid VARCHAR(50) UNIQUE NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL
);

-- Games table - enhanced with game-specific fields
CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    game_type VARCHAR(20) NOT NULL CHECK (game_type IN ('chess', 'foosball')),
    player1_id INT REFERENCES users(id),
    player2_id INT REFERENCES users(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'active' 
        CHECK (status IN ('active', 'completed', 'cancelled', 'timeout', 'forfeit', 'draw')),
    winner_id INT REFERENCES users(id),
    board_id VARCHAR(50) NOT NULL,
    game_mode VARCHAR(20) CHECK (game_mode IN ('casual', 'blitz', 'classical')),
    time_limit INT,  -- in seconds
    metadata JSONB,  -- for game-specific data like chess moves
    elo_change JSONB NOT NULL DEFAULT '{}'::jsonb,
    deleted BOOLEAN DEFAULT FALSE,
    game_source VARCHAR(20) 
        CHECK (game_source IN ('physical', 'online')) 
        DEFAULT 'physical'
);

-- ELO ratings table - with constraints and index
CREATE TABLE elo_ratings (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    game_type VARCHAR(20) NOT NULL CHECK (game_type IN ('chess', 'foosball')),
    rating INT NOT NULL DEFAULT 1500 CHECK (rating >= 0),
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, game_type)
);

-- Indexes for common queries
CREATE INDEX idx_games_board_id ON games(board_id);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_games_players ON games(player1_id, player2_id);
CREATE INDEX idx_elo_ratings_user_game ON elo_ratings(user_id, game_type);

-- Trigger to update last_updated in elo_ratings
CREATE OR REPLACE FUNCTION update_elo_last_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_elo_timestamp
    BEFORE UPDATE ON elo_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_elo_last_updated();

-- Optional: Add table for challenges
CREATE TABLE game_challenges (
    id SERIAL PRIMARY KEY,
    challenger_id INT REFERENCES users(id),
    challenged_id INT REFERENCES users(id),
    game_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
