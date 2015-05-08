

--Sandboxed? environemnt
local sandbox = {
	assert	= 	assert,
	dofile 	= 	dofile,
	error 	=	error,
	_G		= 	nil,
	getmetatable = getmetatable,
	ipairs 	= 	ipairs,
	load	= load,
	loadfile = loadfile,
	next	=	next,
	pairs	=	pairs,
	pcall	=	pcall,
	print 	= 	print,
	rawequal = rawequal,
	rawlen 	= rawlen,
	select	=	select,
	setmetatable = setmetatable,
	tonumber = tonumber,
	tostring = tostring,
	type	= 	type,
	_VERSION = "Lua 5.2",
	xpcall	= xpcall,
	coroutine = coroutine,
	string = { --because modifying string can be unsecure
		byte = string.byte,
		char = string.char,
		dump = string.dump,
		find = string.find,
		format = string.format,
		gmatch = string.gmatch,
		gsub = string.gsub,
		len = string.len,
		lower = string.lower,
		match = string.match,
		rep = string.rep,
		reverse = string.reverse,
		sub = string.sub,
		upper = string.upper
	},
	table = {
		concat = table.concat,
		insert = table.insert,
		pack = table.pack,
		remove = table.remove,
		sort = table.sort,
		unpack = table.unpack
	},
	math = {
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		atan = math.atan,
		atan2 = math.atan2,
		ceil = math.ceil,
		cos = math.cos,
		cosh = math.cosh,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		fmod = math.fmod,
		frexp = math.frexp,
		huge = math.huge,
		ldexp = math.ldexp,
		log = math.log,
		max = math.max,
		min = math.min,
		modf = math.modf,
		pi = math.pi,
		pow = math.pow,
		rad = math.rad,
		random = math.random,
		randomseed = math.randomseed,
		sin = math.sin,
		sinh = math.sinh,
		sqrt = math.sqrt,
		tan = math.tan,
		tanh = math.tanh
	},
	bit32 = {
		arshift = bit32.arshift,
		band = bit32.band,
		bnot = bit32.bnot,
		bor = bit32.bor,
		btest = bit32.btest,
		bxor = bit32.bxor,
		extract = bit32.extract,
		replace = bit32.replace,
		lrotate = bit32.lrotate,
		lshift = bit32.lshift,
		rrotate = bit32.rrotate,
		rshift = bit32.rshift
	},	
	io	=  {
		read = io.read,
		write = io.write,
		flush = io.flush,
		type = io.type,
	},
	os	=  {
		clock = os.clock,
		date = os.date,
		difftime = os.difftime,
		execute = nil,
		exit = nil, -- to be redefined in here i guess.
		getenv = os.getenv,
		remove = os.remove,
		setlocale = os.setlocale,
		time 	= os.time,
		tmpname = os.tmpname,
	},
	debug = {
		traceback = debug.traceback,
	}
}
sandbox._G = sandbox

sandbox.os.exit = function (code)

end

sandbox.os.execute = function () 

end
