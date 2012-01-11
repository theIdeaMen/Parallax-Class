local M = {}
--====================================================================--      
-- PARALLAX CLASS
--====================================================================--
--
-- Version: 0.6
-- Made by Griffin Adams ( theIdeaMen ) 2011
-- Twitter: http://www.twitter.com/theIdeaMen
-- Mail: duff333@gmail.com
--
--  MIT License
-- You can use and change this code free of purgery or death as long
--  as you promise to have fun or something along those lines.
--
-- Thanks to Brent Sorrentino for a great parallax demo, the
--  the starting point from witch this class was born.
--
-- Feedback welcome!
--
--====================================================================--        
-- CHANGES
--====================================================================--
--
--  7-18-2011 - Griffin Adams - Created
--  8-17-2011 - Griffin Adams - newLayer now returns an object
--							  - use yourScene.props.* to access scene properties
--							  - removed 1 pixel overlapping
--  9-05-2011 - Griffin Adams - replaced module() with table
--  9-29-2011 - Griffin Adams - Moved helper function
--                            - replaced content* with viewableContent*
-- 10-01-2011 - Griffin Adams - replaced viewableContent* with screen size offset factor
--							  - multiple fixes for multiple screen sizes
--							  - fixed layers that appear to 'jump' if starting position
--							     was anything other than 0
--  1-11-2012 - Bob Dickinson - fixed multiple screen size issues, for real this time
--              Griffin Adams -
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
--			[speed = [HOW FAST, 0 - 1 for backgrounds, > 1 for foregrounds]],
--			[repeated = [INF SCROLL, TRUE/FALSE]]
--		} )
--
-- NOTE: Create your layers in order from closest to farthest away
--
--
-- * To add objects to a layer
--
--   yourScene:insertObj( object, [layer] )
--
-- NOTE: If no layer specified, defaults to the top layer
--        From top back they are numbered 1 to # of Layers
--
--
-- * To move a scene
--
--   yourScene:move( deltaX, deltaY )
--
--====================================================================--


--====================================================================--
--  LIMITS UTILITY - helps with limit checking and/or repeated layers
--====================================================================--
local function limitsHelper( group, worldLimits )

    -- adjust the world limits based on the device screen size
    local adjustX = display.contentWidth - display.screenOriginX * 2
    local adjustY = display.contentHeight + display.screenOriginY * 2

    if group.repeated then

        -- background copy already exists, check if at a limit
        if group.bgCopy then
            local bgX, bgY = group.background:localToContent( -group.background.width * 0.5, -group.background.height * 0.5 )
            local copyX, copyY = group.bgCopy:localToContent( -group.bgCopy.width * 0.5, -group.bgCopy.height * 0.5 )

            if bgX > copyX then
                if bgX < adjustX - group.background.width then
                    group.bgCopy.x = group.background.x + group.background.width
                end
                if copyX > worldLimits.XMin then
                    group.background.x = group.bgCopy.x - group.bgCopy.width
                end
            elseif bgX < copyX then
                if copyX < adjustX - group.bgCopy.width then
                    group.background.x = group.bgCopy.x + group.bgCopy.width
                end
                if bgX > worldLimits.XMin then
                    group.bgCopy.x = group.background.x - group.background.width
                end
            end
            
            if bgY > copyY then
                if bgY < adjustY - group.background.height then
                    group.bgCopy.y = group.background.y + group.background.height
                end
                if copyY > worldLimits.YMin then
                    group.background.y = group.bgCopy.y - group.bgCopy.height
                end
            elseif bgY < copyY then
                if copyY < adjustY - group.bgCopy.height then
                    group.background.y = group.bgCopy.y + group.bgCopy.height
                end
                if bgY > worldLimits.YMin then
                    group.bgCopy.y = group.background.y - group.background.height
                end
            end
            
        -- make a copy of this layer background if at a limit
        elseif group.x > 0 or group.x < adjustX - group.width then
            group.bgCopy = display.newImageRect( group, group.image, group.width, group.height )
            group.bgCopy:setReferencePoint( display.TopLeftReferencePoint )
            group.bgCopy.y = group.background.y
            if group.x > 0 then
                group.bgCopy.x = group.background.x - group.background.width
            else
                group.bgCopy.x = group.background.x + group.background.width
            end
        
        elseif group.y > 0 or group.y < adjustY - worldLimits.YMax then
            group.bgCopy = display.newImageRect( group, group.image, group.width, group.height )
            group.bgCopy:setReferencePoint( display.TopLeftReferencePoint )
            group.bgCopy.x = group.background.x
            if group.y > 0 then
                group.bgCopy.y = group.background.y - group.background.height
            else
                group.bgCopy.y = group.background.y + group.background.height
            end

        end
    
    else -- this layer not repeated so check bounds
        if group.x > 0 then
            group.x = 0
        end
        if group.x < adjustX - worldLimits.XMax then
            group.x = adjustX - worldLimits.XMax
        end
        if group.y > 0 then
            group.y = 0
        end
        if group.y < adjustY - worldLimits.YMax then
            group.y = adjustY - worldLimits.YMax
        end
    end

