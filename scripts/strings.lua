local MULTI_MOD = {
	NAME = "ONLINE MULTIPLAYER",
	TIP = "<c:FF8411>ONLINE MULTIPLAYER</c>\nEnables multiplayer over a TCP connection.\nAdvanced options become available when you launch the game.",
	
	GAME_MODES = {
		NAME = "GAME MODE",
		TIP = "<c:FF8411>GAME MODE</c>Determines the rules for players controlling agents.\n<c:FF8411>FREE FOR ALL</c>\nAny player can control any agent at any time.\n<c:FF8411>BACKSTAB PROTOCOLS</c>\nPlayers control one agent each and take alternating moves. End Turn is replaced with Yield Turn, which hands control to the other player.",
		OPTS = {
			"FREE FOR ALL",
			"BACKSTAB PROTOCOLS"
		}
	},
	
	MISSION_VOTING = {
		NAME = "MISSION VOTING",
		TIP = "<c:FF8411>MISSION VOTING</c>Determines the rules for selecting missions.\n<c:FF8411>FIRST COME FIRST SERVED</c>\nAny player can start a mission.\n<c:FF8411>MAJORITY VOTE</c>\nAll players must select a mission and the mission with the most votes is chosen (random in case of a tie).\n<c:FF8411>WEIGHTED RANDOM</c>\nMissions are chosen at random depending on the number of players that vote on them.\n<c:FF8411>HOST DECIDES</c>\nOnly the host can start a mission.",
		OPTS = {
			"FIRST COME FIRST SERVED",
			"MAJORITY VOTE",
			"WEIGHTED RANDOM",
			"HOST DECIDES",
		}
	},
	
	BUTTON_HOST = "HOST",
	BUTTON_JOIN = "JOIN",
	BUTTON_LOCAL = "OFFLINE PLAY",
	BUTTON_REFRESH = "REFRESH",
	
	TITLE_SETUP = "SETUP ONLINE MULTIPLAYER",
	TITLE_HOST = "HOST GAME",
	TITLE_JOIN = "JOIN GAME",
	
	BODY_SETUP = "Click Host to setup a game for others to join.",
	BODY_HOST = "Send the ip, port, and optional password to those you wish to join the game.",
	BODY_JOIN = "Enter the ip, port, and password the host sent to you.",
	
	CONNECTION_FAILED = "CONNECTION FAILED",
	CONNECTION_ERROR = "CONNECTION ERROR",
	JOIN_FAILED = "Game already closed.",
	RETRY = "RETRY",
	PASSWORD_REJECTED = "Password Incorrect.",
	WAITING_JOINING = "Waiting to join game...",
	WAITING_PASSWORD = "Waiting for password verification...",
	WAITING_CREATE = "Waiting for game listing to be created...",
	WAIT_GAMES_LIST = "Waiting for response...",
	CONNECTING = "CONNECTING",
	CONNECTING_BODY = "Connecting...",
	CONNECTION_TIMING_OUT = "Waiting for response...",
	CONTINUE_HOST = "HOST GAME",
	JOIN_FAILED_CLOSED = "Failed to join, game is already closed.",
	GAME_OVER = "Game ended by host.",
	
	SOCKET_VERSION_REQUIRED = "Socket version required:",
	CURRENT_SOCKET_VERSION = "Current socket version:",
	
	BACKSTAB_YIELD_SWIPE = "%s ACTIVITY",
	YIELD = "YIELD TURN",
	YIELDED_TO = "%s TURN",

	NOT_YOUR_TURN_TITLE = "Not your turn",
	NOT_YOUR_TURN_SUBTEXT = "%s is currently taking actions.",
	
	PANEL = {
		TITLE = "Game Title",
		PASSWORD = "Password",
		USERNAME = "Your Name",
		TOGGLE_PASSWORD = "Toggle password visibility",
	}
}

return MULTI_MOD
