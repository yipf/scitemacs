require("util")
require("api")

-- onchar
local matchers={["("]=")",["["]="]",["{"]="}",["\""]="\""}  
OnChar=function(ch)
	local pane=api.get_active_pane()
	local m=matchers[ch]
	if m then
		pane:InsertText(-1,m)
		return true
	end
	return false
end

OnKey=function(keycode) -- multi level keys support, which aim to process sequential key pressed like `Ctrl+A s p d ...' where `Ctrl+A' is the leader key
	if type(buffer.expect)=="table" then 
		local expect=buffer.expect
		keycode= keycode>=0 and keycode<256 and string.char(keycode) or keycode
		local action=expect[keycode]
		local tp=type(action)
		if tp=="table" then 
			expect=action
		elseif tp=="function" then
			action(api.get_active_pane())
			expect=false
		elseif tp=="string" then
			api.message(action)
		else
			api.message("Invalid option %q, valid options are %q",keycode,table.concat(util.get_keys(expect),"/"))
		end
		buffer.expect=expect
		return true
	end
end

bind=api.make_mode(0,"user_%d")

-- user bind functions
bind("Tab","Smart Tab",function(pane)
	pane=pane or api.get_active_pane()
	if pane.SelectionEmpty then 
		local pos=pane.CurrentPos
		local line_start=pane:PositionFromLine(pane:LineFromPosition(pos))
		if pos==line_start then 
			scite.MenuCommand(IDM_EXPAND)
			return true
		end
		local str=pane:textrange(line_start,pos)
		local dir,sub=string.match(str,"^.-([^\":%s]*/)(%S-)$")
		if dir then -- try expand this path
			if string.sub(dir,1,1)~="/" then 
				dir=props["FileDir"].."/"..dir
			end
			api.suggest(pane,string.len(sub),util.run_shell(string.format("ls -1 -p %q",dir)),"\n")
			return true
		elseif string.match(str,"%S$") then -- try expand abbrev
			scite.MenuCommand(IDM_ABBREV)
			return true
		end
	end
	return pane:Tab()
end)

bind("Escape","Cancel current action",function(pane)
	pane:Cancel()
	editor:GrabFocus()
end)

bind("Alt+d","Dictionary","sdcv -n $(CurrentWord)")

-- spell checker
local suggest_word=function(pane)
	local word=pane:GetSelText()
	local list=util.run_shell(string.format("echo %q | aspell -a",word)):match("\n&.-:%s*(%w.*%w)")
	if list then 
		api.message("%q is wrong!",pane:GetSelText())
		if pane.CurrentPos~=pane.SelectionEnd then pane:SwapMainAnchorCaret() end
		api.suggest(pane,pane.SelectionEnd-pane.SelectionStart,list:gsub("%s*",""),",")
	end
	return list
end

bind("Alt+s","Spell check",function(pane)
	pane=editor
	pane:WordPartLeft()
	pane:WordRightEndExtend()
	if not suggest_word(pane) then
		api.message("%q is right!",pane:GetSelText())
	end
end)

bind("Ctrl+Alt+s","Spell check rest",function(pane)
	pane=editor
	local pos
	local next_one=api.search_text_by_pattern
	repeat
		pos=next_one(pane,"\\w+")
	until pos<0 or suggest_word(pane)
end)

-- smart selectors

bind("Alt+f","Select folding",api.select_fold)
bind("Alt+w","Select Word",api.select_word)
bind("Alt+q","Select Quoted",api.select_quoted)
bind("Alt+b","Select Braced",api.select_braced)
bind("Alt+l","Select Line",api.select_line)
bind("Alt+p","Select paragraph",api.select_paragraph)

bind("Alt+x","Smart select( `?' for help)",{
	["l"]=api.select_line,
	["q"]=api.select_quoted,
	["b"]=api.select_braced,
	["p"]=api.select_paragraph,
	["f"]=api.select_fold,
	["w"]=api.select_word,
	["x"]=function()
		api.message("Exit selection!")
	end,
	["?"]=[[Valid Options:
[block selection] 	l: select line 		f: select fold 		p: select paragraph 	
[inline selection] 	w: select word 		q: select quoted 	b: select braced	
[other options] 	?: show this help 	e: exit current mode]]})

bind("Alt+y","Yank clipboard to current pane",function(pane)
	local content=api.clipboard()
	if pane.SelectionEmpty then 
		pane:InsertText(-1,content)
	else
		pane:ReplaceSel(content)
	end
end)