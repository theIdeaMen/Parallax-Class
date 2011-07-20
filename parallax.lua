module (..., package.seeall)

--====================================================================--      
-- PARALLAX CLASS
--====================================================================--
--
-- Version: 0.1
-- Made by Griffin Adams ( theIdeaMen ) 2011
-- Twitter: http://www.twitter.com/theIdeaMen
-- Mail: duff333@gmail.com
--
-- You can use and change this class free of purgery or death as long
--  as you promise to have fun.
--
-- Thanks to Brent Sorrentino for a great parallax demo, the
--  the starting point from witch this class was born.
--
--====================================================================--        
-- CHANGES
--====================================================================--
--
-- 7-18-2011 - Griffin Adams - Created
--
--
--====================================================================--
-- INFORMATION
--====================================================================--
--
--
-- * Import the class like this:
--
--   parallax = require( "parallax" )
--
--
-- * To create a new scene
--
--   yourScene = parallax.newScene(
--		{
--			width = [X SCENE SIZE],
--			height = [Y SCENE SIZE],
--			left = [SCENE X BEGINNING POS],
--			top = [SCENE Y BEGINNING POS],
--			[infinite = [REPEAT FOREVER, TRUE/FALSE]
--		} )
--
--
-- * To add a new layer to the scene
--
--   yourScene:newLayer(
--		{
--			image = [IMAGE NAME],
--			width = [IMAGE WIDTH],
--			height = [IMAGE HEIGHT],
--			top = [IMAGE Y POS],
--			left = [IMAGE X POS],
--			[speed = [HOW FAST, 0 - 1]],
--			[repeated = [INF SCROLL, TRUE/FALSE]]
--		} )
--
--
-- * To add objects to a layer
--
--   yourScene:insertObj( object, [layer] )
--
-- NOTE: If no layer specified defaults to the top layer
--        From top back they are numbered 1 to # of Layers
--
--
-- * To move a scene
--
--   yourScene:move( deltaX, deltaY )
--
--====================================================================--



--====================================================================--
--  CREATE NEW SCENE
--====================================================================--
function newScene( params )
	
	local Group = display.newGroup()
	Group:setReferencePoint( display.TopLeftReferencePoint )
	
	local width = params.width
	local height = params.height
	local left = params.left
	local top = params.top
	local infinite = params.infinite or false
	
	local moveGroups = {}
	local groupCount = 1
	moveGroups[groupCount] = display.newGroup()
	moveGroups[groupCount].repeated = infinite
	
	Group:insert( moveGroups[groupCount] )
	
	groupCount = groupCount + 1
	
	local worldLimits = { XMin = left , YMin = top , XMax = width , YMax = height }
	
	
--====================================================================--
--  CREATE NEW IMAGE LAYER
--====================================================================--	
	function Group:newLayer( params )
	
		local moveGroups = moveGroups
		
		moveGroups[groupCount] = display.newGroup()
		
		local image = params.image
		local width = params.width
		local height = params.height
		local top = params.top
		local left = params.left
		local speed = params.speed
		local repeated = params.repeated or false
	
		moveGroups[groupCount].background = display.newImageRect( moveGroups[groupCount], image, width, height )
		moveGroups[groupCount].background:setReferencePoint( display.TopLeftReferencePoint )
		moveGroups[groupCount].background.x = left
		moveGroups[groupCount].background.y = top
		
		moveGroups[groupCount].image = image
		moveGroups[groupCount].speed = speed
		moveGroups[groupCount].repeated = repeated
	
		Group:insert( moveGroups[groupCount] )
		
		moveGroups[groupCount]:toBack()
		
		groupCount = groupCount + 1
		
	end
	
--====================================================================--
--  INSERT OBJECT INTO LAYER
--====================================================================--
	function Group:insertObj( obj, layer )

		local layer = layer or 1
		local moveGroups = moveGroups
		
		moveGroups[layer]:insert( obj )
		
	end

--====================================================================--
--  MOVE THE SCENE
--====================================================================--	
	function Group:move( dx, dy )
	
		local moveGroups = moveGroups

		-- helps with the nasty limits and/or repeated layers
		local function limitsHelper( group )
		
			local worldLimits = worldLimits
		
			-- adjust the world limits based on the device screen size
			local adjustedXMax = display.contentWidth - display.screenOriginX * 2 - worldLimits.XMax
			local adjustedYMax = display.contentHeight - display.screenOriginY * 2 - worldLimits.YMax
		
			if group.repeated then
				if group.bgCopy then
					local bgX, bgY = group.background:localToContent( -group.background.width * 0.5, -group.background.height * 0.5 )
					local copyX, copyY = group.bgCopy:localToContent( -group.bgCopy.width * 0.5, -group.bgCopy.height * 0.5 )
					
					if bgX > copyX then
						if bgX < display.contentWidth - display.screenOriginX * 2 - group.background.width then
							group.bgCopy.x = group.background.x + group.background.width - 1
						end
						if copyX > 0 then
							group.background.x = group.bgCopy.x - group.bgCopy.width + 1
						end
					elseif bgX < copyX then
						if copyX < display.contentWidth - display.screenOriginX * 2 - group.bgCopy.width then
							group.background.x = group.bgCopy.x + group.bgCopy.width - 1
						end
						if bgX > 0 then
							group.bgCopy.x = group.background.x - group.background.width + 1
						end
					end
					
					if bgY > copyY then
						if bgY < display.contentHeight - group.background.height then
							group.bgCopy.y = group.background.y + group.background.height - 1
						end
						if copyY > 0 then
							group.background.y = group.bgCopy.y - group.bgCopy.height + 1
						end
					elseif bgY < copyY then
						if copyY < display.contentHeight - group.bgCopy.height then
							group.background.y = group.bgCopy.y + group.bgCopy.height - 1
						end
						if bgY > 0 then
							group.bgCopy.y = group.background.y - group.background.height + 1
						end
					end
				-- make a copy of this layer background if at a limit
				elseif group.x > worldLimits.XMin or group.x < display.contentWidth - display.screenOriginX * 2 - group.width then
					group.bgCopy = display.newImageRect( group, group.image, group.width, group.height )
					group.bgCopy:setReferencePoint( display.TopLeftReferencePoint )
					group.bgCopy.y = group.background.y
					if group.x > worldLimits.XMin then
						group.bgCopy.x = group.background.x - group.background.width + 1
					else
						group.bgCopy.x = group.background.x + group.background.width - 1
					end
					
				elseif group.y > worldLimits.YMin or group.y < display.contentHeight - display.screenOriginY * 2 - group.height then
					group.bgCopy = display.newImageRect( group, group.image, group.width, group.height )
					group.bgCopy:setReferencePoint( display.TopLeftReferencePoint )
					group.bgCopy.x = group.background.x
					if group.y > worldLimits.YMin then
						group.bgCopy.y = group.background.y - group.background.height + 1
					else
						group.bgCopy.y = group.background.y + group.background.height - 1
					end

				end
			
			else -- this layer not repeated so check bounds
				if group.x > worldLimits.XMin then
					group.x = worldLimits.XMin
				end
				if group.x < adjustedXMax then
					group.x = adjustedXMax
				end
				if group.y > worldLimits.YMin then
					group.y = worldLimits.YMin
				end
				if group.y < adjustedYMax then
					group.y = adjustedYMax
				end
			end

		end -- end helper
		
		-- iterate through the layers and move them
		for i, v in ipairs( moveGroups ) do
		
			if i == 1 then
				v.x = v.x - dx
				v.y = v.y - dy

				if not v.repeated then
					limitsHelper( v )
				end
				
			elseif v.speed then
				v.x = moveGroups[1].x * v.speed
				v.y = moveGroups[1].y * v.speed
				limitsHelper( v )
	
			else
				-- assign a speed based on position of group
				v.x = moveGroups[1].x * 1 / i
				v.y = moveGroups[1].y * 1 / i
				limitsHelper( v )
				
			end
			
		end
		
	end
	
	return Group

end