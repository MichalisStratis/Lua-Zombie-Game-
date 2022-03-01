function love.load()

    math.randomseed(os.time())
    coreWidth=720
    coreHeight=960
    scale=1
    shiftdown=0
    pause=0

    osString = love.system.getOS()
    if osString == "Android" or osString == "iOS" then
        scale = love.graphics.getWidth()/coreWidth
        shiftdown = (love.graphics.getHeight() - (coreHeight * scale)) / 2 /scale
    else
        scale = 0.6
    end

    love.window.setMode(coreWidth * scale, coreHeight * scale)

    anim8=require 'libraries/anim8/anim8'
    wf = require "libraries/windfield/windfield"
    timer = require "libraries/hump/timer"
    lume = require "libraries/lume/lume"

    sounds = {}
  
    sounds.music=love.audio.newSource("sounds/ZombieMusic.mp3","stream")
    sounds.gun=love.audio.newSource("sounds/gun.mp3","stream")
    sounds.bomb=love.audio.newSource("sounds/bomb.mp3","stream")
    sounds.ouch=love.audio.newSource("sounds/ouch.mp3","stream")
    sounds.gun:setPitch(1.5)
    sounds.bomb:setPitch(2)
    sounds.ouch:setPitch(1)
   
    sounds.music:setLooping(true)
    sounds.music:play()

    sprites = {}
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.playerSheet=love.graphics.newImage('sprites/playerSheet.png')
    sprites.zombie=love.graphics.newImage('sprites/zombie.png')
    sprites.bomb=love.graphics.newImage('sprites/bomb.png')
    
    local grid=anim8.newGrid(614,564,sprites.playerSheet:getWidth(),sprites.playerSheet:getHeight())

    animations={}
    animations.idle=anim8.newAnimation(grid('1-15',1),0.05)
    animation=animations.idle

     -- 0 is the main menu 
     gamerun = 0
     kills = 0
     killp=0
     timer=0
     maxtime=2
     zombiespawntime=maxtime
     bombtime=30
     bombspawn=bombtime
     health=5
     besttime=0
     explosions=0
    
     
          
     player={}
     player.x=coreWidth/2
     player.y=coreHeight/2
   
     zombies={}
     bombs={}

     require('libraries/show')
     saveData={}
     saveData.bestscore=0
     
    if love.filesystem.getInfo("save.lua") then 
        local data=love.filesystem.load("save.lua")
        data()
    end

     ------------FONT-----------------
     myfont=love.graphics.newFont(30)
     minifont=love.graphics.newFont(20)
     largefont=love.graphics.newFont(70)

    
end 

