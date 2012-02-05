local M = {}
--====================================================================--      
-- PARALLAX CLASS
--====================================================================--
--
-- Version: 0.7
-- Made by Griffin Adams ( theIdeaMen ) 2011-2012
-- Twitter: http://www.twitter.com/theIdeaMen
-- eMail: duff333@gmail.com
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
-- 02-05-2012 - Griffin Adams - Major update/rewrite
--                            - see 'Old' branch for previous history
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
--			[repeated = [REPEAT FOREVER, "horizontal","vertical","both"]
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
--			[top = [IMAGE Y POS],]
--          [bottom = [IMAGE Y POS],]
--			left = [IMAGE X POS],
--			speed = [HOW FAST, 0 - 1 for backgrounds, > 1 for foregrounds],
--			[repeated = [INF SCROLL, "horizontal","vertical","both"]]
--		} )
--
-- NOTE: Create your layers in order from closest to farthest away
-- NOTE: All x/y coordinates should be in relation to the screen (not local)
--
--
-- * To add objects to a layer
--
--   yourScene:insertObj( object, [layer] )
--
-- NOTE: If no layer specified, defaults to the top layer
-- 
--
--
-- * To move a scene
--
--   yourScene:move( deltaX, deltaY )
--
--====================================================================--


--====================================================================--
--  LIMITS UTILITY - helps with limit checking
--====================================================================--
local function limitsCheck( group, worldLimits )

    -- adjust the world limits based on the device screen size
    local adjustX = ( display.contentWidth - display.screenOriginX * 2 ) - worldLimits.XMax
    local adjustY = ( display.contentHeight - display.screenOriginY * 2 ) - worldLimits.YMax
    
    local direction = group.repeated
    
    if ( direction == "vertical" or direction == false ) then
        if group.x > 0 then
            group.x = 0
        elseif group.x < adjustX  then
            group.x = adjustX
        end
    end
    
    if ( direction == "horizontal" or direction == false ) then
        if group.y < 0 then
            group.y = 0
        elseif group.y > -adjustY then
            group.y = -adjustY
        end
    end
    
end


