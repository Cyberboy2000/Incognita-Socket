local function initStrings( modApi )
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()
	
    local MULTI_MOD = include( scriptPath .. "/strings" )
    modApi:addStrings( dataPath, "MULTI_MOD", MULTI_MOD )  
end

local function init( modApi )
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()
	
	log:write("MULTIMOD INIT")
	MOAIFileSystem.copy( dataPath.."/lua5.1.dll", "lua5.1.dll" )
	package.cpath = package.cpath..";"..dataPath.."/?.dll;"
	
	rawset(_G,"multiMod",include( scriptPath.."/state-multiplayer" ))
	
	modApi:addGenerationOption("multiMod",STRINGS.MULTI_MOD.NAME,STRINGS.MULTI_MOD.TIP,{noUpdate=true})
	modApi:addGenerationOption("gameMode",STRINGS.MULTI_MOD.GAME_MODES.NAME,STRINGS.MULTI_MOD.GAME_MODES.TIP,
	{
		noUpdate=true,
		strings = STRINGS.MULTI_MOD.GAME_MODES.OPTS,
		values = {
			multiMod.GAME_MODES.FREEFORALL,
			multiMod.GAME_MODES.BACKSTAB,
		}
	})
	modApi:addGenerationOption("votingMode",STRINGS.MULTI_MOD.MISSION_VOTING.NAME,STRINGS.MULTI_MOD.MISSION_VOTING.TIP,
	{
		noUpdate=true,
		strings = STRINGS.MULTI_MOD.MISSION_VOTING.OPTS,
		values = {
			multiMod.MISSION_VOTING.FREEFORALL,
			multiMod.MISSION_VOTING.MAJORITY,
			multiMod.MISSION_VOTING.WEIGHTEDRAND,
			multiMod.MISSION_VOTING.HOSTDECIDES,
		}
	})
	
	multiMod.DEFAULT_PORT = 27017
	multiMod.MULTI_MOD_VERSION = 2.1
	--multiMod.COMPABILITY_VERSION = 2 -- Moved to load!!!
	multiMod.WERP_ADRESS = "werp.site"
	multiMod.WERP_PORT = 31337
	multiMod.VERBOSE = true
	log:write("MULTIMOD VERSION "..tostring(multiMod.MULTI_MOD_VERSION))
	multiMod.socketCore = include( "socket.core" )
	multiMod.serializer = include(scriptPath.."/serializer")
	multiMod.host = include(scriptPath.."/tcp-host")
	multiMod.client = include(scriptPath.."/tcp-client")
	--multiMod.werpHost = include(scriptPath.."/tcp-werp-host")
	multiMod.werpClient = include(scriptPath.."/tcp-werp-client")
	multiMod.stateSetup = include(scriptPath.."/state-setup-multiplayer")
	multiMod.stateSetupWerp = include(scriptPath.."/state-setup-werp")
	include(scriptPath.."/mui_text")
	include(scriptPath.."/state-game")
	include(scriptPath.."/state-loading")
	include(scriptPath.."/state-team-preview")
	include(scriptPath.."/engine")
	include(scriptPath.."/saveslots-dialog")
	include( scriptPath.."/state-map-screen" )
	include( scriptPath.."/state-upgrade-screen" )
	include( scriptPath.."/modal_thread" )
	include( scriptPath.."/simactions2" )
	include( scriptPath.."/hud" )
end

local function showSetup( stateGenerationOptions, difficulty, options )
	statemgr.activate( multiMod.stateSetupWerp, nil, difficulty, options )
end

local function load( modApi, options, params )
	multiMod.params = nil
	
	local scriptPath = modApi:getScriptPath()
	modApi:addNewUIScreen( "modal-setup-multiplayer", scriptPath.."/modal-setup-multiplayer" )
	modApi:addNewUIScreen( "hud-multiplayer", scriptPath.."/hud-multiplayer" )
	modApi:insertUIElements( include( scriptPath.."/screen_inserts" ) )
	modApi:modifyUIElements( include( scriptPath.."/screen_modifications" ) )
	
	if options["multiMod"] and options["multiMod"].enabled and params then
		multiMod.params = params
		
		modApi:addPostGenerationOptionsFunction( showSetup )
	end
	if options["gameMode"] then
		multiMod.gameMode = options["gameMode"].value
	end
	if options["votingMode"] then
		multiMod.votingMode = options["votingMode"].value
	end
	
	if multiMod.gameMode ~= multiMod.GAME_MODES.FREEFORALL or (params and params.timeAttack and params.timeAttack > 0) then
		multiMod.COMPABILITY_VERSION = 2.1
	else
		multiMod.COMPABILITY_VERSION = 2
	end
	
	for eventType, handlerFile in pairs( include( scriptPath.."/viz/viz" ) ) do
		modApi:addVizEvHandler( eventType, include( scriptPath.."/viz/"..handlerFile ))
	end
end

local function unload( modApi, params )
	multiMod.params = nil
end

local function earlyInit( modApi )
	modApi.requirements = {"Quick Loader","Agent Reserve"}
end

return {
	initStrings = initStrings,
	init = init,
	earlyInit = earlyInit,
	load = load,
	unload = unload,
}