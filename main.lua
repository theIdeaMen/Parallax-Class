--
-- Parallax Class Demo main.lua
-- Created by Griffin Adams
-- Revised by Tim Catania
--
-- Version: 0.4
--

local parallax = require( "parallax" )

display.setStatusBar( display.HiddenStatusBar )


------------------------------------------------
-- Screen objects, physics objects, etc.
------------------------------------------------
-- create new parallax scene
local myScene = parallax.newScene(
{
	width = 1500,
	height = 500,
	bottom = 320,            -- So the bottom lines up with the bottom of the screen
	left = 0,
    repeated = false         -- Optional, repeated defaults to false
} )

-- repeated grass foreground
myScene:newLayer(
{
	image = "grass.png",
	width = 410,               -- This is dimensions of the image
	height = 62,
	bottom = 320,              -- Sometimes it makes sense to use bottom/left
	left = 0,
    speed = 1.4,
    repeated = "horizontal"    -- You can choose "horizontal" "vertical" or "both" directions to repeat
} )

-- repeated cloud layer
myScene:newLayer(
{
	image = "clouds.png",
	width = 629,
	height = 61,
	top = -216,                 -- Sometimes it makes sense to use top/left
	left = 0,
	speed = 1.2,
	repeated = "horizontal"
} )

-- left-most hills
local leftHills = myScene:newLayer(
{
	image = "hills_left.png",
	width = 500,
	height = 188,
	bottom = 320,
	left = 0,
	speed = 1                -- If speed is not defined, it will default to (1 / layer index)
} )

-- center hills
local centerHills = myScene:newLayer(
{
	image = "hills_center.png",
	width = 502,
	height = 182,
	bottom = 320,
	left = leftHills.width,   -- Start these hills at the end of the left hills
    speed = 1
} )

-- right hills
myScene:newLayer(
{
	image = "hills_right.png",
	width = 500,
	height = 212,
	bottom = 320,
	left = leftHills.width + centerHills.width,
    speed = 1
} )

-- repeated horizon background
local ground = myScene:newLayer(
{
	image = "ground.png",
	width = 480,
	height = 106,
	bottom = 320,
	left = 0,
    speed = 0.6,
    repeated = "horizontal"
} )

-- repeated sky background
local sky = myScene:newLayer(
{
	image = "sky.png",
	width = 480,
	height = 500,
	top = -180,
	left = 0,
    speed = 1,
    repeated = "horizontal"
} )

-- add a mountain to the background
local mountain = display.newImageRect( "mountain.png", 618, 321 )

myScene:insertObj( mountain, ground )      -- The mountain is now a part of the ground layer

mountain.anchorx = 0
mountain.x = 240
mountain.y = 250


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
        myScene.yPrev = event.y
		
	elseif phase == "moved" then
		-- move scene as the event moves
		myScene:move( event.x - myScene.xPrev, event.y - myScene.yPrev )
		-- store location as previous
		myScene.xPrev = event.x
        myScene.yPrev = event.y
	
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

--timer.performWithDelay( 3000, function() print( collectgarbage("count"), system.getInfo("textureMemoryUsed") ) end, 0 )
