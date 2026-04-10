use context dcic2024
#|            
   
██╗  ██╗██╗████████╗ ██████╗██╗  ██╗███████╗███╗   ██╗
██║ ██╔╝██║╚══██╔══╝██╔════╝██║  ██║██╔════╝████╗  ██║
█████╔╝ ██║   ██║   ██║     ███████║█████╗  ██╔██╗ ██║
██╔═██╗ ██║   ██║   ██║     ██╔══██║██╔══╝  ██║╚██╗██║
██║  ██╗██║   ██║   ╚██████╗██║  ██║███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝

 ██████╗██████╗  █████╗ ███████╗███████╗
██╔════╝██╔══██╗██╔══██╗╚══███╔╝██╔════╝
██║     ██████╔╝███████║  ███╔╝ █████╗
██║     ██╔══██╗██╔══██║ ███╔╝  ██╔══╝
╚██████╗██║  ██║██║  ██║███████╗███████╗
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝
  
   (Spring 2026)
|#


# IGNORE THIS - this imports support code
include shared-gdrive("project2-support-fall24.arr", "1BBNcHnYHMF72ZxNHsfZU7E6uLpsdZEla")
include reactors
include gdrive-sheets
include data-source

#######################################################################
# -------------------- External Data & Constants ---------------------#
#######################################################################
   
ssid = "1VjBrj9KidMnkZxnw4YFNGxC5MCLkFNRrqIsZr7dfMZ8"
 
# load maze from spreadsheet
maze-grid  = load-maze(ssid) 
   
# load item positions from spreadsheet into Table form
item-table = load-items(ssid) 


# Loads all images for the game
base-url = "https://drive.google.com/thumbnail?id="
boy-img = image-url(base-url + "1aAHj21rZLFJ_T0xAnE6hNMQFWAWhtO13")
cookie-img = image-url(base-url + "11y05YkAUPSujhGwCUaslc5CHeiKA7mlW")
hat-img = image-url(base-url + "19067hbaHuikEbcU7T4t1ZCyabX1SZGBJ")
card-img = image-url(base-url + "1JkF7oEpCSgaG9_Cxp5pF132DWhIsDZUq")
sponge-img = image-url(base-url + "1uUHcUw5WD-agy3mIqyo_l50GbxKJi7WK")
meal-img = image-url(base-url + "1RDYMwPjBdOkcyyTozKPm6x55T-JIUUdt")
floor-img = image-url(base-url + "1aE2tShwsae2f1CaaDLHDGf5s6xepHEor")
wall-img = image-url(base-url + "1YGsNRuxUuk7ICXBxR_SmUyOndEu01oB6")


#DATATYPES
data Coord:
  | coord(x :: Number, y :: Number)
end

data Widget:
  | cookie(pos :: Coord)
  | sponge(pos :: Coord)
  | meal(pos :: Coord)
  | hat(pos:: Coord)
  | noWidget
end

data GameState:
  | game(char-pos :: Coord, stamina-level :: Number, widgets-in-game :: List<Widget>)
end
    

#DRAW BACKGROUND
fun draw-row(mazeRow :: List<String>) -> Image:
  doc: "takes in a list in the maze grid representing a row and outputs an image of that row. assumes list only contains x's and o's"
  cases(List) mazeRow:
    | empty => square(0, "solid", "black")
    | link(f, r) => 
      if f == "x":
        beside-align("middle", square(30, "solid", "brown"), draw-row(r))
      else:
        beside-align("middle", square(30, "solid", "white"), draw-row(r))
      end
  end
end
    
fun draw-background(grid :: List<List<String>>) -> Image:
  doc: "inputs maze grid and outputs corresponding maze image"
  cases(List) grid:
    | empty => square(0, "solid", "black")
    | link(f, r) => above-align("middle", draw-row(f), draw-background(r))
  end 
end


#WIDGET SETUP
fun coord-to-pixel(tile-num :: Number) -> Number:
	doc: "takes in a tile number and outputs the corresponding coordinate in pixels by multiplying by 30 and adding 15 to center the object in the desired tile. works in one dimension at a time."
  (tile-num * 30) + 15
