unit bearlibPF;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

const
  bearlibpfLIB = 'bearlibpf.dll';

type
	TPFAlgorithm = (
  	Dijkstra = 0,
    AStar = 1);
  TRecalcMode = (
    DontCheck = 0,
    CheckOnly = 1,
    CheckAndRecalculate = 2
  );
  TPFCallback = function(fromx, fromy, tox, toy: integer; opaque: pointer): Single;cdecl;
	TPathfinderHandle = Pointer;
	TPathHandle = Pointer;

const
  PATH_NOT_FOUND = TPathHandle(0);

function pf_create(map_id, layer: Integer; algorithm: TPFAlgorithm; diagonal_cost: Single): TPathfinderHandle;cdecl; external bearlibpfLIB;
function pf_create_cb(SizeX, SizeY: Integer; algorithm: TPFAlgorithm; diagonal_cost: Single; opaque: pointer; callback: TPFCallback): TPathfinderHandle;cdecl;external bearlibpfLIB;
procedure pf_delete(Pathfinder: TPathfinderHandle);cdecl;external bearlibpfLIB;
procedure pf_set_opaque(Pathfinder: TPathfinderHandle; opaque: pointer);cdecl;external bearlibpfLIB;
function pf_calculate_path(Pathfinder: TPathfinderHandle; fromx, fromy, tox, toy: Integer): TPathHandle;cdecl;external bearlibpfLIB;
function pf_calculate_path_gc(Pathfinder: TPathfinderHandle; key: pointer; fromx, fromy, tox, toy: Integer): TPathHandle;cdecl;external bearlibpfLIB;

procedure pf_path_origin(Path: TPathHandle; out fromx: Integer; out fromy: Integer);cdecl;external bearlibpfLIB;
procedure pf_path_destination(Path: TPathHandle; out tox: Integer; out toy: Integer);cdecl;external bearlibpfLIB;
function pf_path_empty(Path: TPathHandle): Boolean;cdecl;external bearlibpfLIB;
function pf_path_length(Path: TPathHandle): Integer;cdecl;external bearlibpfLIB;
procedure pf_path_revert(Path: TPathHandle);cdecl;external bearlibpfLIB;
function pf_path_distance(Path: TPathHandle): Single;cdecl;external bearlibpfLIB;
procedure pf_path_get(Path: TPathHandle; index: integer; out x: integer; out y: integer);cdecl;external bearlibpfLIB;
function pf_path_walk(Path: TPathHandle; out x: integer; out y: integer; RecalcMode: TRecalcMode): Boolean;cdecl;external bearlibpfLIB;
procedure pf_path_delete(Path: TPathHandle);cdecl;external bearlibpfLIB;

function pf_dijkstra_distance(Pathfinder: TPathfinderHandle; x: integer; y: integer): Single;cdecl;external bearlibpfLIB;
function pf_dijkstra_length(Pathfinder: TPathfinderHandle; x: integer; y: integer): Integer;cdecl;external bearlibpfLIB;
procedure pf_dijkstra_calculate(Pathfinder: TPathfinderHandle; tox, toy: Integer);cdecl;external bearlibpfLIB;
function pf_dijkstra_find_unreachable(Pathfinder: TPathfinderHandle; out x: integer; out y: integer): Boolean;cdecl;external bearlibpfLIB;

implementation

end.

