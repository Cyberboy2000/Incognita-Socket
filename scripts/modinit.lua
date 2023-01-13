local function initStrings( modApi )
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()
	
    local MULTI_MOD = include( scriptPath .. "/strings" )
    modApi:addStrings( dataPath, "MULTI_MOD", MULTI_MOD )  
end

local function init( modApi )
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()
	
	modApi:addGenerationOption("multiMod",STRINGS.MULTI_MOD.NAME,STRINGS.MULTI_MOD.TIP,{noUpdate=true})
	
	log:write("MULTIMOD INIT")
	MOAIFileSystem.copy( dataPath.."/lua5.1.dll", "lua5.1.dll" )
	package.cpath = package.cpath..";"..dataPath.."/?.dll;"
	
	rawset(_G,"multiMod",include( scriptPath.."/state-multiplayer" ))
	
	multiMod.DEFAULT_PORT = 27017
	multiMod.MULTI_MOD_VERSION = 1
	multiMod.COMPABILITY_VERSION = 1
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
end

local function load( modApi, options, params )
	multiMod.params = nil
	
	local scriptPath = modApi:getScriptPath()
	modApi:addNewUIScreen( "modal-setup-multiplayer", scriptPath.."/modal-setup-multiplayer" )
	modApi:insertUIElements( include( scriptPath.."/screen_inserts" ) )
	modApi:modifyUIElements( include( scriptPath.."/screen_modifications" ) )
	
	if options["multiMod"] and options["multiMod"].enabled and params then
		multiMod.params = params
		params.exitfunction = function(stateGenerationOptions)
			statemgr.activate( multiMod.stateSetupWerp, nil, stateGenerationOptions._diff, multiMod.params )
		end
	end
end

local function unload( modApi, params )
	multiMod.params = nil
end

local function earlyInit( modApi )
	modApi.requirements = {"Quick Loader"}
end

return {
	initStrings = initStrings,
	init = init,
	earlyInit = earlyInit,
	load = load,
	unload = unload,
}