where: 
  coord-to-pixel(1) is 45
  coord-to-pixel(10) is 315
end

fun get-widget-list(widget-table :: Table) -> List<Widget>:
	doc: "Takes in a table with widget information and outputs a list of corresponding widget types"
	w-table = build-column(widget-table, "widget", lam(r): row-to-widget(r) end )
	w-table.get-column("widget")
where:
  get-widget-list(table: name :: String, x :: Number, y :: Number, url :: String
    row: "Cookie", 21, 1, "cookie.png"
    row: "Cookie", 19, 5, "cookie.png"
    row: "Cookie", 27, 17, "cookie.png"
    end) is [list: cookie(coord(21, 1)), cookie(coord(19, 5)), cookie(coord(27, 17))]
  get-widget-list(table: name :: String, x :: Number, y :: Number, url :: String
    row: "Cookie", 12, 5, "cookie.png"
    row: "Meal", 4, 2, "cookie.png"
    row: "Hat", 34, 14, "cookie.png"
    end) is [list: cookie(coord(12, 5)), meal(coord(4, 2)), hat(coord(34, 14))]
end

fun row-to-widget(row :: Row) -> Widget:
	doc: "converts a row of widget information into a widget type"
  if row["name"] == "Cookie":
		cookie(coord(row["x"], row["y"]))
  else if row["name"] == "Sponge":
		sponge(coord(row["x"], row["y"]))
  else if row["name"] == "Meal":
		meal(coord(row["x"], row["y"]))
	else:
		hat(coord(row["x"], row["y"]))
	end
where:
  row-to-widget(item-table.row-n(0)) is cookie(coord(7, 1))
  row-to-widget(item-table.row-n(11)) is sponge(coord(3, 1))
end
	

#INITIAL CONSTANTS
empty-background = rectangle(length(get(maze-grid, 0)) * 30,  length(maze-grid) * 30, "solid", "transparent") 
BACKGROUND = draw-background(maze-grid)

end-background = rectangle(1080, 570, "solid", "transparent")
lose-text = text-font("GAME OVER", 150, "red", "Typewriter", "decorative", "normal", "bold", false)
LOSE-ENDSCREEN = overlay-align("center", "center", lose-text, end-background)
win-text = text-font("YOU WIN!", 150, "green", "Typewriter", "decorative", "normal", "bold", false)
WIN-ENDSCREEN = overlay-align("center", "center", win-text, end-background)

use-arrows = true

init-widgets = get-widget-list(item-table)
init-state = game(coord(1, 1), 100, init-widgets)


#DRAWING GAME PIECES
fun draw-all-widgets(widget-list :: List<Widget>) -> Image:
  doc: "takes in list of widgets in play and draws all of those widgets on a transparent background"
  cases(List) widget-list:
    |empty => empty-background
    |link(f, r) => place-image(get-widget-img(f), coord-to-pixel(f.pos.x), coord-to-pixel(f.pos.y), draw-all-widgets(r))
  end
end

fun get-widget-img(wgt:: Widget) -> Image:
  doc: "takes in a widget type and draws that widget's image"
  cases(Widget) wgt:
    | cookie(pos) =>  cookie-img
    | sponge(pos) =>  sponge-img
    | meal(pos) =>   meal-img
    | hat(pos) =>   hat-img
  end
end

fun draw-char(char-pos :: Coord) -> Image:
  doc: "takes in character coordinates and draws the character at the corresponding pixel points"
  place-image(boy-img, coord-to-pixel(char-pos.x), coord-to-pixel(char-pos.y), empty-background)
end


