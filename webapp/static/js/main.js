// Update active games
function updateActiveGames() {
    fetch('/api/active-games')
        .then(response => response.json())
        .then(games => {
            const gamesDiv = document.getElementById('activeGames');
            if (games.length === 0) {
                gamesDiv.innerHTML = '<p>No active games</p>';
                return;
            }
            // Render games
            gamesDiv.innerHTML = games.map(game => `
                <div class="game-card">
                    <h3>${game.game_type}</h3>
                    <p>Board: ${game.board_id}</p>
                    <p>Status: ${game.status}</p>
                </div>
            `).join('');
        });
}

// Update leaderboard
function updateLeaderboard() {
    fetch('/api/leaderboard')
        .then(response => response.json())
        .then(rankings => {
            const leaderboardDiv = document.getElementById('leaderboard');
            leaderboardDiv.innerHTML = rankings.map(rank => `
                <div class="rank-card">
                    <span>${rank.username}</span>
                    <span>${rank.game_type}</span>
                    <span>${rank.rating}</span>
                </div>
            `).join('');
        });
}

// Update every 5 seconds
setInterval(() => {
    updateActiveGames();
    updateLeaderboard();
}, 5000);

// Initial load
document.addEventListener('DOMContentLoaded', () => {
    updateActiveGames();
    updateLeaderboard();
});