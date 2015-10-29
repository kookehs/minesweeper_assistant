from random import randint

filename = ""
algorithm = ""
mapHeight = 0
mapWidth = 0
selected = (0, 0)
grid = []

def display():
    for j in range(mapHeight):
        row = ""

        for i in range(mapWidth):
            row += str(grid[j][i]) + " "

        print(row + "\n")

def saveCommands(commands):
    file = open('commands.txt', 'a')

    for item in commands:
        file.write(item + "\n")

    file.close()

def graph(x, y):
    adj = []

    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue

            newX = x + dx
            newY = y + dy

            if  newX >= 0 and newY >= 0 and newX <= mapWidth - 1 and newY <= mapHeight - 1:
                adj.append((newX, newY))

    return adj

def countAdj(x, y):
    adj = {}

    for i in range(1, 9):
        adj[str(i)] = []

    adj["@"] = []
    adj["?"] = []
    adj["B"] = []
    adj["E"] = []
    adj["F"] = []
    adj["W"] = []

    for adjTile in graph(x, y):
        nextTile = grid[adjTile[1]][adjTile[0]]
        adj[nextTile].append(adjTile)

    return adj

def obviousBomb():
    prev = {}
    prev[selected] = None
    visited = [selected]
    queue = [selected]
    flagSpots = []

    while queue:
        node = queue.pop(0)

        neighbors = countAdj(node[0], node[1])

        for neighboringKey in neighbors.keys():
            for tile in neighbors[neighboringKey]:
                if tile not in prev:
                    prev[tile] = node
                    queue.append(tile)

        if not grid[node[1]][node[0]].isdigit():
            continue

        currentTile = int(grid[node[1]][node[0]])
        potentialTiles = []
        adj = countAdj(node[0], node[1])
        occupiedTiles = len(adj["W"]) + len(adj["F"]) + len(adj["?"])

        if currentTile == occupiedTiles:
            for tile in adj["W"]:
                if str(tile) not in visited:
                    visited.append(str(tile))
                    flagSpots.append(str(tile) + "\t'R'\t[" + str(len(adj["W"])) + "]")

    saveCommands(flagSpots)

    return len(flagSpots)

def obviousSafe():
    prev = {}
    prev[selected] = None
    visited = [selected]
    queue = [selected]
    safeSpots = []

    while queue:
        node = queue.pop(0)

        neighbors = countAdj(node[0], node[1])

        for neighboringKey in neighbors.keys():
            for tile in neighbors[neighboringKey]:
                if tile not in prev:
                    prev[tile] = node
                    queue.append(tile)

        if not grid[node[1]][node[0]].isdigit():
            continue

        currentTile = int(grid[node[1]][node[0]])
        adj = countAdj(node[0], node[1])
        occupiedTiles = len(adj["F"]) + len(adj["?"])

        if currentTile == occupiedTiles and len(adj["W"]) > 0:
            if str(node) not in visited:
                visited.append(str(node))
                safeSpots.append(str(node) + "\t'M'\t[" + str(len(adj["F"])) + "]")

    saveCommands(safeSpots)

    return len(safeSpots)

def getWalls():
    wallSpots = []

    for j in range(mapHeight):
        for i in range(mapWidth):
            if grid[j][i] == "W":
                wallSpots.append("(" + str(i) + ", " + str(j) + ")\t'L'\t[0]")

    file = open('commands.txt', 'w')
    file.write(wallSpots[randint(0, len(wallSpots) - 1)])
    file.close()

def probability():
    prev = {}
    prev[selected] = None
    queue = [selected]
    wallSpots = {}

    while queue:
        node = queue.pop(0)

        neighbors = countAdj(node[0], node[1])

        for neighboringKey in neighbors.keys():
            for tile in neighbors[neighboringKey]:
                if tile not in prev:
                    prev[tile] = node
                    queue.append(tile)

        if not grid[node[1]][node[0]].isdigit():
            continue

        currentTile = int(grid[node[1]][node[0]])
        adj = countAdj(node[0], node[1])

        for tile in adj["W"]:
            if tile not in wallSpots:
                wallSpots[tile] = 1 * currentTile - len(adj["F"])
            else:
                wallSpots[tile] += 1 * currentTile - len(adj["F"])

    if wallSpots:
        print(wallSpots)
        minValue = sorted(wallSpots.values())[0]

        for key in wallSpots.keys():
            if wallSpots[key] == minValue:
                file = open('commands.txt', 'w')
                file.write(str(key) + "\t'L'\t[0]")
                file.close()
                break
    else:
        getWalls()

def search():
    file = open('commands.txt', 'w')
    file.close()

    bomb = 0
    safe = 0

    if algorithm == "obviousBomb":
        bomb = obviousBomb()
    elif algorithm == "obviousSafe":
        safe = obviousSafe()
    elif algorithm == "obviousBoth":
        bomb = obviousBomb()
        safe = obviousSafe()

    if bomb + safe == 0:
        # getWalls()
        probability()

def load():
    file = open(filename, "r")
    global selected
    selected = (int(file.readline()) - 1, int(file.readline()) - 1)
    global mapHeight
    mapHeight = int(file.readline())
    global mapWidth
    mapWidth = int(file.readline())
    grid[:] = []

    for j in range(mapHeight):
        grid.append([])

        for i in range(mapWidth):
            grid[j].append("Z")

    for j, line in enumerate(file.readlines()):
        x = 0

        for i, char in enumerate(line):
            if char == "\n" or char == "\r" or char == " ":
                continue
            elif char == "@":
                grid[j][x] = "W"
            else:
                grid[j][x] = char

            x += 1

    search()

if __name__ ==  '__main__':
    import sys
    _, filename, algorithm = sys.argv
    load()
