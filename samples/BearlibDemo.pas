program BearlibPFDemo;

uses
  BeaRLibTerminal,
  SysUtils,
  Classes,
  Math,
  BearLibMap,
  BearLibPF in '..\include\bearlibpf.pas',
  bearlibMG;

// Map layers:
const
  kOpacityLayer = 0;
  kTileLayer = 1;
  kPathLayer = 2;

  ALGO_NAMES: array[TPFAlgorithm] of string = ('Dijkstra', 'AStar');

var
  map_id: integer = -1;
  mouse, player: TPoint;
  pathdata: array of TPoint;
  pathdistance: Single;
  pathdiags: single = 1.4;
  pathfinder: TPathfinderHandle;
  path: TPathHandle;
  PathMode: TPFAlgorithm;


procedure CalcPath;
var
  i: integer;
begin
  path := pf_calculate_path_gc(pathfinder, nil, player.x, player.y, mouse.x, mouse.y);
  if path = PATH_NOT_FOUND then
  begin
    SetLength(pathdata, 0);
    pathdistance := 0;
    exit;
  end;
  pathdistance := pf_path_distance(path);
  SetLength(pathdata, pf_path_length(path));
  for i := 0 to high(pathdata) do
    pf_path_get(path, i, pathdata[i].x, pathdata[i].y);
end;

procedure UpdatePathfinder;
begin
  if PathMode = Dijkstra then
    pf_dijkstra_calculate(pathfinder, mouse.x, mouse.y);
  CalcPath;
end;



procedure DeleteMap;
begin
  map_free(map_id);
end;

function TileToChar(tile: TCellType): Integer;
begin
  case tile of
    TILE_CAVE_WALL: Result := ord('#');
    TILE_GROUND: Result := ord('.');
    TILE_WATER: Result := ord('~');
    TILE_TREE: Result := ord('T');
    TILE_MOUNTAIN: Result := ord('^');
    TILE_ROAD: Result := ord('%');
    TILE_HOUSE_WALL: Result := $2588;
    TILE_HOUSE_FLOOR: Result := ord('*');
    TILE_GRASS: Result := ord(',');
    TILE_EMPTY: Result := ord(' ');
    TILE_CORRIDOR: Result := ord('.');
    TILE_SMALLROOM: Result := ord(',');
    TILE_BIGROOM: Result := ord('*');
    TILE_ROOMWALL: Result := $2588;
    TILE_DOOR: Result := ord('+');
    else Result := ord('?')
  end;
end;

function TileToColor(tile: TCellType): string;
begin
  case tile of
    TILE_CAVE_WALL: Result := 'dark yellow';
    TILE_GROUND: Result := 'yellow';
    TILE_WATER: Result := 'blue';
    TILE_TREE: Result := 'green';
    TILE_MOUNTAIN: Result := 'yellow';
    TILE_ROAD: Result := 'yellow';
    TILE_HOUSE_WALL: Result := 'gray';
    TILE_HOUSE_FLOOR: Result := 'gray';
    TILE_GRASS: Result := 'green';
    TILE_EMPTY: Result := 'gray';
    TILE_CORRIDOR: Result := 'gray';
    TILE_SMALLROOM: Result := 'light blue';
    TILE_BIGROOM: Result := 'gray';
    TILE_ROOMWALL: Result := 'dark yellow';
    TILE_DOOR: Result := 'yellow';
    else Result := 'gray'
  end;

end;

procedure SetTile(I,J: integer; tile: TCellType);
begin
  map_set(map_id,I, J,kTileLayer, ord(tile));
  case tile of
    TILE_CAVE_WALL,TILE_TREE,
    TILE_ROOMWALL, TILE_MOUNTAIN,TILE_HOUSE_WALL:
    begin
      map_set(map_id,I, J,kOpacityLayer, 1);
      map_set(map_id,I, J,kPathLayer, 0);
    end
    else
    begin
      if player.x < 0 then
      begin
        player.x := I;
        player.y := J;
      end;
      map_set(map_id,I, J,kOpacityLayer, 0);
      if (TileToChar(tile) = ord('~')) or (TileToChar(tile) = ord(',')) then
        map_set(map_id,I, J,kPathLayer, 2)
      else
        map_set(map_id,I, J,kPathLayer, 1);
    end;
  end;
end;



procedure GenerateMap(Width, Height: Integer; MapType: TMapGenerator);
var
  plx, ply, I, J, rx, ry, h, w: Integer;
  tile: TCellType;
begin
  player.x := -1;
  map_id := map_alloc(Width, Height, 'flag, integer, integer');

  mg_generate(map_id, kTileLayer, MapType, 0, nil, nil);

  for I := 0 to Width-1 do
    for J := 0 to Height-1 do
    begin
      tile := TCellType(map_get(map_id, I, J, kTileLayer));
      SetTile(I, J, tile);
    end;
  pathfinder := pf_create(map_id, kPathLayer, PathMode, pathdiags);

  UpdatePathfinder;
end;

procedure DrawSimple;
var
  x, y: integer;
  tile: TCellType;
