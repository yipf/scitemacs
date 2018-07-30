module("util",package.seeall)

factory=function(registerer)
	local container={}
	local set,get=rawset,rawget
	if type(registerer)~="function" then 
		registerer=set
	end
	return function(key,value)
		if not key then return container end
		if not value then return get(container,key) end
		registerer(container,key,value)
		return value
	end
end

run_shell=function(cmd,body)
	if body then 
		cmd=cmd.." <<EOF\n"..body.."\nEOF"
	end
	return io.popen(cmd):read("*a")
end

in_range=function(value,min,max)
	if min~=nil and value<min then 
		return false
	end
	if max~=nil and value>max then
		return false
	end
	return true
end

minmax=function(a,b)
	if a>b then 
		return b,a
	end
	return a,b
end

str2object=function(str)
	return loadstring("return "..str)()
end

str2file=function(str,path)
	local f=io.open(path,"w")
	if f then 
		f:write(str)
		f:close()
		return path
	end
end

file2str=function(path)
	local f=io.open(path)
	if f then 
		local s=f:read("*a")
		f:close()
		return s
	end
end

local push=table.insert

local object2str_
object2str_=function(object)
	local tp=type(object)
	local push=table.insert
	local format=string.format
	if tp=="table" then 
		local t={}
		for i,v in ipairs(object) do
			t[i]=object2str_(v)
		end
		for k,v in pairs(object) do
			if t[k]==nil then 
				push(t,format("[%s]=%s",object2str_(k),object2str_(v)))
			end
		end
		return format("{%s}",table.concat(t,","))
	elseif tp=="string" then
		return format("%q",object)
--~ 	elseif tp=="function" then
--~ 		return format("load(%q)",string.dump(object))
	else
		return tostring(object)
	end
end
object2str=object2str_

get_keys=function(tbl)
	assert(type(tbl)=="table","Only table can get keys!")
	local keys={}
	local push=table.insert
	for k,v in pairs(tbl) do
		push(keys,k)
	end
	return keys
end
