unit uAStar;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface
  uses uPathfinder;

const
  MAXLEN = 10000;
type
  TPathFindBlock = record
    CostWay:TDistance;
    Parent :TSmallPoint;
  end;

  TOpenBlock = record
    Cost: TDistance;
    X,Y: integer;
  end;
  POpenBlock = ^TOpenBlock;

  TPathFindMap = array of TPathFindBlock;
  TOpenArray = array[0..MAXLEN] of POpenBlock;


  TAStar = class(TPathfinder)
    Cells: TPathFindMap;
    Open:TOpenArray;
    OpenRaw:array[0..MAXLEN] of TOpenBlock;
    NOpen: integer;
    constructor Create(aSizeX, aSizeY: Integer; aDiagonal: TDistance);override;
    function Calculate(fromx, fromy, tox, toy: integer; p: TPath): boolean; override;
    private
      function Heuristic(dx,dy: integer): TDistance; inline;
      procedure HeapSwap(i,j: integer);inline;
      procedure HeapAdd;inline;
      procedure Heapify(i: integer);inline;

  end;

implementation

function Max(A, B: Integer): Integer;inline;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

function Min(A, B: Integer): Integer;inline;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;

function InRange(X, A, B: Integer): Boolean;inline;
begin
  Result := (X >= A) and (X <= B);
end;



{ TAStar }


  procedure TAStar.HeapSwap(i,j: integer);
  var
    tmp: POpenBlock;
  begin
    tmp := Open[i];
    Open[i] := Open[j];
    Open[j] := tmp;
  end;


  procedure TAStar.HeapAdd;
  var
    i, parent: integer;
    tmp: POpenBlock;
  begin
    i := NOpen-1;
    parent := (i-1) div 2;
    while (i > 0) and (Open[parent].Cost > Open[i].Cost)do
    begin
      HeapSwap(i, parent);
      i := parent;
      parent := (i - 1) div 2;
    end;
  end;


  procedure TAStar.Heapify(i: integer);
  var
    leftChild, rightChild, largestChild: integer;
    tmp: POpenBlock;
  begin
    repeat
        leftChild := 2 * i + 1;
        if leftChild >= NOpen then exit;
        rightChild := leftChild+1;
        largestChild := i;
        if Open[leftChild].Cost < Open[largestChild].Cost then
          largestChild := leftChild;
        if (rightChild < NOpen) and (Open[rightChild].Cost < Open[largestChild].Cost) then
          largestChild := rightChild;
        if largestChild = i then exit;
        HeapSwap(i, largestChild);
        i := largestChild;
    until false;
  end;

function TAStar.Calculate(fromx, fromy, tox, toy: integer; p: TPath): boolean;
var
  failed: boolean;

procedure BuildPath(endx, endy: Integer);
var
  ax, ay, I, N: Integer;
  bl: TSmallPoint;
begin
  //count length
  N := 1;
  ax := endx;
  ay := endy;
  while (ax <> ToX) or (ay <> ToY) do
  begin
    Inc(N);
    bl := Cells[aX*SizeY+aY].Parent;
    ax := bl.X;
    ay := bl.Y;
  end;
  SetLength(p.Data, N);
    ax := endx;
    ay := endy;
  for I := N-1 downto 0 do
  begin
    p.Data[I].x := ax;
    p.Data[I].y := aY;
    p.Data[I].distance := Cells[aX*SizeY+aY].CostWay-1;
    bl := Cells[aX*SizeY+aY].Parent;
    ax := bl.X;
    ay := bl.Y;
  end;
end;


  procedure AddToOpen(X, Y, FrX, FrY: Integer; OldCost :TDistance; is_diagonal: boolean = false);
  var
    MoveCost: TDistance;
  begin
    if not InRange(X, 0, SizeX-1) then
      exit;
    if not InRange(Y, 0, SizeY-1) then
      exit;
    with Cells[X*SizeY+Y] do
    begin
      MoveCost := Self.Rate(X, Y, frX, frY);
      if MoveCost<=0 then
        exit;
      if is_diagonal then
        MoveCost := MoveCost*Diagonal;
      if CostWay > 0 then //if OpenID > 0 then
      begin
        if CostWay <= MoveCost+OldCost then
          exit;
      end;
      if NOpen >= MAXLEN then
      begin
        failed := True;
        exit;
      end;
      Open[NOpen].X := X;
      Open[NOpen].Y := Y;
      CostWay := OldCost+MoveCost;
      Open[NOpen].Cost := CostWay + Heuristic(abs(X - FromX), abs(Y - FromY));
      Inc(NOpen);
      HeapAdd;
      Parent.X := frX;
      Parent.Y := frY;
    end;
  end;

var
  CurX, CurY :integer;
begin
  Result := False;
  failed := False;
  if not InRange(ToX, 0, SizeX-1) then
    exit;
  if not InRange(ToY, 0, SizeY-1) then
    exit;
  if (FromX = ToX) and (FromY = ToY) then
  begin
    Result := True;
    p.SetEmpty(tox, toy);
    exit;
  end;

  FillChar(Pointer(Cells)^, SizeX*SizeY*Sizeof(Cells[0]), 0);

  NOpen := 0;
  Open[NOpen].X := ToX;
  Open[NOpen].Y := ToY;
  Open[NOpen].Cost := 0;
  Cells[ToX*SizeY+ToY].CostWay := 1;
  Inc(NOpen);
  repeat
    CurX := Open[0].X;
    CurY := Open[0].Y;
    if (CurX = FromX) and (CurY = FromY) then
    begin
      Result := True;
      BuildPath(FromX, FromY);
      exit;
    end;
    with Cells[CurX*SizeY+CurY] do
    begin
      HeapSwap(0, NOpen-1);
      Dec(NOpen);
      Heapify(0);
      if Diagonal > 0 then
      begin
        AddToOpen(CurX - 1, CurY - 1, CurX, CurY, CostWay, True);
        AddToOpen(CurX - 1, CurY + 1, CurX, CurY, CostWay, True);
        AddToOpen(CurX + 1, CurY - 1, CurX, CurY, CostWay, True);
        AddToOpen(CurX + 1, CurY + 1, CurX, CurY, CostWay, True);
      end;
      AddToOpen(CurX - 1, CurY, CurX, CurY, CostWay);// + KNORM);
      AddToOpen(CurX, CurY - 1, CurX, CurY, CostWay);// + KNORM);
      AddToOpen(CurX, CurY + 1, CurX, CurY, CostWay);// + KNORM);
      AddToOpen(CurX + 1, CurY, CurX, CurY, CostWay);// + KNORM);
    end;
  until (NOpen <= 0) or failed;
  Result := False;
end;

constructor TAStar.Create(aSizeX, aSizeY: Integer; aDiagonal: TDistance);
var
  I: Integer;
begin
  inherited;
  SetLength(Cells, SizeX*SizeY);
  for I := 0 to MAXLEN do
    Open[I] := @OpenRaw[I];

end;

function TAStar.Heuristic(dx, dy: integer): TDistance;
begin
  if dx < 0 then dx := -dx;
  if dy < 0 then dy := -dy;
  if Diagonal > 0 then
    Result := max(dx,dy)+(Diagonal-1)*min(dx,dy)
  else
    Result := dx+dy;
end;

end.
