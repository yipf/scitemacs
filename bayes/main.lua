require("util")
require("api")
require("core")

-- core functions

local check_in=function(sentences,sentence)
	if string.match(sentence,"%S") then 
		table.insert(sentences,sentence)
	end
end

local str2sentences=function(str)
	local sentences={}
	local S,E=1,string.len(str)
	str=string.lower(str)
	for s,e in string.gmatch(str,"()%p%s+()") do
		if S<s then 
			check_in(sentences,string.sub(str,S,s-1))
			S=e
		end
	end
	if S<E then 
		check_in(sentences,string.sub(str,S,E))
	end
	return sentences
end

local analyze_sentence=function(model,sentence)
	local get,set,type=rawget,rawset,type
	local from,relation
	for word in string.gmatch(sentence,"[a-z%-]+") do
		if from then 
			relation=get(model,from)
			if type(relation)~="table" then 
				relation={}
				set(model,from,relation)
			end
			from=get(relation,word)
			-- use the function f(x)=x+1/x to store as large as possible, which is incrementally when x>=1.
			set(relation,word, from and from+1/from or 1)   
		end
		from=word
	end
end

local relation2list=function(relation)
	local list={}
	local push=table.insert
	for k,v in pairs(relation) do
		push(list,k)
	end
	table.sort(list,function(a,b)
		return relation[a]>relation[b]
	end)
	return list
end

local global_candidators={}
local refresh_candidators=function(model)
	local candidators={}
	local set=rawset
	local concat=table.concat
	for word,relation in pairs(model) do
		relation=relation2list(relation)
		if #relation>0 then 
			set(candidators,word,concat(relation,"\n"))
		end
	end
	global_candidators=candidators
end

-- helper functions

local model_path=table.concat({LOCAL_DIR,"bayes","model"},"/")

local load_model=function(filepath)
	return util.str2object(util.file2str(filepath) or "")
end

local model=load_model(model_path) or {}
refresh_candidators(model)

local save_model=function(model,filepath)
	return util.str2file(util.object2str(model),filepath)
end

local update_model=function(model,content)
	local sentences=str2sentences(content)
	for i,sentence in ipairs(sentences) do
		analyze_sentence(model,sentence)
	end
	refresh_candidators(model)
	return save_model(model,model_path)
end

-- interface
bind("Ctrl+Alt+c","Analyze text",function()
	local pane=api.get_active_pane()
	if pane.SelectionEmpty then 
		pane:SelectAll()
	end
	return update_model(model,pane:GetSelText())
end)

bind("Alt+c","Suggest words after current word according to the bayes model",function()
	local pane=api.get_active_pane()
	local pos=pane.CurrentPos
	pane:WordPartLeft()
	pane:WordRightEndExtend()
	local word=pane:GetSelText()
	local candidators=global_candidators[word]
	if candidators then 
		local s,e=api.get_sel_positions(pane)
		pane:InsertText(e," ")
		pane:GotoPos(e+1)
		api.suggest(pane,0,candidators,"\n")
	else
		pane:GotoPos(pos)
		return api.message("No candicator for word %q",word)
	end
end)
