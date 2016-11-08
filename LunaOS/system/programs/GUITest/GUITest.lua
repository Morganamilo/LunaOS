local function gui(a)
	default = GUI.Theme()

	f = GUI.Frame()

	f:applyTheme(default)

	function setText(lbl, a,b,c,d,e)
		a = tostring(a) or ""
		b = tostring(b) or ""
		c = tostring(c) or ""
		d = tostring(d) or ""
		e = tostring(e) or ""

		lbl.text = a..' '..b..' '..c..' '..d..' '..e .. "\n".. (tostring(f.focus) or "")
	end

	eventListner = GUI.Label(1,1,30,2,"events")
	eventListner:applyTheme(default)
	eventListner.backgroundColour = colourUtils.blits.green
	eventListner:addEventListener("", setText)
	eventListner:addEventListener("terminate", function() f:stop() end)
	ls = GUI.Label(2,1,1,12,"123456789abc")

	v2 = GUI.View(2, 2, 49, 17) --1.1
	v = GUI.ScrollView(4, 4, 44, 13, 70, 80)
	v3 = GUI.View(28, 3, 6, 16)

	v2:addComponent(ls)
	ls:applyTheme(default)
	f:addComponent(eventListner)
	--f:addComponent(v2)
	f:addComponent(v)


	--v3 = GUI.View(2,2,20,20)
	--v2:addComponent(v3)
	--v3.backgroundColour = "-1"



	v:applyTheme(default)
	v2:applyTheme(default)
	v3:applyTheme(default)
	v2.backgroundColour = "4"
	--v2:addComponent(v)
	vl = GUI.Button(2,10,5,1,"test")
	vl:applyTheme(default)
	v:addComponent(vl)

		v.backgroundColour = "0"

	oldf = f
	f = v

	sw1 = GUI.Switch(3,2,2,2)
	sw1:transform(-1,-1)
	sw2 = GUI.Switch(3,8,2,2)
	sw3 = GUI.Switch(3,11,2,2)
	sw4 = GUI.RadioButton(3,14)
	pb= GUI.ProgressBar(3,17,40,1,"this is progress")
	pb.maxProgress = 20


	l1 = GUI.Label(10, 8, 10 , 4)
	tb = GUI.ToggleButton(3,5,5,2)

	sw1:applyTheme(default)
	sw2:applyTheme(default)
	sw3:applyTheme(default)
	sw4:applyTheme(default)

	tb:applyTheme(default)
	l1:applyTheme(default)

	pb:applyTheme(default)

	sbh= GUI.HorizontalScrollbar(25, 14, 14, 1, 8)
	sb2= GUI.Scrollbar(23, 2, 1, 14, 8)








	sbh:applyTheme(default)
	sb2:applyTheme(default)




	counter = 0

	b = GUI.Button(10,2,10,4,"this is a test")

	c = GUI.Menu()
	c:applyTheme(default)
	c:addItem("Copy")
	c:addSeparator("-")
	c:addItem("Cut")
	c:addItem("Paste")
	c:addItem("Paste")
c:addItem("Paste")
	c:addItem("Paste")

	function b:onRightClick(event, mouse, xPos, yPos)
		local realXPos, realYPos = self:getAbsolutePos()
		counter = counter + 1
		self.text = "i have been pressed " .. counter   .. " times"
		pb.progress = counter
		c:popup(b, xPos, yPos)
	end



	b:applyTheme(default)

	tf1 = GUI.TextField(28,2,20)
	tf2 = GUI.TextField(28,4,20)
	tf1:applyTheme(default)
	tf2:applyTheme(default)
	tf1.mask = ""
	tf1.hint = "Username:"
	tf1.backgroundColour = "1"

	function tf1:onChange()
		self.textColour = 2^(math.random(0,15))
	end

	f:addComponent(sw1)
	f:addComponent(sw2)
	f:addComponent(sw3)
	f:addComponent(sw4)
	f:addComponent(b)
	f:addComponent(tb)
	f:addComponent(tf1)
	f:addComponent(tf2)
	f:addComponent(l1)
	f:addComponent(sbh)
	f:addComponent(sb2)





	f:addComponent(pb)


	tg2 = GUI.ToggleButton(2,2,4,3)
	tg2:applyTheme(default)







	group = GUI.Group(false, false)

	group:addComponent(sw1)
	group:addComponent(sw2)
	group:addComponent(sw3)
	group:addComponent(sw4)
	group:addComponent(tb)

	function group:onChange()
		local s
		local selected = group:getSelected()[1]

		if selected == sw1 then
			s = "switch one"
		elseif selected == sw2 then
			s = "switch two"
		elseif selected == sw3 then
			s = "switch three"
		elseif selected == sw4 then
			s = "switch four"
		elseif selected == tb then
			s = "the toggle button"
		else
			s = "nothing"
		end

		l1:setText(s .. " is selected")
	end

	f = oldf

	b6 = GUI.TextField(4,4,15,"test")
	--b6 = GUI.Button(4,4,15,3,"test")
	b6:applyTheme(default)
	v3:addComponent(b6)

	local open = 1
	v2:addComponent(b6)

	--mv = GUI.TabbedView(2,2,20,16)
	--mv:addView(v, "1")
	--mv:addView(v2, "2")
	--mv:addView(v3, "3")
	--f:addComponent(mv)
	--f:addComponent(v2)
	--mv:gotoView("1")

	function n()
		mv:gotoView(tostring(open))
		open = open + 1
	end

	--mv:addEventListener("key", n)

	if a then f:mainLoop() else dofile("rom/programs/lua") end

end

local args = {...}
gui(args[1])
