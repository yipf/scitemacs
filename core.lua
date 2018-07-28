-- internal helper functions

local keys={}
local register_key=function(current, key, des, action)
	local keys=keys
	local n=0
	local child
	for k in string.gmatch(key, "%S") do
		n=n+1
		keys[n]=k
		child=current[k]
		if type(child)~="table" or type(child.action)=="function" then 
			child={key=table.concat(keys, "\t", 1, n)}
		end
		current=child
	end
	current.action=action
	current.description=des
end

local copy_entry
copy_entry=function(dst,src)
	if type(src.action)=="function" then -- if src is an entry
		return register_key(dst,src.key,src.description , src.action)
	else
		for k,v in pairs(src) do
			copy_entry(dst,v)
		end
	end
end

local make_mode=function(...)
	local mode={}
	for i,parent in ipairs({...}) do
		copy_entry(mode,parent)
	end
	return function(key, des, func)
		if not key then return mode end
		return register_key(mode, key, des, func)
	end
end

-- interface

local modes={["*"]={}}

local load_mode_=function(name)
	if type(name)=="table" then 
		return name
	end
	return modes[name] or modes["*"]
end

register_mode=function(name,config,...)
	local mode={}
	modes[name]=mode
	for i,parent in ipairs({...}) do
		copy_entry(mode,load_mode_(parent))
	end
	return function(key, des, func)
		if not key then return mode end
		return register_key(mode, key, des, func)
	end
end

general_onkey=function(key)
	local mode=(buffer.mode or load_mode_(props["language"]))[key]
	if type(mode)~="table" then 
		mode=load_mode_(props["language"])
		return false
	elseif type(mode.action)=="function" then
		mode.action()
		mode=load_mode_(props["language"])
	end
	buffer.mode=mode
	return true
end