#REACTOR FUNCTIONS
fun draw-game(state :: GameState) -> Image:
  doc: "draws updated frame where the character/image is on background"
  widgets-and-character = overlay(draw-char(state.char-pos), draw-all-widgets(state.widgets-in-game))
  maze-board = overlay-xy(widgets-and-character, 0, 0, BACKGROUND)
  maze-board-bar = beside-align("bottom", maze-board, draw-stamina-bar(state))
  if game-ends(state):
    if state.stamina-level <= 0:
      overlay-align("center", "center", LOSE-ENDSCREEN, maze-board-bar)
    else:
      overlay-align("center", "center", WIN-ENDSCREEN, maze-board-bar)
    end
  else:
    maze-board-bar
  end
end

fun key-pressed(state :: GameState, key :: String) -> GameState:
  doc: "defines what key will allow the boy to move"
  new-coord = get-new-coord(state.char-pos, key, use-arrows)
  if new-coord == state.char-pos:
    state
  else if not(is-wall(new-coord)):
    hit-widget = get-hit-widget(new-coord, state)
    new-widget-list = get-new-widget-list(hit-widget, state)
    new-stamina-level = get-new-stamina-level(hit-widget, state)
    new-game-state = game(new-coord, new-stamina-level, new-widget-list)
    new-game-state
  else:
    state
  end
where: 
  key-pressed(init-state, "p") is init-state #p not a movement key
  key-pressed(init-state, "w") is init-state #hitting a wall
  key-pressed(init-state, "d") is game(coord(2, 1), 96, init-state.widgets-in-game) #legal move right from init-state (no widget hit!)
  key-pressed(game(coord(2,1), 96, init-state.widgets-in-game), "d") is game(coord(3,1), 35, remove(init-state.widgets-in-game, sponge(coord(3,1)))) #legal move right onto sponge
  key-pressed(game(coord(4,1), 96, init-state.widgets-in-game), "s") is game(coord(4,2), 100, remove(init-state.widgets-in-game, meal(coord(4,2)))) #legal move down onto meal
  key-pressed(game(coord(8,1), 96, init-state.widgets-in-game), "a") is game(coord(7,1), 100, remove(init-state.widgets-in-game, cookie(coord(7,1)))) #legal move left onto cookie
  key-pressed(game(coord(33,14), 2, init-state.widgets-in-game), "d") is game(coord(34,14), 0, remove(init-state.widgets-in-game, hat(coord(34,14)))) #legal move right onto hat (still gets there and wins even tho stamina is out!)
end


fun game-ends(state :: GameState) -> Boolean:
  #no hats left in game
  (length(filter(lam(f): is-hat(f) end, state.widgets-in-game)) == 0) or (state.stamina-level <= 0)
where: game-ends(init-state) is false
  game-ends(game(coord(8,8), 0, init-state.widgets-in-game)) is true
end
  


#CHARACTER MOVEMENT FUNCTIONS
fun is-wall(tile-coord :: Coord) -> Boolean:
  doc: "takes in a tile's coordinates and returns whether it is a wall"
  get(get(maze-grid, tile-coord.y), tile-coord.x) == "x"
where: is-wall(coord(2, 1)) is false
  is-wall(coord(0,0)) is true
end

fun get-new-coord(char-pos :: Coord, key :: String, arrows-in-use) -> Coord:
  doc: "takes in a character position and outputs where it would move depending on the key that was pressed"
  if (key == "d") or (arrows-in-use and (key == "right")):
    coord(char-pos.x + 1, char-pos.y)
  else if (key == "a") or (arrows-in-use and (key == "left")):
    coord(char-pos.x - 1, char-pos.y)
  else if (key == "s") or (arrows-in-use and (key == "down")):
    coord(char-pos.x, char-pos.y + 1)
  else if (key == "w") or (arrows-in-use and (key == "up")):
    coord(char-pos.x, char-pos.y - 1)
  else: 
    char-pos
  end
where: get-new-coord(coord(5,7), "w", true) is coord(5, 6)
  get-new-coord(coord(2,2), "right", false) is coord(2,2)
end
  
  
#INTERACTING WITH WIDGETS
fun get-new-widget-list(hit-widget :: Widget, state :: GameState) -> List<Widget>:
  doc: "takes in a widget and a current gamestate and returns a new list of widgets in play that matches the gamestate but the hit widget is removed"
  remove(state.widgets-in-game, hit-widget)
