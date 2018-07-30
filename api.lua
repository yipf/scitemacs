module("api",package.seeall)

local get_active_pane_=function()
	return editor.Focus and editor or output.Focus and output
end
get_active_pane=get_active_pane_

local anything2lang=function(anything)
	if not anything then return "*" end
	if type(anything)~="table" then return "*."..anything end
	return "*."..table.concat(anything,";*.")
end

make_mode=function(base,namefmt,lang,config)
	base= base or 0
	namefmt=namefmt or "_%d"
	lang=anything2lang(lang)
	-- set up config
	local format=string.format
	if type(config)=="table" then 
		for k,v in pairs(config) do
			props[format("%s.%s",k,lang)]=v
		end
	end
	-- the interface function
	return function(key,des,action)
		base=base+1
		local subsystem,name
		local tp=type(action)
		if tp=="string" then 
			subsystem=1
			name=action
		else
			subsystem=3
			name=format(namefmt,base)
			_G[name]=(tp=="function") and function() return action(get_active_pane_()) end or function() buffer.expect=action end
		end
		local tail=format("%d.%s",base,lang)
		props[format("command.name.%s",tail)]=des or name
		props[format("command.%s",tail)]=name
		props[format("command.subsystem.%s",tail)]=subsystem
		props[format("command.mode.%s",tail)]="savebefore:no"
		props[format("command.shortcut.%s",tail)]=key
	end
end

suggest=function(pane,len,str,sep)
	pane.AutoCSeparator=string.byte(sep or "\n")
	pane.AutoCAutoHide=false
	pane:AutoCShow(len,str)
end

local message_=function(...)
	output:ClearAll()
	return print(string.format(...))
end
message=message_

clear_messages=function()
	return output:ClearAll()
end

local get_sel_positions_=function(pane)
	local s,e=pane.SelectionStart,pane.SelectionEnd
	if s>e then 
		return e,s
	end
	return s,e
end
get_sel_positions=get_sel_positions_

local search_text_by_pattern_=function(pane,pat,prev)
	if pane.SelectionEmpty then 
		s=pane.CurrentPos
		e=s
	else
		s,e=get_sel_positions_(pane)
	end
	if prev then 
		pane:GotoPos(s)
		pane:SearchAnchor()
		return pane:SearchPrev(SCFIND_REGEXP,pat)
	else
		pane:GotoPos(e)
		pane:SearchAnchor()
		return pane:SearchNext(SCFIND_REGEXP,pat)
	end
end
search_text_by_pattern=search_text_by_pattern_

local get_local_values=function()
	if type(buffer.local_values)~="table" then 
		buffer.local_values={}
	end
	return buffer.local_values
end

get_local=function(key)
	local values=get_local_values()
	if key~=nil then return values[key] end
	return values
end

set_local=function(key,value)
	local values=get_local_values()
	if not key then 
		for k,v in pairs(values) do
			values[k]=value
		end
	else
		values[key]=value
	end
end

local clipboard_=""
clipboard=function(content)
	if content then 
		clipboard_=content
	end
	return clipboard_
end

-- selectors

select_fold=function(pane,pos)
	pane=pane or get_active_pane_()
	pos=pos or pane.CurrentPos
	local current_line=pane:LineFromPosition(pos)
	local parent_line=pane.FoldParent[current_line]
	if not parent_line or parent_line<0 then 
		parent_line=current_line
	end
	pane:GotoLine(parent_line)
	pane:SetSel(pane:PositionFromLine(parent_line),pane.LineEndPosition[pane:GetLastChild(parent_line, pane.FoldLevel[parent_line])])
	return parent_line~=current_line
end

select_word=function(pane,pos)
	pane=pane or get_active_pane_()
	pos=pos or pane.CurrentPos
	pane:GotoPos(pos)
	pane:WordPartLeft()
	pane:WordRightEndExtend()
	return message_("Word selecting complete!")
end

select_quoted=function(pane,pos)
	pane=pane or get_active_pane_()
	pos=pos or pane.CurrentPos
	pane:GotoPos(pos)
	local search=api.search_text_by_pattern
	local maybe=search(pane,"[^\\\\]\"",true)
	if maybe>=0 then
		pane:GotoPos(maybe)
		maybe=search(pane,"\".*?[^\\\\]\"")
		if maybe>=0 and util.in_range(pos,api.get_sel_positions(pane)) then
			return message_("Quoted selecting complete!")
		end
	end
	pane:GotoPos(pos)
	return message_("Current pos is not in any quoted block!")
end

select_braced=function(pane,pos)
	pane=pane or get_active_pane_()
	pos=pos or pane.CurrentPos
	pane:GotoPos(pos)
	local search=api.search_text_by_pattern
	local maybe=search(pane,"[\\[\\{\\(]",true)
	local s,e
	while maybe>=0 do
		scite.MenuCommand(IDM_SELECTTOBRACE)
		s,e=api.get_sel_positions(pane)
		if pos>=s and pos<=e then 
			pane:SetSel(s+1,e-1)
			return message_("Brace selecting complete!")
		end
		maybe=search(pane,"[\\[\\{\\(]",true)
	end
	return message_("Current position is not in any brace!")
end

select_line=function(pane,pos)
	pane=pane or get_active_pane_()
	pos=pos or pane.CurrentPos
	pane:GotoPos(pos)
	pane:Home()
	pane:LineEndExtend()
	return message_("Line selecting complete!")
end

select_paragraph=function(pane,pos)
	pane=pane or get_active_pane_()
	pos=pos or pane.CurrentPos
	pane:GotoPos(pos)
	pane:ParaUp()
	pane:ParaDownExtend()
	return message_("Paragraph selecting complete!")
end
