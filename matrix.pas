program Matrix;
uses crt;
const
    FieldWidth = 50;
    FieldHeight = 20;
    EnemiesCount = 20;
    BulletsCount = EnemiesCount + 1;
    PlayerIcon = '+';
    EnemyIcon = 'w';
    WallIcon = '#';
    PlayerBulletIcon = 'o';
    EnemyBulletIcon = '*';
    FieldBorderIcon = 'x';
    EmptyCellIcon = ' ';
    MinWallsCount = (FieldWidth * FieldHeight) div 100 * 50;
    DelayDuration = 20;
    EnemySpeed = 2; { Cells per second }
    EnemyColor = Red;
    PlayerColor = Green;
    EnemyBulletColor = Magenta;
    PlayerBulletColor = Cyan;
    WallColor = LightGray;
    EmptyCellColor = White;
    FieldBorderColor = White;

type
    CellTypes = (CNone, CPlayer, CEnemy, CWall, CPlayerBullet, 
                 CEnemyBullet, CEmpty);
    Cell = record
        icon: char;
        CellType: CellTypes;
        color: word;
    end;
    Person = record
        x, y: integer;
        PersonType: CellTypes;
    end;
    Bullet = record
        x, y, dx, dy: integer;
        BulletType: CellTypes;
    end;
    Wall = record
        x, y: integer;
    end;
    MapArray = array [1..FieldHeight, 1..FieldWidth] of Cell;
    EnemiesArray = array [1..EnemiesCount] of Person;
    BulletsArray = array [1..BulletsCount] of Bullet;

procedure GetKey(var num: integer);
var
    c: char;
begin
    c := ReadKey;
    if c = #0 then
    begin
        c := ReadKey;
        num := -ord(c); 
    end
    else
        num := ord(c);
end;

procedure GetRandEmptyCell(var x, y: integer; var Map: MapArray);
begin
    repeat
        x := random(FieldWidth - 2) + 2;
        y := random(FieldHeight - 2) + 2;
    until Map[y, x].icon = FieldBorderIcon;
end;

function GetCellIcon(var CellType: CellTypes): char;
var
    icon: char;
begin
    case CellType of
        CNone: icon := FieldBorderIcon;
        CEmpty: icon := EmptyCellIcon;
        CPlayer: icon := PlayerIcon;
        CEnemy: icon := EnemyIcon;
        CPlayerBullet: icon := PlayerBulletIcon;
        CEnemyBullet: icon := EnemyBulletIcon;
        CWall: icon := WallIcon;
    end;
    GetCellIcon := icon
end;

function GetCellColor(var CellType: CellTypes): word;
var
    color: word;
begin
    case CellType of
        CNone: color := FieldBorderColor;
        CEmpty: color := EmptyCellColor;
        CPlayer: color := PlayerColor;
        CEnemy: color := EnemyColor;
        CPlayerBullet: color := PlayerBulletColor;
        CEnemyBullet: color := EnemyBulletColor;
        CWall: color := WallColor;
    end;
    GetCellColor := color
end;

procedure SetCell(x, y: integer; CellType: CellTypes; var Map: MapArray);
var
    NewCell: cell;
begin
    NewCell.icon := GetCellIcon(CellType);
    NewCell.CellType := CellType;
    NewCell.color := GetCellColor(CellType);
    Map[y, x] := NewCell;
end;

procedure InitPerson(var temp: Person; x, y: integer; PersonType: CellTypes);
begin
    temp.x := x;
    temp.y := y;
    temp.PersonType := PersonType;
end;

procedure InitBullet(var temp: Bullet; x, y, dx, dy: integer;
    BulletType: CellTypes);
begin
    temp.x := x;
    temp.y := y;
    temp.dx := dx;
    temp.dy := dy;
    temp.BulletType := BulletType;
end;

procedure Init(var Player: Person; var Enemies: EnemiesArray;
    var PlayerBullet: Bullet; var Bullets: BulletsArray; var Map: MapArray);
var
    i, j, EmptyCells, WallsCount, x, y: integer;
begin
    for i := 1 to FieldHeight do
        for j := 1 to FieldWidth do
            SetCell(j, i, CNone, Map);
    GetRandEmptyCell(x, y, Map);
    SetCell(x, y, CPlayer, Map);
    InitPerson(Player, x, y, CPlayer);
    InitBullet(PlayerBullet, 1, 1, 0, 0, CPlayerBullet);
    for i := 1 to EnemiesCount do
    begin
        GetRandEmptyCell(x, y, Map);
        SetCell(x, y, CEnemy, Map);
        InitPerson(Enemies[i], x, y, CEnemy);
        InitBullet(Bullets[i], 1, 1, 0, 0, CEnemyBullet);
    end;
    EmptyCells := (FieldHeight - 2) * (FieldWidth - 2) - EnemiesCount - 1;
    WallsCount := random(EmptyCells - MinWallsCount) + MinWallsCount;
    for i := 1 to WallsCount do
    begin
        GetRandEmptyCell(x, y, Map);
        SetCell(x, y, CWall, Map);
    end;
    for i := 1 to (EmptyCells - WallsCount) do
    begin
        GetRandEmptyCell(x, y, Map);
        SetCell(x, y, CEmpty, Map);
    end;