function love.update(dt)

    animations.idle:update(dt)
        if gamerun==1 or gamerun==3 then 
            if timer>=0 then 
                timer=timer+dt
                if gamerun==1 and timer>=65 then 
                    gamerun=2
                end
                if gamerun==3 and timer>=65 then 
                    gamerun=4
                end
                

            end 
            
            for i,z in ipairs(zombies) do 
                if gamerun==1 then 
                    z.x=z.x+(math.cos(playerzombie(z))*z.speed*dt)
                    z.y=z.y+(math.sin(playerzombie(z))*z.speed*dt)
                elseif gamerun==3 then
                    if z.x<player.x and z.y>player.y then 
                        z.x=z.x+(math.cos(playerzombie(z))*z.speed*dt)
                        for x=z.x,coreWidth/2,100 do 
                                A=5
                                f=0.05
                                B=10 
                                z.y=z.y-A*math.sin(2*math.pi*f*x+B)
                        end  
                    elseif z.x>player.x and z.y<player.y then 
                        z.x=z.x+(math.cos(playerzombie(z))*z.speed*dt)
                        for x=z.x,player.x,-100 do 
                            A=5
                            f=0.05
                            B=10 
                            z.y=z.y-A*math.sin(2*math.pi*f*x+B)
                        end  
                        

                    elseif z.x<player.x and z.y<player.y then 
                        z.x=z.x+(math.cos(playerzombie(z))*z.speed*dt)
                        for x=z.x,player.x,100 do 
                            A=5
                            f=0.05
                            B=10 
                            z.y=z.y+A*math.sin(2*math.pi*f*x+B)
                        end  
                      
                    elseif z.x>player.x and z.y>player.y then 
                        z.x=z.x+(math.cos(playerzombie(z))*z.speed*dt)
                        for x=z.x,player.x,-100 do 
                            A=5
                            f=0.05
                            B=10 
                            z.y=z.y+A*math.sin(2*math.pi*f*x+B)
                        end  
                
                    end

                end 

                if distancebetween(z.x,z.y,player.x,player.y)<z.radius then 
                    sounds.ouch:play()
                    z.dead=true 
                    health=health-1
                end   
            end
            for i=#zombies,1,-1 do 
                local z=zombies[i]
                if z.dead==true then
                    table.remove(zombies,i)
                end
            end

            
            zombiespawntime=zombiespawntime-dt
            if zombiespawntime<=0 then 
                spawnZombie()
                if gamerun==1 then 
                    maxtime=maxtime*0.97
                    zombiespawntime=maxtime
                end 
                if gamerun==3 then 
                    maxtime=maxtime*0.97
                    zombiespawntime=maxtime
                end
          
            end

            

            bombspawn=bombspawn-dt
            if bombspawn<=0 then 
                spawnbomb()
                bombtime=bombtime-3
                bombspawn=bombtime
            end

            for i,b in pairs(bombs) do
                local b=bombs[i]
                if b.explode==true then 
                    table.remove(bombs,x)
                end
            end

            if gamerun==2 or gamerun==4 then
                timer=0
                if kills>saveData.bestscore then 
                    saveData.bestscore=kills
                    love.filesystem.write("save.lua",table.show(saveData, "saveData"))
                end 
                for i=#zombies,1,-1 do 
                    local z=zombies[i]
                    table.remove(zombies,i)
                end
            end 

            if gamerun==1 and health<=0 or gamerun==3 and health<=0 then
                gamerun=5
                if kills>saveData.bestscore then 
                    saveData.bestscore=kills
                    love.filesystem.write("save.lua",table.show(saveData, "saveData"))
                end 
            
            end 
        end
    end 


    ------------------------------------------------------------------------------------------------------------------

    function love.draw()
        -- Scaling all graphics
        love.graphics.scale(scale)

        love.graphics.draw(sprites.background, 0, 0,nil,2,2,1.5)
        if gamerun==0 then 
            love.graphics.setFont(largefont)
            love.graphics.print("Zombie Survive",coreWidth/3-150,coreHeight/2-250+shiftdown)
            love.graphics.setFont(minifont)
            love.graphics.print("Try to save the boy from the evil zombies",coreWidth/5,coreHeight/2-50+shiftdown)
            love.graphics.print("Touch the screen to start the game",coreWidth/5+45,coreHeight/2+shiftdown)
            love.graphics.print("Most kills: "..math.ceil(saveData.bestscore),coreWidth/5+150,coreHeight/2+200+shiftdown)
            

        end 
        if gamerun==1 then 
        
            animation:draw(sprites.playerSheet,coreWidth/2,coreHeight/2+shiftdown,nil,0.2,0.2,130,300)
            love.graphics.setFont(myfont)
            love.graphics.print("Kills: "..kills,5,5)
            love.graphics.print("Health: "..health,coreWidth-150,5)

            love.graphics.print(math.ceil(timer),coreWidth/2,5)
            love.graphics.print("LEVEL 1",coreWidth/2-50,40)

            for i,z in ipairs(zombies) do 
                love.graphics.draw(sprites.zombie,z.x,z.y,playerzombie(z),nil,nil,sprites.zombie:getWidth()/2,sprites.zombie:getHeight()/2)
            end 

            for x,b in ipairs(bombs) do 
                love.graphics.draw(sprites.bomb,b.x,b.y,playerbomb(b),nil,nil,sprites.bomb:getWidth()/2,sprites.bomb:getHeight()/2)

            end 
        end

        if gamerun==2 then 
            
            love.graphics.setFont(minifont)
            love.graphics.print("You managed to keep the boy alive!!!",coreWidth/3-65,coreHeight/2-50+shiftdown)
            love.graphics.print("Press the P button to proceed to the next level",coreWidth/3-100,coreHeight/2+shiftdown)
            love.graphics.print("Most kills: "..math.ceil(saveData.bestscore),coreWidth/10,coreHeight/10+shiftdown)
            
        end 

        if gamerun==3 then 
        
            animation:draw(sprites.playerSheet,coreWidth/2,coreHeight/2+shiftdown,nil,0.2,0.2,130,300)
            love.graphics.setFont(myfont)
            love.graphics.print("Kills: "..kills,5,5)
            love.graphics.print("Health: "..health,coreWidth-150,5)

            love.graphics.print(math.ceil(timer),coreWidth/2,5)
            love.graphics.print("LEVEL 2",coreWidth/2-50,40)

            for i,z in ipairs(zombies) do 
                love.graphics.draw(sprites.zombie,z.x,z.y,playerzombie(z),nil,nil,sprites.zombie:getWidth()/2,sprites.zombie:getHeight()/2)
            end 

            for x,b in ipairs(bombs) do 
                love.graphics.draw(sprites.bomb,b.x,b.y,playerbomb(b),nil,nil,sprites.bomb:getWidth()/2,sprites.bomb:getHeight()/2)

            end 
        end

        if gamerun==4 then 
            
            love.graphics.setFont(minifont)
            love.graphics.print("You managed to keep the boy alive for a second time!!!",coreWidth/3-150,coreHeight/2-50+shiftdown)
            love.graphics.print("Press the P button to proceed to play again",coreWidth/3-90,coreHeight/2+shiftdown)
            love.graphics.print("Most kills: "..math.ceil(saveData.bestscore),coreWidth/10,coreHeight/10+shiftdown)
            
        end 

        if gamerun==5 then 
            
            love.graphics.setFont(minifont)
            
            love.graphics.print("You did not managed to keep the boy alive...Game Over!!!",coreWidth/3-160,coreHeight/2-50+shiftdown)
            love.graphics.print("Press the P button to proceed to play again",coreWidth/3-80,coreHeight/2+shiftdown)
            love.graphics.print("Most kills: "..math.ceil(saveData.bestscore),coreWidth/10,coreHeight/10+shiftdown)
            
        end 
    end 

