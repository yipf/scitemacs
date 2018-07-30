require("api")

-- core functions

local get_entries=function()
	local entries=api.get_local("bibtex_entries")
	if type(entries)~="table" then 
		entries={length=0}
		api.set_local("bibtex_entries",entries)
	end
	return entries
end

local add_entry=function(entry)
	if not entry then 
		return 
	end
	local entries=get_entries()
	local n=entries.length
	if n>0 then
		for i=1,n do
			if entries[i]==entry then -- avoid duplication
				return entry
			end
		end
	end
	n=n+1
	entries.length=n
	entries[n]=entry
	return entry
end

local clear_entry=function()
	local entries=get_entries()
	local n=entries.length
	entries.length=0
	return table.concat(entries,",",1,n)
end

-- interface
local local_bind=api.make_mode(20,"bibtex_func_%d",{"bib","bibtex"},{
	["lexer"]="cpp",
	["keywords"]="^@",
})

local_bind("Alt+i","Add bibtex entry",function(pane)
	if pane.SelectionEmpty then 
		local pos=pane.CurrentPos
		local select_fold=api.select_fold
		while(select_fold(pane,pos)) do pos=api.get_sel_positions(pane) end
	end
	local entries=get_entries()
	local s=entries.length
	for entry in string.gmatch("\n"..pane:GetSelText(),"\n[^=]-%{%s*(.-)%s*,") do
		add_entry(entry)
	end
	local e=entries.length
	if s<e then 
		api.message("%q is selected!",table.concat(entries,",",s+1,e))
	else
		api.message("No invalid entry in selection!")
	end
end,"")

local_bind("Ctrl+Alt+i","Show current selection",function()
	api.message(api.clipboard(clear_entry()))
end,"")