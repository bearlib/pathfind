unit uInterface;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses uPathfinder;

type
	TPFAlgorithm = (
  	Dijkstra = 0,
    AStar = 1);

  TRecalcMode = (
    DontCheck = 0,
    CheckOnly = 1,
    CheckAndRecalculate = 2
  );
//	TPFCallback = function(fromx, fromy, tox, toy: integer; opaque: pointer): Boolean;cdecl;
	TPathfinderHandle = Pointer;
	TPathHandle = Pointer;
const
  PATH_NOT_FOUND = TPathHandle(0);

function pf_create(map_id, layer: Integer; algorithm: TPFAlgorithm; diagonal_cost: Single): TPathfinderHandle;cdecl;
function pf_create_cb(SizeX, SizeY: Integer; algorithm: TPFAlgorithm; diagonal_cost: Single; opaque: pointer; callback: TPFCallback): TPathfinderHandle;cdecl;
procedure pf_delete(Pathfinder: TPathfinderHandle);cdecl;
procedure pf_set_opaque(Pathfinder: TPathfinderHandle; opaque: pointer);cdecl;

function pf_calculate_path(Pathfinder: TPathfinderHandle; fromx, fromy, tox, toy: Integer): TPathHandle;cdecl;
procedure pf_path_origin(Path: TPathHandle; out fromx: Integer; out fromy: Integer);cdecl;
procedure pf_path_destination(Path: TPathHandle; out tox: Integer; out toy: Integer);cdecl;
function pf_path_empty(Path: TPathHandle): Boolean;cdecl;
function pf_path_length(Path: TPathHandle): Integer;cdecl;
procedure pf_path_revert(Path: TPathHandle);cdecl;
function pf_path_distance(Path: TPathHandle): Single;cdecl;
procedure pf_path_get(Path: TPathHandle; index: integer; out x: integer; out y: integer);cdecl;
function pf_path_walk(Path: TPathHandle; out x: integer; out y: integer; RecalcMode: TRecalcMode): Boolean;cdecl;
procedure pf_path_delete(Path: TPathHandle);cdecl;
function pf_calculate_path_gc(Pathfinder: TPathfinderHandle; key: pointer; fromx, fromy, tox, toy: Integer): TPathHandle;cdecl;

function pf_dijkstra_distance(Pathfinder: TPathfinderHandle; x: integer; y: integer): Single;cdecl;
function pf_dijkstra_length(Pathfinder: TPathfinderHandle; x: integer; y: integer): Integer;cdecl;
procedure pf_dijkstra_calculate(Pathfinder: TPathfinderHandle; tox, toy: Integer);cdecl;
function pf_dijkstra_find_unreachable(Pathfinder: TPathfinderHandle; out x: integer; out y: integer): Boolean;cdecl;

implementation

uses BearLibMap, uDijkstra, uAStar;

function typ(algo: TPFAlgorithm): TPathfinderClass;
begin
  case algo of
    Dijkstra: Result := TDijkstra;
    AStar: Result := TAStar;
    else
      Result := TAStar;
  end;
end;

function pf_create(map_id, layer: Integer; algorithm: TPFAlgorithm; diagonal_cost: Single): TPathfinderHandle;cdecl;
var
  it: TPathfinder;
begin
  it := typ(algorithm).create(map_width(map_id), map_height(map_id), diagonal_cost);
  it.InitForMap(map_id, layer);
  Result := TPathfinderHandle(it)
end;

function pf_create_cb(SizeX, SizeY: Integer; algorithm: TPFAlgorithm; diagonal_cost: Single; opaque: pointer; callback: TPFCallback): TPathfinderHandle;cdecl;
var
  it: TPathfinder;
begin
  it := typ(algorithm).create(SizeX, SizeY, diagonal_cost);
  it.InitForCallback(opaque, callback);
  Result := TPathfinderHandle(it)
end;