-------------------------------------------------------------------------------------------------------------------

function love.mousepressed(x, y, button, istouch, presses )

    if gamerun==0 then 
        gamerun=1
    end
    
    if button==1 and gamerun==1 or button==1 and gamerun==3 then 
        sounds.gun:play()
        for i,z in ipairs(zombies) do 

            local mousetotarget=distancebetween(z.x,z.y,x/scale,y/scale)
            if mousetotarget<z.radius then 
                kills=kills+1
                z.dead=true
                killp=killp+1
                if killp==5 then 
                    health=health+1
                    z.radius=z.radius+5
                    killp=0
                end

            end
            for i,b in ipairs(bombs) do
                local mousetobomb=distancebetween(b.x,b.y,x/scale,y/scale)
                local bombtozombie=distancebetween(b.x,b.y,z.x,z.y)
                if mousetobomb<b.radius then 
                    sounds.bomb:play()
                    b.explode=true 
                    kills=kills+1
                    killp=killp+1
                    if killp==5 then 
                        health=health+1
                        z.radius=z.radius+5
                        killp=0
                    end
                    if b.explode==true and bombtozombie<400 then 
                        z.dead=true
                        health=health-1
                    end
                    
                end
            end
         

        end

    end 
    

end    


function spawnZombie()
    local zombie={}
    zombie.x=math.random(5,coreWidth)
    zombie.y=math.random(5,coreHeight)
    zombie.speed=100
    zombie.dead=false
    zombie.radius=30

    local side=math.random(1,4)
    if side==1 then 
        zombie.x=-30
        zombie.y=math.random(0,coreHeight+shiftdown)
    

    elseif side==2 then 
        zombie.x=coreWidth+30
        zombie.y=math.random(0,coreHeight+shiftdown)
    

    elseif side==3 then 
        zombie.y=-30
        zombie.x=math.random(0,coreWidth)
    

    elseif side==4 then 
        zombie.y=coreHeight+30
        zombie.x=math.random(0,coreWidth)
    end



    table.insert(zombies,zombie)
end

function spawnbomb()
    local bomb={}
    bomb.x=math.random(player.x-200,player.x+200)
    bomb.y=math.random(player.y-200,player.y+200)
    bomb.explode=false
    bomb.radius=20

    table.insert(bombs,bomb)
end 


function distancebetween(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2+(y2-y1)^2)
end  

function playerzombie(enemy)
    return math.atan2(player.y-enemy.y,player.x-enemy.x)
end   

function playerbomb(bomb)
    return math.atan2(player.y-bomb.y,player.x-bomb.x)
end  


function love.keypressed(key)
    if key=="p" and gamerun==2 then 
        gamerun=3
        maxtime=2
        health=5
        bombtime=20

        for i=#zombies,1,-1 do 
            local z=zombies[i]
            table.remove(zombies,i)
        end
    end

    if key=="p" and gamerun==4 then 
        gamerun=0
        bombtime=30
        kills=0
        timer=0
        maxtime=2
        health=5

        for i=#zombies,1,-1 do 
            local z=zombies[i]
            table.remove(zombies,i)
        end
    end

    if key=="p" and gamerun==5 then 
        gamerun=0
        bombtime=20
        kills=0
        timer=0
        maxtime=2
        health=5

        for i=#zombies,1,-1 do 
            local z=zombies[i]
            table.remove(zombies,i)
        end
    end
end