where: get-new-widget-list(cookie(coord(9, 1)), game(coord(1,1), 10, [list: hat(coord(2,2)), cookie(coord(9,1))])) is [list: hat(coord(2,2))]
  get-new-widget-list(noWidget, init-state) is init-state.widgets-in-game
end


fun get-hit-widget(tile-coord :: Coord, state :: GameState) -> Widget:
  doc:"takes in a tile's coordinates and returns the widget that is currently there OR noWidget if there is no widget"
  widgets-at-coord = filter(lam(f): (f.pos.x == tile-coord.x) and (f.pos.y == tile-coord.y) end, state.widgets-in-game)
  if length(widgets-at-coord) > 0:
    get(widgets-at-coord, 0)
  else:
    noWidget
  end
where: get-hit-widget(coord(7,1), init-state) is cookie(coord(7,1))
  get-hit-widget(coord(8,1), init-state) is noWidget
end

#STAMINA FUNCTIONS
fun get-new-stamina-level(hit-widget :: Widget, state :: GameState) -> Number:
  doc: "takes in a widget and gamestate and outputs the new stamina level (-4 for tile move and then depends on widget effect)."
  cases(Widget) hit-widget:
    | noWidget => 
      if (state.stamina-level - 4) >= 0: state.stamina-level - 4
      else: 0
      end
    | cookie(pos) =>  
      if (state.stamina-level + 45) <= 100: state.stamina-level + 45
      else: 100
      end
    | sponge(pos) =>  35
    | meal(pos) =>   100
    | hat(pos) =>  
      if (state.stamina-level - 4) >= 0: state.stamina-level - 4
      else: 0
      end
  end
where: get-new-stamina-level(noWidget, game(coord(1,1), 15, [list: hat(coord(10,13))])) is 11
  get-new-stamina-level(cookie(coord(1,1)), game(coord(1,0), 90, [list: hat(coord(10,13))])) is 100
  
end

fun draw-stamina-bar(state :: GameState) -> Image:
  white-rect = rectangle(30, 570, "solid", "white")
  if state.stamina-level <= 25:
    stamina-bar = rectangle(30, state.stamina-level * 5.7, "solid", "red")
    overlay-align("left", "bottom", stamina-bar, white-rect)
  else:
    stamina-bar = rectangle(30, state.stamina-level * 5.7, "solid", "yellow")
    overlay-align("left", "bottom", stamina-bar, white-rect)
  end
end

  
#REACTOR  
my-reactor = reactor:
  init: init-state,
  to-draw: draw-game,
  on-key: key-pressed,
  title: "Kitchen Craze!",
  stop-when: game-ends
end

interact(my-reactor)


#| PHASE 3
Task 1
Guideline 1: Include an option to adjust the game speed
	This accessibility feature would not be needed for a game like a crossword puzzle. The given game features are constant, and the user is completely in control of how quickly they complete the puzzle. In other words, everything that changes in the game is controlled by the user. On the other hand, in a puzzle game where the player needs to type a word in under a given time limit, this option would be a good idea to implement. For someone with limited mobility, a slower version of the game would be just as testing as the hardcore level for someone who could type more quickly.

Guideline 2: Ensure no essential information is conveyed by a fixed color alone.
	This accessibility feature would not be needed in a game that already conveys essential information in a variety of ways. For example, in Candy Crush, both the color and the shape of the candy differ so that even a person who might have trouble telling green and red apart would be able to correctly match the candies based on the difference of shape. The creators of Among Us, on the other hand, might incorporate an option to help colorblind players tell the difference between the other player icons. One way they have already done this is by having player names, so that someone can identify them by name as well as by color. But when killings happen swiftly, it is certainly an advantage to be able to identify someone merely by color... perhaps they could give the players distinctive hats in servers where there are colorblind players... or perhaps the names are good enough.
 
Task 2: 
   use-arrows is defined on line 151
|#
