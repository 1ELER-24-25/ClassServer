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

-- ============================================
-- Programming Course Feature Tables
-- ============================================

-- Courses Table
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    language VARCHAR(50), -- e.g., 'python', 'javascript'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Modules Table
CREATE TABLE modules (
    id SERIAL PRIMARY KEY,
    course_id INT REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL, -- Instructions for the module
    content TEXT, -- Starter code, expected output, etc.
    documentation_links JSONB, -- [{"title": "Link Title", "url": "..."}]
    order_num INT NOT NULL, -- Sequence within the course
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (course_id, order_num)
);

-- Hints Table
CREATE TABLE hints (
    id SERIAL PRIMARY KEY,
    module_id INT REFERENCES modules(id) ON DELETE CASCADE,
    hint_text TEXT NOT NULL,
    hint_number INT NOT NULL CHECK (hint_number IN (1, 2, 3, 4)), -- Allow hint 4, removed duplicate column defs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (module_id, hint_number)
);

-- User Course Progress Table
CREATE TABLE user_course_progress (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    course_id INT REFERENCES courses(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    score INT, -- Calculated at the end
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    UNIQUE (user_id, course_id)
);

-- User Module Progress Table
CREATE TABLE user_module_progress (
    id SERIAL PRIMARY KEY,
    user_course_progress_id INT REFERENCES user_course_progress(id) ON DELETE CASCADE,
    module_id INT REFERENCES modules(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    hints_used_mask INT DEFAULT 0, -- Bitmask: 1=hint1, 2=hint2, 4=hint3
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    UNIQUE (user_course_progress_id, module_id)
);

-- Indexes for course tables
CREATE INDEX idx_modules_course_id ON modules(course_id);
CREATE INDEX idx_hints_module_id ON hints(module_id);
CREATE INDEX idx_user_course_progress_user_course ON user_course_progress(user_id, course_id);
CREATE INDEX idx_user_module_progress_ucp_module ON user_module_progress(user_course_progress_id, module_id);

-- Seed data is now moved to separate files in postgres/seed_data/
-- The Docker entrypoint script will execute *.sql files from /docker-entrypoint-initdb.d/
