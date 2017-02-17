unit uDijkstra;

interface
  uses uPathfinder;

type

  TDijkstraRecord = record
    Distance: TDistance; //offset by one for microoptimization
    Length: integer;//offset by one for microoptimization
    NextX, NextY: Shortint;
  end;

  TDijkstra = class(TPathfinder)
    DestX, DestY: Integer;
    WaveData: array of array of TDijkstraRecord;
    constructor Create(aSizeX, aSizeY: Integer; aDiagonal: TDistance);override;
    procedure CalcMap(tox, toy: integer);
    function Calculate(fromx, fromy, tox, toy: integer; p: TPath): boolean; override;
    function FindUnreachable(out ax, ay: integer): Boolean;
  end;
implementation

uses MyMath;

{ TDijkstra }

procedure TDijkstra.CalcMap(tox, toy: integer);
var
  changed: boolean;
  minx, miny, maxx, maxy, oldminy, oldmaxy,  ax, ay, dx, dy, nx, ny: integer;
  r: TDistance;
  astep: integer;
begin
  DestX := tox;
  DestY := toy;
  SetLength(WaveData, 0, 0);
  SetLength(WaveData, SizeX, SizeY);
  WaveData[tox, toy].Distance := 1;
  WaveData[tox, toy].Length := 1;
  astep := 1;
  minx := max(0, tox-1);
  maxx := min(SizeX-1, tox+1);
  miny := max(0, toy-1);
  maxy := min(SizeY-1, toy+1);
  repeat
    changed := False;
    oldminy := miny;
    oldmaxy := maxy;
    for ax := minx to maxx do
      for ay := oldminy to oldmaxy do
      begin
//        if WaveData[ax, ay].Distance = 0 then
//          continue;
        if WaveData[ax, ay].Length <> astep then
          continue;
        for dx := -1 to 1 do
          for dy := -1 to 1 do
          begin
            if (dx = 0) and (dy = 0) then continue;
            if (Diagonal <= 0) and (dx <> 0) and (dy <> 0) then continue;
            nx := ax+dx;
            if not InRange(nx, 0, SizeX-1) then
              continue;
              ny := ay+dy;
            if not InRange(ny, 0, SizeY-1) then
              continue;
            r := Rate(nx, ny, ax, ay);
            if r <= 0 then
              continue;
            if (dx <> 0) and (dy <> 0) then
              r := r*Diagonal;

            if (WaveData[nx, ny].Distance > 0)and (WaveData[nx, ny].Distance < WaveData[ax, ay].Distance+r)  then
              continue;

            //new point reached!
            changed := True;
            WaveData[nx, ny].Distance := WaveData[ax, ay].Distance+r;
            WaveData[nx, ny].length := astep+1;
            WaveData[nx, ny].NextX := -dx;
            WaveData[nx, ny].NextY := -dy;
            if (nx > 0) and (minx > nx-1) then
              minx := nx-1;
            if (ny > 0) and (miny > ny-1) then
              miny := ny-1;
            if (nx < SizeX-1) and (maxx < nx+1) then
              maxx := nx+1;
            if (ny < SizeY-1) and (maxy < ny+1) then
              maxy := ny+1;
          end;
      end;
      inc(astep);
  until not changed;
end;

function TDijkstra.Calculate(fromx, fromy, tox, toy: integer; p: TPath): boolean;
var
  w: TDijkstraRecord;
  N, I: Integer;
  ax, ay: integer;
begin
  if (tox <> DestX) or (toy <> DestY) then
    CalcMap(tox, toy);
  if WaveData[fromx, fromy].length = 0 then
  begin
    Result := False;
    p.SetEmpty(fromx, fromy);
    exit;
  end;
  Result := True;
  N := 1;
  ax := fromx;
  ay := fromy;
  while (ax <> tox) or (ay <> toy) do
  begin
    w := WaveData[ax, ay];
    ax := ax + w.NextX;
    ay := ay + w.NextY;
    inc(N);
  end;
  SetLength(p.Data, N);
  for I := N-1 downto 0 do
  begin
    p.Data[I].x := fromx;
    p.Data[I].y := fromy;
    w := WaveData[fromx, fromy];
    p.Data[I].distance := w.Distance-1;
    fromx := fromx + w.NextX;
    fromy := fromy + w.NextY;
  end;
end;

constructor TDijkstra.Create(aSizeX, aSizeY: Integer; aDiagonal: TDistance);
begin
  inherited;
  SetLength(WaveData, SizeX, SizeY);
  DestX := -1;
end;

function TDijkstra.FindUnreachable(out ax, ay: integer): Boolean;
var
  x,y: integer;
begin
  for x := 0 to SizeX - 1 do
    for y := 0 to SizeX - 1 do
      if (WaveData[x,y].Length = 0) and (Rate(x,y,x,y) > 0) then
      begin
        ax := x;
        ay := y;
        Result := True;
        exit;
      end;
  Result := False;
end;

end.
