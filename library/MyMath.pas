unit MyMath;

interface

function Max(A, B: Integer): Integer;inline;
function Min(A, B: Integer): Integer;inline;
function InRange(X, A, B: Integer): Boolean;inline;
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


end.
