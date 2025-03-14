CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    rfid_uid VARCHAR(50) UNIQUE NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255)
);

CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    game_type VARCHAR(20) NOT NULL,
    player1_id INT REFERENCES users(id),
    player2_id INT REFERENCES users(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    winner_id INT REFERENCES users(id),
    board_id VARCHAR(50),
    metadata JSONB,
    elo_change JSONB,
    deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE elo_ratings (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    game_type VARCHAR(20) NOT NULL,
    rating INT NOT NULL DEFAULT 1500,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);