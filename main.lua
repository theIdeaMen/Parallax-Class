--
-- Parallax Class Demo main.lua
-- Created by Griffin Adams
--
-- Version: 0.3
--

local parallax = require( "parallax" )

display.setStatusBar( display.HiddenStatusBar )

--Center position of visible playing screen
local center = display.contentCenterX
local middle = display.contentCenterY


------------------------------------------------
-- Screen objects, physics objects, etc.
------------------------------------------------
-- create new parallax scene
local myScene = parallax.newScene(
{
	width = 1920,
	height = 320,
	top = 0,
	left = 0,
    infinite = false
} )

-- add the near layer
local nearLayer = myScene:newLayer(
{
	image = "parallax_near.png",
	width = 1280,
	height = 320,
	top = 0,
	left = 0
} )
nearLayer.alpha = 0.7

-- add the far layer
myScene:newLayer(
{
	image = "parallax_far.png",
	width = 640,
	height = 320,
	top = 0,
	left = 0,
	speed = 0.2,
	repeated = true
} )

-- create a box and add it to top layer (the top layer travels at same speed as player)
local box = display.newRect( center, display.contentHeight - 50, 20, 50 )
myScene:insertObj( box )

-- add box to second layer
box = display.newRect( center, middle - 25, 20, 50 )
myScene:insertObj( box, 2 )

-- add box to third layer
box = display.newRect( center, 0, 20, 50 )
myScene:insertObj( box, 3 )


------------------------------------------------
-- Functions
------------------------------------------------
local function onTouch( event )

	local phase = event.phase

	if phase == "began" then
		-- set scene to 'focused'
		display.getCurrentStage():setFocus( myScene, event.id )
		-- store location as previous
		myScene.xPrev = event.x
		
	elseif phase == "moved" then
		-- move scene as the event moves
		myScene:move( myScene.xPrev - event.x, 0 )
		-- store location as previous
		myScene.xPrev = event.x
	
	elseif phase == "ended" or phase == "cancelled" then
		-- un-focus scene
		display.getCurrentStage():setFocus( myScene, nil )

	end
	
	return true
	
end


--------------------------------------------
-- Events
--------------------------------------------
myScene:addEventListener( "touch", onTouch )
