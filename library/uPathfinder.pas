unit uPathfinder;

interface

type
  TDistance = Single;

  TSmallPoint = record
    X, Y :Word;
  end;

	TPFCallback = function(fromx, fromy, tox, toy: integer; opaque: pointer): TDistance;cdecl;

  TPathPoint = record
    x,y: Smallint;
    distance: TDistance;
  end;

  TPathfinder = class;
  TPath = class
    Owner: TPathfinder;
    Data: array of TPathPoint;
    gced: boolean;
    function Walk(out x: integer; out y: integer; check: boolean): boolean;
    procedure AddPoint(ax, ay: integer; d: TDistance);
    procedure Clear;
    procedure Revert;
    function Empty: boolean;
    destructor Destroy; override;
    function Recalculate: Boolean;
    procedure SetEmpty(ax, aY: integer);
  end;

  TGCPath = record
    owner: pointer;
    path: TPath;
  end;

  TPathfinder = class
    SizeX, SizeY: Integer;
    Diagonal: TDistance;

    MapUsed: Boolean;
    Callback: TPFCallback;
    Opaque: Pointer;
    MapId, MapLayer: Integer;
    GC: array of TGCPath;

    function NewPath: TPath;
    function GCPath(aowner: pointer): TPath;
    constructor Create(aSizeX, aSizeY: Integer; aDiagonal: TDistance);virtual;
    destructor Destroy; override;
    function Rate(fromx, fromy, tox, toy: integer): TDistance;
    procedure InitForMap(amap_id, alayer: Integer);
    procedure InitForCallback(aopaque: pointer; acallback: TPFCallback);
    function Calculate(fromx, fromy, tox, toy: integer; p: TPath): boolean; virtual;abstract;
  end;

  TPathfinderClass = class of TPathfinder;

implementation
uses BearLibMap, uDijkstra, uAStar;

{ TPathfinder }

constructor TPathfinder.Create(aSizeX, aSizeY: Integer; aDiagonal: TDistance);
begin
  SizeX := aSizeX;
  SizeY := aSizeY;
  Diagonal := aDiagonal;
  if Diagonal >= 2 then
    Diagonal := 0;
end;

destructor TPathfinder.Destroy;
var
  rec: TGCPath;
begin
  for rec in GC do
  begin
    rec.path.gced := False;
    rec.path.Free;
  end;
  inherited;
end;

function TPathfinder.GCPath(aowner: pointer): TPath;
var
  rec: TGCPath;
begin
  for rec in GC do
    if rec.owner = aowner then
    begin
      Result := rec.path;
      exit;
    end;
  Result := NewPath;
  Result.gced := True;
  SetLength(GC, length(GC)+1);
  with GC[High(GC)]do
  begin
    owner := aowner;
    path := Result;
  end;
end;

procedure TPathfinder.InitForCallback(aopaque: pointer; acallback: TPFCallback);
begin
  Opaque := aopaque;
  Callback := acallback;
  MapUsed := False;
end;

procedure TPathfinder.InitForMap(amap_id, alayer: Integer);
begin
  MapId := amap_id;
  MapLayer := alayer;
  MapUsed := True;
end;

function TPathfinder.NewPath: TPath;
begin
  Result := TPath.Create;
  Result.Owner := self;
end;

function TPathfinder.Rate(fromx, fromy, tox, toy: integer): TDistance;
begin
  if MapUsed then
    Result := map_get(MapId, tox, toy, MapLayer)
  else
    Result := Callback(fromx, fromy, tox, toy, Opaque);
end;

{ TPath }

procedure TPath.AddPoint(ax, ay: integer; d: TDistance);
begin
  SetLength(Data, length(Data)+1);
  Data[high(Data)].x := ax;
  Data[high(Data)].y := ay;
  Data[high(Data)].distance := d
end;

procedure TPath.Clear;
begin
  SetLength(Data, 0);
end;

destructor TPath.Destroy;
var
  i: integer;
  rec: TGCPath;
begin
  if gced then
  begin
    for I := 0 to length(Owner.GC) - 1 do
      if owner.GC[i].path = self then
      begin
        Owner.GC[I] := Owner.GC[high(Owner.GC)];
        SetLength(Owner.GC, length(Owner.GC)-1);
        break;
      end;
  end;
  inherited;
end;

function TPath.Empty: boolean;
begin
  Result := length(Data) < 2
end;

function TPath.Recalculate: Boolean;
var
  frx, fry, tox, toy: integer;
begin
  frx := Data[high(Data)].x;
  fry := Data[high(Data)].y;
  tox := Data[0].x;
  toy := Data[0].y;
  Result := Owner.Calculate(frx, fry, tox, toy, self);
end;

procedure TPath.Revert;
var
  i: integer;
  it: TPathPoint;
  maxd: TDistance;
begin
  //at first, revert order of elements
  for I := 0 to (length(Data) div 2)-1 do
  begin
    it := Data[I];
    Data[I] := Data[Length(Data)-1-I];
    Data[Length(Data)-1-I] := it;
  end;
  //then revert distances
  maxd := Data[0].distance;
  for I := 0 to High(Data) do
    Data[I].distance := maxd - Data[I].distance;
end;

procedure TPath.SetEmpty(ax, aY: integer);
begin
  SetLength(Data, 1);
  Data[0].x := ax;
  Data[0].y := ay;
  Data[0].distance := 0;
end;

function TPath.Walk(out x, y: integer; check: boolean): boolean;
var
  n: integer;
begin
  Result := False;
  if Empty then exit;
  n := length(Data);
  if check and (Owner.Rate(Data[n-1].x, Data[n-1].y, Data[n-2].x, Data[n-2].y) <= 0) then exit;
  Result := True;
  SetLength(Data, n-1);
  x := data[n-2].x;
  y := data[n-2].y;
end;

end.
