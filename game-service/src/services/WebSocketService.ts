class WebSocketService {
    private connections: Map<string, WebSocket>;
    
    handleConnection(userId: string, ws: WebSocket) {
        this.connections.set(userId, ws);
        
        ws.on('message', (data) => {
            const message = JSON.parse(data);
            switch(message.type) {
                case 'move':
                    this.handleMove(userId, message.gameId, message.move);
                    break;
                case 'challenge':
                    this.handleChallenge(userId, message.targetId);
                    break;
                // ... other handlers
            }
        });
    }
    
    broadcastGameState(gameId: string, state: GameState) {
        const players = [state.players.white, state.players.black];
        players.forEach(playerId => {
            const ws = this.connections.get(playerId);
            if (ws) {
                ws.send(JSON.stringify({
                    type: 'gameState',
                    state: state
                }));
            }
        });
    }
}