--====================================================================--
--  LEAP-FROG UTILITY - helps infinite scroll do its job
--====================================================================--
local function leapFrog( low, high, bgTable, down )

    if ( down ) then
        low = high
        for i = 1, #bgTable do
            if ( high == bgTable[i] ) then
                if ( i == 1 ) then
                    high = bgTable[#bgTable]
                else
                    high = bgTable[i-1]
                end
                break
            end
        end
        
    else
        high = low
        for i = 1, #bgTable do
            if ( low == bgTable[i] ) then
                if ( i == #bgTable ) then
                    low = bgTable[1]
                else
                    low = bgTable[i+1]
                end
                break
            end
        end
        
    end
    
    return low, high

end


--====================================================================--
--  INFINITE SCROLL UTILITY - layer management for infinite scroll
--====================================================================--
local function infiniteScroll( group, worldLimits )

    local screenOffsetW = display.contentWidth - display.viewableContentWidth - display.screenOriginX
    local screenOffsetH = display.contentHeight - display.viewableContentHeight - display.screenOriginY
    
    -- adjust the world limits based on the device screen size
    local adjustX = ( display.contentWidth + screenOffsetW * 2 )
    local adjustY = ( display.contentHeight + screenOffsetH * 2 )
    
    local direction = group.repeated
    
    
    if ( direction == "horizontal" ) then
        local leftMostX, leftMostY = group.leftMost:localToContent(-group.leftMost.width*0.5,0)
        local rightMostX, rightMostY = group.rightMost:localToContent(group.rightMost.width*0.5,0)

        if ( leftMostX > -screenOffsetW ) then
            group.rightMost.x = group.leftMost.x - group.bgX[1].width
            group.leftMost, group.rightMost = leapFrog( group.leftMost, group.rightMost, group.bgX, true )
        elseif ( rightMostX < adjustX ) then
            group.leftMost.x = group.rightMost.x + group.bgX[1].width
            group.leftMost, group.rightMost = leapFrog( group.leftMost, group.rightMost, group.bgX )
        end
        
    elseif ( direction == "vertical" ) then
        local bottomMostX, bottomMostY
        local topMostX, topMostY
        
        if ( group.top ) then
            topMostX, topMostY = group.topMost:localToContent(0,group.topMost.height*0.5)
            bottomMostX, bottomMostY = group.bottomMost:localToContent(0,-group.bottomMost.height*0.5)
        elseif ( group.bottom ) then
            topMostX, topMostY = group.topMost:localToContent(0,-group.topMost.height*0.5)
            bottomMostX, bottomMostY = group.bottomMost:localToContent(0,group.bottomMost.height*0.5)
        end

        if ( topMostY > -screenOffsetH ) then
            group.bottomMost.y = group.topMost.y - group.bgY[1].height
            if ( group.top ) then
                group.topMost, group.bottomMost = leapFrog( group.topMost, group.bottomMost, group.bgY )
            elseif ( group.bottom ) then
                group.bottomMost, group.topMost = leapFrog( group.bottomMost, group.topMost, group.bgY, true )
            end
        elseif ( bottomMostY < adjustY ) then
            group.topMost.y = group.bottomMost.y + group.bgY[1].height
            if ( group.top ) then
                group.topMost, group.bottomMost = leapFrog( group.topMost, group.bottomMost, group.bgY )
            elseif ( group.bottom ) then
                group.bottomMost, group.topMost = leapFrog( group.bottomMost, group.topMost, group.bgY, true )
            end
        end
        
    elseif ( direction == "both" ) then
        local leftMostX, leftMostY = group.leftMost:localToContent(-group.leftMost.width*0.5,0)
        local rightMostX, rightMostY = group.rightMost:localToContent(group.rightMost.width*0.5,0)
        local bottomMostX, bottomMostY
        local topMostX, topMostY
        
        if ( group.top ) then
            topMostX, topMostY = group.topMost:localToContent(0,group.topMost.height*0.5)
            bottomMostX, bottomMostY = group.bottomMost:localToContent(0,-group.bottomMost.height*0.5)
        elseif ( group.bottom ) then
            topMostX, topMostY = group.topMost:localToContent(0,-group.topMost.height*0.5)
            bottomMostX, bottomMostY = group.bottomMost:localToContent(0,group.bottomMost.height*0.5)
        end

        if ( leftMostX > -screenOffsetW ) then
            for i = 1, #group.bgY do
                if ( group.rightMost == group.bgY[i][1] ) then
                    for j = 1, #group.bgY[i] do
                        group.bgY[i][j].x = group.leftMost.x - group.bgX[1].width
                    end
                    group.leftMost = group.rightMost
                    if ( i == 1 ) then
                        group.rightMost = group.bgY[#group.bgY][1]
                    else
                        group.rightMost = group.bgY[i-1][1]
                    end
                    break
                end
            end
            
        elseif ( rightMostX < adjustX ) then
            for i = 1, #group.bgY do
                if ( group.leftMost == group.bgY[i][1] ) then
                    for j = 1, #group.bgY[i] do
                        group.bgY[i][j].x = group.rightMost.x + group.bgX[1].width
                    end
                    group.rightMost = group.leftMost
                    if ( i == #group.bgY ) then
                        group.leftMost = group.bgY[1][1]
                    else
                        group.leftMost = group.bgY[i+1][1]
                    end
                    break
                end
            end
        end
        
        if ( topMostY > -screenOffsetH ) then
            for i = 1, #group.bgY[1] do
                if ( group.bottomMost == group.bgY[1][i] ) then
                    for j = 1, #group.bgY do
                        group.bgY[j][i].y = group.topMost.y - group.bgX[1].height
                    end
                    group.topMost = group.bottomMost
                    if ( group.top ) then
                        if ( i == 1 ) then
                            group.topMost = group.bgY[1][#group.bgY[1]]
                        else
                            group.topMost = group.bgY[1][i-1]
                        end
                    elseif ( group.bottom ) then
                        if ( i == #group.bgY[1] ) then
                            group.bottomMost = group.bgY[1][1]
                        else
                            group.bottomMost = group.bgY[1][i+1]
                        end
                    end
                    break
                end
            end
            
        elseif ( bottomMostY < adjustY ) then
            for i = 1, #group.bgY[1] do
                if ( group.topMost == group.bgY[1][i] ) then
                    for j = 1, #group.bgY do
                        group.bgY[j][i].y = group.bottomMost.y + group.bgX[1].height
                    end
                    group.bottomMost = group.topMost
                    if ( group.top ) then
                        if ( i == #group.bgY[1] ) then
                            group.bottomMost = group.bgY[1][1]
                        else
                            group.bottomMost = group.bgY[1][i+1]
                        end
                    elseif ( group.bottom ) then
                        if ( i == 1 ) then
                            group.topMost = group.bgY[1][#group.bgY[1]]
                        else
                            group.topMost = group.bgY[1][i-1]
                        end
                    end
                    break
                end
            end
            
        end

--[[        -- Not working yet
    else
        
        if ( group.x + worldLimits.XMax + group.bgX[1].x < adjustX ) then
            group.bgX[1].x = worldLimits.XMax + group.bgX[1].x
        elseif ( group.x - worldLimits.XMax + group.bgX[1].x + group.bgX[1].width > -screenOffsetW ) then
            group.bgX[1].x = worldLimits.XMin - worldLimits.XMax + group.bgX[1].x
        end
        
        if ( group.y + worldLimits.YMax + group.bgY[1].y < -screenOffsetH ) then
            group.bgY[1].y = worldLimits.YMax + group.bgY[1].y
        elseif ( group.y - worldLimits.YMax + group.bgY[1].y + group.bgY[1].height > adjustY ) then
            group.bgY[1].y = worldLimits.YMin - worldLimits.YMax + group.bgY[1].y
        end
]]--        
    end
    
end


--====================================================================--
--  REPEATED LAYER UTILITY - creates copies for repeated layers
--====================================================================--
local function makeCopies( group, worldLimits )
    
    local sceneWidth  = worldLimits.XMax
    local sceneHeight = worldLimits.YMax
    local direction   = group.repeated
    local xCopies, yCopies
        
    if ( direction == "horizontal" ) then
        xCopies = math.ceil( ( sceneWidth * group.speed ) / group.bgX[1].width ) + 1
        for i = 2, xCopies do
            group.bgX[i] = display.newImageRect( group, group.image, group.bgX[1].width, group.bgX[1].height )
            if ( group.top ) then
                group.bgX[i]:setReferencePoint( display.TopLeftReferencePoint )
            elseif ( group.bottom ) then
                group.bgX[i]:setReferencePoint( display.BottomLeftReferencePoint )
            end
            group.bgX[i].x = ( group.bgX[1].width * ( i - 1 ) ) + worldLimits.XMin
            group.bgX[i].y = group.bgX[1].y
            group.bgX[i]:toBack()
        end
        group.leftMost = group.bgX[1]
        group.rightMost = group.bgX[xCopies]
    end
    
    
    if ( direction == "vertical" ) then
        yCopies = math.ceil( ( sceneHeight * group.speed ) / group.bgY[1].height ) + 1
        for i = 2, yCopies do
            group.bgY[i] = display.newImageRect( group, group.image, group.bgY[1].width, group.bgY[1].height )
            if ( group.top ) then
                group.bgY[i]:setReferencePoint( display.TopLeftReferencePoint )
                group.bgY[i].y = group.bgY[1].y + ( group.bgY[1].height * ( i - 1 ) )
            elseif ( group.bottom ) then
                group.bgY[i]:setReferencePoint( display.BottomLeftReferencePoint )
                group.bgY[i].y = group.bgY[1].y - ( group.bgY[1].height * ( i - 1 ) )
            end
            group.bgY[i].x = group.bgY[1].x
            group.bgY[i]:toBack()
        end
        if ( group.top ) then
            group.bottomMost = group.bgY[yCopies]
            group.topMost = group.bgY[1]
        elseif ( group.bottom ) then
            group.bottomMost = group.bgY[1]
            group.topMost = group.bgY[yCopies]
        end
    end
    
    -- Nested loops to create 2-D matrix of a "both" repeated layer
    if ( direction == "both" ) then
        xCopies = math.ceil( ( sceneWidth * group.speed ) / group.bgY[1].width )
        yCopies = math.ceil( ( sceneHeight * group.speed ) / group.bgY[1].height )
        for i = 1, xCopies do
            group.bgY[i] = {}
            
            for j = 1, yCopies do
                group.bgY[i][j] = display.newImageRect( group, group.image, group.bgX[1].width, group.bgX[1].height )
                if ( group.top ) then
                    group.bgY[i][j]:setReferencePoint( display.TopLeftReferencePoint )
                    group.bgY[i][j].y = group.bgX[1].y + ( group.bgX[1].height * ( j - 1 ) )
                elseif ( group.bottom ) then
                    group.bgY[i][j]:setReferencePoint( display.BottomLeftReferencePoint )
                    group.bgY[i][j].y = group.bgX[1].y - ( group.bgX[1].height * ( j - 1 ) )
                end
                group.bgY[i][j].x = ( group.bgX[1].width * ( i - 1 ) ) + worldLimits.XMin
                group.bgY[i][j]:toBack()
            end
            
        end
        group.leftMost = group.bgY[1][1]
        group.rightMost = group.bgY[xCopies][1]
        group.bottomMost = group.bgY[1][1]
        group.topMost = group.bgY[1][yCopies]
    end
    
end

--====================================================================--
--  CREATE NEW SCENE - This is where it all begins
--====================================================================--
local function newScene( params )

    local screenOffsetW = display.contentWidth - display.viewableContentWidth - display.screenOriginX
    local screenOffsetH = display.contentHeight - display.viewableContentHeight - display.screenOriginY
    
    local Group = display.newGroup()
    
    local width    = params.width
    local height   = params.height
    local top      = params.top or false
    local bottom   = params.bottom or false
    local left     = params.left - screenOffsetW
    local repeated = params.repeated or false
    
    local verticalMin
    
    Group:setReferencePoint( display.TopLeftReferencePoint )
    
    if ( top ) then
        top = top - screenOffsetH
        verticalMin = top
        
    elseif ( bottom ) then
        bottom = bottom - screenOffsetH
        verticalMin = bottom - height
        
    end
    

    local moveGroups = {}
    local groupCount = 1
    moveGroups[groupCount] = display.newGroup()

    moveGroups[groupCount].top      = verticalMin
    moveGroups[groupCount].bottom   = bottom
    moveGroups[groupCount].left     = left
    moveGroups[groupCount].repeated = repeated
    moveGroups[groupCount].index    = groupCount
    
    -- You can get scene properties from this. Ex. 'yourScene.prop.x'
    Group.prop = moveGroups[groupCount]
    
    Group:insert( moveGroups[groupCount] )
    
    groupCount = groupCount + 1
    
    local worldLimits = { XMin = left, YMin = verticalMin, XMax = width + screenOffsetW, YMax = height + screenOffsetH }
    
    
--====================================================================--
--  CREATE NEW IMAGE LAYER
--====================================================================--	
    function Group:newLayer( params )
    
        local moveGroups = moveGroups
        
        moveGroups[groupCount] = display.newGroup()
        
        local image    = params.image
        local width    = params.width
        local height   = params.height
        local top      = params.top or false
        local bottom   = params.bottom or false
        local left     = params.left + moveGroups[1].left
        local speed    = params.speed
        local repeated = params.repeated or false
        local id       = params.id
        
        moveGroups[groupCount].bgX = {}
        moveGroups[groupCount].bgY = {}
        local xLocal, yLocal

        moveGroups[groupCount].bgX[1] = display.newImageRect( moveGroups[groupCount], image, width, height )

        if ( top ) then
            top = top
            xLocal, yLocal = Group:contentToLocal(left, top)
            moveGroups[groupCount].bgX[1]:setReferencePoint( display.TopLeftReferencePoint )
            
        elseif ( bottom ) then
            bottom = bottom + screenOffsetH
            xLocal, yLocal = Group:contentToLocal(left, bottom)
            moveGroups[groupCount].bgX[1]:setReferencePoint( display.BottomLeftReferencePoint )
            
        end

        moveGroups[groupCount].bgX[1].x = xLocal
        moveGroups[groupCount].bgX[1].y = yLocal
        
        moveGroups[groupCount].bgY[1] = moveGroups[groupCount].bgX[1]

        moveGroups[groupCount].image    = image
        moveGroups[groupCount].top      = top
        moveGroups[groupCount].bottom   = bottom
        moveGroups[groupCount].left     = left
        moveGroups[groupCount].speed    = speed
        moveGroups[groupCount].repeated = repeated
        moveGroups[groupCount].index    = groupCount
        
        Group:insert( moveGroups[groupCount] )
        
        moveGroups[groupCount]:toBack()

        if ( repeated ) then
            makeCopies( moveGroups[groupCount], worldLimits )
        end
        
        groupCount = groupCount + 1
        
        return moveGroups[groupCount - 1]
        
    end
    
--====================================================================--
--  INSERT OBJECT INTO LAYER
--====================================================================--
    function Group:insertObj( obj, layer )

        local index = layer.index or 1
        local moveGroups = moveGroups
        
        moveGroups[index]:insert( obj )
  
    end

--====================================================================--
--  MOVE THE SCENE
--====================================================================--	
    function Group:move( dx, dy )
  
        local moveGroups = moveGroups

        -- iterate through the layers and move them
        for index, layer in ipairs( moveGroups ) do
        
            if index == 1 then
                layer:translate( dx, dy )
                
                limitsCheck( layer, worldLimits )
                
            elseif layer.speed then
                layer.x = moveGroups[1].x * layer.speed
                layer.y = moveGroups[1].y * layer.speed
                
                if moveGroups[1].repeated then
                    infiniteScroll( layer, worldLimits )
                end

            end
            
        end
    
    end
    
    return Group

end
M.newScene = newScene

return M