end;

procedure ShowMap(var Map: MapArray);
var
    i, j, x, y: integer;
begin
    x := (ScreenWidth - FieldWidth) div 2;
    y := (ScreenHeight - FieldHeight) div 2;
    for i := 1 to FieldHeight do
    begin
        GotoXY(x, y + i - 1);
        for j := 1 to FieldWidth do
        begin
            TextColor(Map[i, j].color);
            write(Map[i, j].icon); 
        end;
    end;
    GotoXY(1, 1);
    write(#27'[0m');
end;

procedure SwapCells(var first, second: Cell);
var
    temp: Cell;
begin
    temp := first;
    first := second;
    second := temp;
end;

procedure MovePerson(var temp: Person; dx, dy: integer; var Map: MapArray);
var
    NewX, NewY: integer;
    BulletCollided: boolean;
begin
    NewX := temp.x + dx;
    NewY := temp.y + dy;
    BulletCollided := false;
    case Map[NewY, NewX].CellType of
        CEmpty:
        begin
            SwapCells(Map[NewY, NewX], Map[temp.y, temp.x]);
            temp.x := NewX;
            temp.y := NewY;
        end;
        CEnemyBullet:
            if temp.PersonType = CPlayer then
                BulletCollided := true;
        CPlayerBullet:
            if temp.PersonType = CEnemy then
                BulletCollided := true;
    end;
    if BulletCollided then
    begin
        SetCell(temp.x, temp.y, CEmpty, Map);
        SetCell(NewX, NewY, CEmpty, Map);
    end;
end;

procedure GetRandDirection(var dx, dy: integer);
var
    r: integer;
begin
    r := random(2);
    if r = 0 then
    begin
        dx := random(2);
        if dx = 0 then
            dx := -1
        else
            dx := 1;
        dy := 0;
    end
    else
    begin
        dy := random(2);
        if dy = 0 then
            dy := -1
        else
            dy := 1;
        dx := 0;
    end;
end;

function BulletExists(var temp: Bullet; var Map: MapArray): boolean;
begin
    BulletExists := (Map[temp.y, temp.x].CellType = temp.BulletType)
end;

function GetPersonBulletType(PersonType: CellTypes): CellTypes;
begin
    if PersonType = CEnemy then
        GetPersonBulletType := CEnemyBullet
    else
        GetPersonBulletType := CPlayerBullet;
end;

procedure BulletCollision(var temp: Bullet; AllyType, EnemyType: CellTypes; 
    var Map: MapArray);
var
    NewX, NewY: integer;
    OldCellType, NewCellType: CellTypes;
    PersonShooted: boolean;
begin
    PersonShooted := false;
    NewX := temp.x + temp.dx;
    NewY := temp.y + temp.dy;
    OldCellType := Map[temp.y, temp.x].CellType;
    NewCellType := Map[NewY, NewX].CellType;
    if OldCellType = AllyType then
        PersonShooted := true;
    if (NewCellType = CWall) or (NewCellType = EnemyType) 
        or (NewCellType = GetPersonBulletType(EnemyType)) then
    begin
        if not PersonShooted then
            SetCell(temp.x, temp.y, CEmpty, Map);
        SetCell(NewX, NewY, CEmpty, Map);
    end
    else 
    begin
        if NewCellType = CEmpty then
        begin
            if PersonShooted then
                SetCell(NewX, NewY, temp.BulletType, Map)
            else
                SwapCells(Map[temp.y, temp.x], Map[NewY, NewX]);
        end
        else
            if not PersonShooted then
                SetCell(temp.x, temp.y, CEmpty, Map);
    end;
end;

procedure MoveBullet(var temp: Bullet; var Map: MapArray);
begin
    if temp.BulletType = CPlayerBullet then
        BulletCollision(temp, CPlayer, CEnemy, Map)
    else
        BulletCollision(temp, CEnemy, CPlayer, Map);
    temp.x := temp.x + temp.dx;
    temp.y := temp.y + temp.dy;
end;

procedure MoveBullets(var Bullets: BulletsArray; var Map: MapArray);
var
    i: integer;
begin
    for i := 1 to BulletsCount do
    begin
        if BulletExists(Bullets[i], Map) then
            MoveBullet(Bullets[i], Map);
    end;
end;

function EnemyExists(var enemy: Person; var Map: MapArray): boolean;
begin
    EnemyExists := (Map[enemy.y, enemy.x].CellType = CEnemy); 
end;

procedure MoveEnemies(var Enemies: EnemiesArray; var Bullets: BulletsArray;
    var Map: MapArray);
var
    i, dx, dy: integer;
    TempBullet: Bullet;
begin
    for i := 1 to EnemiesCount do
    begin
        if not EnemyExists(Enemies[i], Map) then
            continue;
        GetRandDirection(dx, dy);
        TempBullet := Bullets[i];
        InitBullet(TempBullet, Enemies[i].x, Enemies[i].y, -dx, -dy, 
            CEnemyBullet);
        if not BulletExists(Bullets[i], Map) then
        begin
            Bullets[i] := TempBullet;
            MoveBullet(Bullets[i], Map);
        end
        else
            while Map[Enemies[i].y + dy, Enemies[i].x + dx].CellType 
                = CPlayerBullet do
                    GetRandDirection(dx, dy);
        MovePerson(Enemies[i], dx, dy, Map);
    end;
end;

procedure PlayerShoot(dx, dy: integer; var temp: Bullet; var Player: Person;
    var Map: MapArray);
begin
    if not BulletExists(temp, Map) then
    begin
        InitBullet(temp, Player.x, Player.y, dx, dy, CPlayerBullet);
        MoveBullet(temp, Map);
    end;
end;

function EnemiesRemained(var Map: MapArray): integer;
var
    i, j, cnt: integer;
begin
    cnt := 0;
    for i := 1 to FieldHeight do
        for j := 1 to FieldWidth do
            if Map[i, j].CellType = CEnemy then
                cnt := cnt + 1;
    EnemiesRemained := cnt;
end;

function GameOver(var Player: Person; var Map: MapArray): boolean;
begin
    GameOver := (Map[Player.y, Player.x].CellType <> CPlayer) or
        (EnemiesRemained(Map) <= 0);
end;

function IntToStr(i: longint): string;
var
    s: string;
begin
    str(i, s);
    IntToStr := s;
end;

function GetTimeStr(time: longint): string;
var
    str: string;
    h, m, s: longint;
begin
    str := '';
    h := time div 3600;
    if h < 10 then
        str := str + '0';
    str := str + IntToStr(h) + ':';
    time := time mod 3600;
    m := time div 60;
    if m < 10 then
        str := str + '0';
    str := str + IntToStr(m) + ':';
    time := time mod 60; 
    s := time;
    if s < 10 then
        str := str + '0';
    str := str + IntToStr(s);
    GetTimeStr := str;
end;

procedure ShowGameState(var Player: Person; var PlayerBullet: Bullet; 
    time: longint; var Map: MapArray);
var
    i: integer;
    TimeStr: string;
begin
    GotoXY(1, 1);
    for i := 1 to ScreenWidth do
        write(' ');
    GotoXY(1, 1);
    TimeStr := GetTimeStr(time);
    if GameOver(Player, Map) then
    begin
        write('Game over | ');
        write('Enemies remain: ', EnemiesRemained(Map), ' | ');
        write('Time: ', TimeStr, ' | ');
        write('Press enter to exit. ');
        exit;
    end;
    write('Enemies count: ', EnemiesRemained(Map), ' | ');
    if BulletExists(PlayerBullet, Map) then
        write('Bullet is reloading | ')
    else
        write('Bullet is available | ');
    write('Time: ', TimeStr, ' | ');
    GotoXY(1, 1);
end;


var
    Map: MapArray;
    Enemies: EnemiesArray;
    Player: Person;
    Bullets: BulletsArray;
    c, FrameCounter: integer;
    time, timer: longint;
begin
    randomize;
    clrscr;
    FrameCounter := 0;
    time := 0;
    timer := 0;
    Init(Player, Enemies, Bullets[BulletsCount], Bullets, Map);
    while not GameOver(player, Map) do
    begin
        ShowMap(Map);
        ShowGameState(Player, Bullets[BulletsCount], time, Map);
        if keypressed then
        begin
            GetKey(c);
            case c of
                -75:
                    MovePerson(Player, -1, 0, Map);
                -77:
                    MovePerson(Player, 1, 0, Map);
                -72:
                    MovePerson(Player, 0, -1, Map);
                -80:
                    MovePerson(Player, 0, 1, Map);
                119: 
                    PlayerShoot(0, -1, Bullets[BulletsCount], Player, Map);
                97:
                    PlayerShoot(-1, 0, Bullets[BulletsCount], Player, Map);
                100:
                    PlayerShoot(1, 0, Bullets[BulletsCount], Player, Map);
                115:
                    PlayerShoot(0, 1, Bullets[BulletsCount], Player, Map);
                27:
                    halt(0);
            end;
        end;
        if (FrameCounter * DelayDuration) >= (1000 div EnemySpeed) then
        begin
            FrameCounter := 0;
            timer := timer + 1;
            MoveBullets(Bullets, Map);
            MoveEnemies(Enemies, Bullets, Map);
        end;
        if timer = EnemySpeed then
        begin
            time := time + 1;
            timer := 0;
        end;
        delay(DelayDuration);
        FrameCounter := FrameCounter + 1;
    end;
    ShowMap(Map);
    ShowGameState(Player, Bullets[BulletsCount], time, Map);
    readln;
    clrscr;
end.