end -- end helper


--====================================================================--
--  CREATE NEW SCENE - This is where it all begins
--====================================================================--
local function newScene( params )

    local screenOffsetW = display.contentWidth - display.viewableContentWidth - display.screenOriginX
    local screenOffsetH = display.contentHeight - display.viewableContentHeight - display.screenOriginY
    
    local Group = display.newGroup()
    Group:setReferencePoint( display.TopLeftReferencePoint )
    
    local width    = params.width
    local height   = params.height
    local top      = params.top - screenOffsetH
    local left     = params.left - screenOffsetW
    local infinite = params.infinite or false
    
    local moveGroups = {}
    local groupCount = 1
    moveGroups[groupCount] = display.newGroup()
    moveGroups[groupCount].repeated = infinite
    
    -- You can get scene properties from this. Ex. 'yourScene.prop.x'
    Group.prop = moveGroups[groupCount]
    
    Group:insert( moveGroups[groupCount] )
    
    groupCount = groupCount + 1
    
    local worldLimits = { XMin = left, YMin = top, XMax = width + screenOffsetW, YMax = height + screenOffsetH }
    
    
--====================================================================--
--  CREATE NEW IMAGE LAYER
--====================================================================--	
    function Group:newLayer( params )
    
        local moveGroups = moveGroups
        
        moveGroups[groupCount] = display.newGroup()
        
        local image    = params.image
        local width    = params.width
        local height   = params.height
        local top      = params.top - screenOffsetH
        local left     = params.left - screenOffsetW
        local speed    = params.speed
        local repeated = params.repeated or false
        local id       = params.id

        moveGroups[groupCount].background = display.newImageRect( moveGroups[groupCount], image, width, height )
        moveGroups[groupCount].background:setReferencePoint( display.TopLeftReferencePoint )
        moveGroups[groupCount].background.x = left
        moveGroups[groupCount].background.y = top

        moveGroups[groupCount].image = image
        moveGroups[groupCount].left = left
        moveGroups[groupCount].top = top
        moveGroups[groupCount].speed = speed
        moveGroups[groupCount].repeated = repeated
    
        Group:insert( moveGroups[groupCount] )
        
        moveGroups[groupCount]:toBack()
        
        groupCount = groupCount + 1
        
        return moveGroups[groupCount - 1]
        
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

        -- iterate through the layers and move them
        for index, layer in ipairs( moveGroups ) do
        
            if index == 1 then
                layer.x = layer.x - dx
                layer.y = layer.y - dy

                if not layer.repeated then
                    limitsHelper( layer, worldLimits )
                end
                
            elseif layer.speed then
                layer.x = moveGroups[1].x * layer.speed
                layer.y = moveGroups[1].y * layer.speed

                limitsHelper( layer, worldLimits )
    
            else
                -- assign a speed based on position of layer
                layer.x = moveGroups[1].x * 1 / index
                layer.y = moveGroups[1].y * 1 / index
                
                limitsHelper( layer, worldLimits )

            end
            
        end
        
    end
    
    return Group

end
M.newScene = newScene

return M
