json = require("json")

shapes = {
    {{1, 1, 1, 1}},
    {{1, 1}, {1, 1}},
    {{1, 1, 0}, {0, 1, 1}},
    {{0, 1, 1}, {1, 1, 0}},
    {{1, 1, 1}},
    {{1, 1}, {0, 1}, {0, 1}},
    {{1, 1}, {1, 0}, {1, 0}},
}

sounds = {
    gameOver = love.audio.newSource("game_over.wav", "static"), 
    removeLines = love.audio.newSource("remove_lines.wav", "static"),
}

function generateRandomPiece()
    shape = shapes[math.random(#shapes)]
    randomX = math.random(1, 10 - #shape[1] + 1)
    return {shape=shapes[math.random(#shapes)], x=randomX, y=1}
end

function love.load()
    love.window.setTitle("Tetris")
    love.window.setMode(300, 600)
    
    if love.filesystem.getInfo("savegame.txt") then
        restoreGame()
    else
        initializeGrid()
        currentPiece = generateRandomPiece()
    end
    dropTimer = 0
end

function initializeGrid()
    grid = {}
    for y = 1, 20 do
        grid[y] = {}
        for x = 1, 10 do
            grid[y][x] = 0
        end
    end
end

function love.update(dt)
    dropTimer = dropTimer + dt

    if removingLines then
        removeAnimationTimer = removeAnimationTimer - dt
        if removeAnimationTimer <= 0 then
            removeLines()
            removingLines = false
        end
        return
    end

    if dropTimer >= 0.5 then
        currentPiece.y = currentPiece.y + 1
        dropTimer = 0
    end

    if checkColision() then
        if currentPiece.y == 1 then
            love.audio.play(sounds.gameOver)
            love.filesystem.remove("savegame.txt")
            love.load()
        else
            lockPiece()
            removeFilledLines()
            currentPiece = generateRandomPiece()
        end
    end
end

function removeLines()
    for _, y in ipairs(linesToRemove) do
        for i = y, 2, -1 do
            for x = 1, 10 do
                grid[i][x] = grid[i - 1][x]
            end
        end
        for x = 1, 10 do
            grid[1][x] = 0
        end
    end
end

function lockPiece()
    for i, row in ipairs(currentPiece.shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                grid[currentPiece.y + i - 1][currentPiece.x + j - 1] = 1
            end
        end
    end
end

function rotatePiece()
    local newShape = {}
    for i = 1, #currentPiece.shape[1] do
        newShape[i] = {}
        for j = 1, #currentPiece.shape do
            newShape[i][j] = currentPiece.shape[#currentPiece.shape - j + 1][i]
        end
    end

    if canRotate(newShape) then
        currentPiece.shape = newShape
    end
end

function canRotate(newShape) 
    for i, row in ipairs(newShape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                if currentPiece.x + j - 1 < 1 or currentPiece.x + j - 1 > 10 or currentPiece.y + i - 1 > 20 or grid[currentPiece.y + i - 1][currentPiece.x + j - 1] == 1 then
                    return false
                end
            end
        end
    end
    return true
end


function removeFilledLines()
    linesToRemove = {}
    for y = 1, 20 do
        local filled = true
        for x = 1, 10 do
            if grid[y][x] == 0 then
                filled = false
            end
        end
        if filled then
            table.insert(linesToRemove, y)
        end
    end

    if #linesToRemove > 0 then
        love.audio.play(sounds.removeLines)
        removeAnimationTimer = 0.5
        removingLines = true
    end
end


function checkColision()
    for i, row in ipairs(currentPiece.shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                if currentPiece.y + i - 1 == 20 or grid[currentPiece.y + i][currentPiece.x + j - 1] == 1 then
                    return true
                end
            end
        end
    end
    return false
end

function love.draw()
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x] == 1 then
                local alpha = 1.0 

                if removingLines then
                    for _, line in ipairs(linesToRemove) do
                        if y == line then
                            alpha = math.abs(math.sin(love.timer.getTime() * 10))
                        end
                    end
                end

                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.rectangle("fill", (x - 1) * 30, (y - 1) * 30, 28, 28)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)

    for i, row in ipairs(currentPiece.shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                love.graphics.rectangle("fill", (currentPiece.x + j - 2) * 30, (currentPiece.y + i - 2) * 30, 28, 28)
            end
        end
    end
end

function love.keypressed(key)
    if key == "left" then
        if canMoveLeft() then
            currentPiece.x = currentPiece.x - 1
        end
    elseif key == "right" then
        if canMoveRight() then
            currentPiece.x = currentPiece.x + 1
        end
    elseif key == "down" then
        currentPiece.y = currentPiece.y + 1
    elseif key == "up" then
        rotatePiece()
    end
end

function canMoveLeft()
    for i, row in ipairs(currentPiece.shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                if currentPiece.x + j - 2 < 1 or grid[currentPiece.y + i - 1][currentPiece.x + j - 2] == 1 then
                    return false
                end
            end
        end
    end
    return true
end

function canMoveRight()
    for i, row in ipairs(currentPiece.shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                if currentPiece.x + j > 10 or grid[currentPiece.y + i - 1][currentPiece.x + j] == 1 then
                    return false
                end
            end
        end
    end
    return true
end

function saveGame()
    local data = {
        grid = grid,
        currentPiece = currentPiece
    }
    
    local file = love.filesystem.newFile("savegame.txt")
    local jsonData = json.encode(data)
    love.filesystem.write("savegame.txt", jsonData)
end

function restoreGame()
    local data = json.decode(love.filesystem.read("savegame.txt"))
    grid = data.grid
    currentPiece = data.currentPiece
end

function love.quit()
    saveGame()
end