procedure pf_delete(Pathfinder: TPathfinderHandle);cdecl;
begin
  TPathfinder(Pathfinder).Free
end;

procedure pf_set_opaque(Pathfinder: TPathfinderHandle; opaque: pointer);cdecl;
begin
  TPathfinder(Pathfinder).Opaque := opaque
end;

function pf_calculate_path(Pathfinder: TPathfinderHandle; fromx, fromy, tox, toy: Integer): TPathHandle;cdecl;
var
  p: TPath;
begin
  with TPathfinder(Pathfinder) do
  begin
    p := NewPath;
    if Calculate(fromx, fromy, tox, toy, p) then
      Result := TPathHandle(p)
    else
      Result := PATH_NOT_FOUND;
  end;
end;

procedure pf_path_origin(Path: TPathHandle; out fromx: Integer; out fromy: Integer);cdecl;
begin
  with TPath(Path) do
  begin
    fromx := Data[length(Data)-1].x;
    fromy := Data[length(Data)-1].y;
  end;
end;

procedure pf_path_destination(Path: TPathHandle; out tox: Integer; out toy: Integer);cdecl;
begin
  with TPath(Path) do
  begin
    tox := Data[0].x;
    toy := Data[0].y;
  end;
end;

function pf_path_empty(Path: TPathHandle): Boolean;cdecl;
begin
  Result := TPath(Path).Empty;
end;

function pf_path_length(Path: TPathHandle): Integer;cdecl;
begin
  Result := length(TPath(Path).Data)-1;
end;

function pf_path_distance(Path: TPathHandle): Single;cdecl;
begin
  with TPath(Path) do
    Result := Data[high(Data)].distance;
end;

procedure pf_path_revert(Path: TPathHandle);cdecl;
begin
  TPath(Path).Revert;
end;

procedure pf_path_get(Path: TPathHandle; index: integer; out x: integer; out y: integer);cdecl;
begin
  with TPath(Path) do
  begin
    x := Data[length(Data)-2-index].x;
    y := Data[length(Data)-2-index].y;
  end;
end;

function pf_path_walk(Path: TPathHandle; out x: integer; out y: integer; RecalcMode: TRecalcMode): Boolean;cdecl;
begin
  Result := TPath(Path).Walk(x, y, RecalcMode > DontCheck);
  if not Result and (RecalcMode = CheckAndRecalculate) then
  begin
    Result := TPath(Path).Recalculate;
    if result then TPath(Path).Walk(x, y, False);
  end;
end;

procedure pf_path_delete(Path: TPathHandle);cdecl;
begin
  TPath(Path).Free;
end;

function pf_calculate_path_gc(Pathfinder: TPathfinderHandle; key: pointer; fromx, fromy, tox, toy: Integer): TPathHandle;cdecl;
var
  p: TPath;
begin
  with TPathfinder(Pathfinder) do
  begin
    p := GCPath(key);
    if Calculate(fromx, fromy, tox, toy, p) then
      Result := TPathHandle(p)
    else
      Result := PATH_NOT_FOUND;
  end;
end;

function pf_dijkstra_distance(Pathfinder: TPathfinderHandle; x: integer; y: integer): Single;cdecl;
begin
  Result := TDijkstra(Pathfinder).WaveData[x, y].Distance-1;
end;

procedure pf_dijkstra_calculate(Pathfinder: TPathfinderHandle; tox, toy: Integer);cdecl;
begin
  TDijkstra(Pathfinder).CalcMap(tox, toy)
end;

function pf_dijkstra_length(Pathfinder: TPathfinderHandle; x: integer; y: integer): Integer;cdecl;
begin
  Result := TDijkstra(Pathfinder).WaveData[x, y].Length-1;
end;

function pf_dijkstra_find_unreachable(Pathfinder: TPathfinderHandle; out x: integer; out y: integer): Boolean;cdecl;
begin
  Result := TDijkstra(Pathfinder).FindUnreachable(x, y);
end;


end.