begin
  for y := 0 to map_height(map_id) - 1 do
    for x := 0 to map_width(map_id) - 1 do
    begin
      tile := TCellType(map_get(map_id, x, y, kTileLayer));
      terminal_color(TileToColor(tile));
      terminal_put(x, y, TileToChar(tile));
    end;
end;

procedure DrawPath;
var
  x, y, i: integer;
  tile: TCellType;
begin
  terminal_bkcolor('red');
  for i := 0 to length(pathdata)-1 do
  begin
    pf_path_get(path, i, x, y);
    tile := TCellType(map_get(map_id, x, y, kTileLayer));
    terminal_color(TileToColor(tile));
    terminal_put(x, y, TileToChar(tile));
  end;
  terminal_bkcolor('black');
end;


procedure MovePlayer(dx, dy: integer);
var
  nx, ny: integer;
begin
  nx := player.x + dx;
  ny := player.y + dy;

  if not InRange(nx, 0, map_width(map_id) - 1) or not
    InRange(ny, 0, map_height(map_id) - 1) then // OOB
    exit;

  if map_get(map_id, nx, ny, kOpacityLayer) > 0 then // Wall
    exit;

  player.x := nx;
  player.y := ny;
end;

procedure ChangeTile(x,y: integer);
var
  tile: TCellType;
begin
  tile := TCellType(map_get(map_id, x, y, kTileLayer));
  if TileToChar(tile) = ord('.') then
    tile := TILE_WATER
  else if TileToChar(tile) = ord('~') then
    tile := TILE_CAVE_WALL
  else
    tile := TILE_GROUND;
  SetTile(x,y,tile);
end;

var
  key: integer;
  i: integer;
  gen_type: TMapGenerator = Low(TMapGenerator);
  quitting: boolean;
begin
  Randomize;

  terminal_open;
  terminal_set(Format('window: size=%dx%d', [80, 41]));
  terminal_set('title=Demo');
  terminal_set('font.name=media/UbuntuMono-R.ttf; font.size=12');
  terminal_set('mouse-cursor = true');
  terminal_set('filter=[keyboard, mouse]');


  gen_type := G_NICE_DUNGEON;
  GenerateMap(80,40,G_NICE_DUNGEON);

  while not quitting do
  begin
    terminal_clear;
    DrawSimple;
    terminal_color(color_from_name('white'));
    terminal_put(player.x, player.y, '@');
    DrawPath;


    terminal_color(color_from_name('white'));
    terminal_print(0, 0, '[color=green]map: '+GENERATOR_NAMES[ord(gen_type)]+'(F1 - change)');
    terminal_print(0, 1, '[color=red]pathfinder: '+ALGO_NAMES[PathMode]+' (F2 - change, F3 - diags)');
    terminal_print(40, 0, 'right click - change block');//left click - walk,
    terminal_print(47, 1, 'path length = '+IntToStr(length(pathdata))+', distance='+FloatToStr(pathdistance));
//    terminal_print(0, 40, 'F1: from file, F2: cycle generators, F3: G_NICE_DUNGEON, F4: tweak example');
    terminal_refresh;
    while terminal_has_input do
    begin
      key := terminal_read;
      case key of
        TK_CLOSE, TK_ESCAPE:
          begin
            quitting := true;
            break;
          end;
        TK_LEFT: MovePlayer(-1, 0);
        TK_UP: MovePlayer(0, -1);
        TK_RIGHT: MovePlayer(+1, 0);
        TK_DOWN: MovePlayer(0, +1);
        TK_KP_1: MovePlayer(-1, +1);
        TK_KP_2: MovePlayer(0, +1);
        TK_KP_3: MovePlayer(+1, +1);
        TK_KP_4: MovePlayer(-1, 0);
        TK_KP_6: MovePlayer(+1, 0);
        TK_KP_7: MovePlayer(-1, -1);
        TK_KP_8: MovePlayer(0, -1);
        TK_KP_9: MovePlayer(+1, -1);
        TK_MOUSE_MOVE:
          begin
            mouse.x := terminal_state(TK_MOUSE_X);
            mouse.y := terminal_state(TK_MOUSE_Y);
            CalcPath;
          end;
        TK_F1:
        begin
          DeleteMap;
          if gen_type = High(TMapGenerator) then
            gen_type := Low(TMapGenerator)
          else
            gen_type := TMapGenerator(ord(gen_type)+1);
          GenerateMap(80,40,gen_type);
        end;
        TK_F2:
        begin
          pf_delete(pathfinder);
          if PathMode = Dijkstra then
            PathMode := AStar
          else
            PathMode := Dijkstra;
          pathfinder := pf_create(map_id, kPathLayer, PathMode, pathdiags);
          UpdatePathfinder;
        end;
        TK_F3:
        begin
          pf_delete(pathfinder);
          if pathdiags = 0 then
            pathdiags := 1.4
          else
            pathdiags := 0;
          pathfinder := pf_create(map_id, kPathLayer, PathMode, pathdiags);
          UpdatePathfinder;
        end;
        TK_MOUSE_RIGHT:
        begin
          ChangeTile(mouse.x, mouse.y);
          UpdatePathfinder;
        end;
      end;
    end;
  end;
  terminal_close;
end.
