program main(input, output, DataFile);

{*****************************************************************************}
{* Prime Elite                                                               *}
{*****************************************************************************}
{* A port of txtelite.c from Ian Bell's site                                 *}
{* http://elitehomepage.org/text/index.htm                                   *}  
{*                                                                           *}
{* Initial plan is to get it ported as-is and to then expand into something  *}
{* more 'gui' based, a bit like the old Star Trek game.                      *}
{*                                                                           *}
{*****************************************************************************}
{*                                                                           *}
{* With help from 'Fully documented source code for Elite on the BBC Micro'  *}
{*   https://www.bbcelite.com/deep_dives/galaxy_and_system_seeds.html        *}
{* Elite: "The game that couldn't be written"                                *}
{*   https://youtu.be/lC4YLMLar5I                                            *}
{*                                                                           *}
{*****************************************************************************}
{* 25 APR 2024 | 1.7.0 - ShipType used to consolidate game global            *}
{*             |         variables                                           *}
{*             |         Save/Load                                           *}
{* 18 APR 2024 | 1.6.0 - Upgrades                                            *}
{* 14 APR 2024 | 1.5.0 - Local and Galaxy Mapping                            *}
{* 06 APR 2024 | 1.4.0 - User input parsing                                  *}
{*             |         Help, Local, Info                                   *}
{*             |         Market, Jump, Warp                                  *}
{*             |         Fuel                                                *}
{*             |         Buying and Selling                                  *}
{* 01 APR 2024 | 1.3.0 - Markets and Goat Soup                               *}
{* 31 Mar 2024 | Milestoned 1.2.0 getting Procedural generation of 'galaxy'  *}
{*             | working.                                                    *}
{*****************************************************************************}

const
  %INCLUDE 'SYSCOM>KEYS.INS.PASCAL';
  %INCLUDE 'SYSCOM>A$KEYS.INS.PASCAL';
  %INCLUDE 'SYSCOM>ERRD.INS.PASCAL';
  
  version             = '1.7.0';
  SaveDataFileName    = 'savedata.dat';
  
  galsize             = 256;
  galsizem            = 255;
  
  AlienItems          = 16;
  lasttrade           = AlienItems;
  lasttradem          = 15;
  lasttradep          = 17;

  base0               = 23114;
  base1               = 584;
  base2               = 46931;
  
  shortdesc           = 0;   {* For PriSys *}
  coldesc             = 1;
  fulldesc            = 2;
  
  DoByTen             = true;
  normal              = false;
  
  numforLave          = 7;   {* Our Start Position *}
  StartingGalaxy      = 1;   {* Our Start Position *}
  
  NumUpgrades         = 11;

  RegularHold         = 20;
  LargeHold           = 30;
  
  RegularFuelTank     = 70;
  LargeFuelTank       = 90;

  tonnes              = 0;
  
  LegalCLEAN          = 1;
  LegalOFFENDER       = 2;
  LegalFUGITIVE       = 3;
  
  UPG_CARGO           = 2;
  UPG_ECM             = 3;
  UPG_LASER1          = 4;
  UPG_LASER2          = 5;
  UPG_FTANK           = 6;
  UPG_ESCAPE          = 7;
  UPG_EBOMB           = 8;
  UPG_ENERGY          = 9;
  UPG_DOCK            = 10;
  UPG_GALHYP          = 11;
  
type
  planetnum     = integer;
  
  chrpostype    = array[1..2] of integer;

  seedtype      = record
    w0, w1, w2: longinteger;
  end; { six byte random number used as seed for planets } 

  fastseedtype  = record
    a, b, c, d: longinteger;
  end; { four byte random number used for planet description }

  plansys       = record
    x, y              : longinteger;
    economy, govtype  : longinteger;  
    techlev           : longinteger;           
    population        : longinteger;        
    productivity      : longinteger;     
    radius            : longinteger;            
    goatsoupseed      : fastseedtype;
    name              : string;
    Iname             : string;                  
  end;
  
  Tradegood     = record
    legal       : boolean;
    baseprice   : longinteger;
    gradient    : longinteger;
    basequant   : longinteger;
    maskbyte    : longinteger;
    units       : longinteger;
    name        : string;
  end;
  
  markettype    = record
    quantity  : array[0..lasttrade] of longinteger;
    price     : array[0..lasttrade] of longinteger;
  end;
  
  desc_option   = record
    option: array[1..5] of string;
  end;
  
  EquipType     = record
    Name      : string;
    TechLevel : integer;
    Price     : longinteger;
  end;
  
  ShipType      = record
    CurrentGalaxy     : longinteger;
    CurrentPlanet     : longinteger;
    Credit            : longinteger;
    Fuel              : longinteger;
    Fueltank          : longinteger;
    Holdspace         : longinteger;
    MaxHold           : longinteger;
    Missiles          : integer;
    Hold              : array[0..lasttradep] of longinteger;
    Upgraded          : array[2..NumUpgrades] of boolean;
    LegalStatus       : Integer;
    Rating            : Integer;
    Name              : string;
  end;
 
  SaveData      = record
    ShipSaveData    : ShipType;
    DateSaved       : longinteger;
  end;
  
var
  Ship              : ShipType;
    
  galaxy            : array[0..galsizem] of plansys;
  Desc_List         : array[129..164] of desc_option;
  govnames          : array[0..7] of string;
  econnames         : array[0..7] of string;
  commodities       : array[0..16] of Tradegood;
  Upgrades          : array[1..NumUpgrades] of EquipType;
  LegalDesc         : array[1..3] of string;
  RatingDesc        : array[1..11] of string;

  
  seed              : seedtype;
  rnd_seed          : fastseedtype;
  lastrand          : longinteger;
  
  Upairs            : string;

  Urpn_pairs        : string;
  Lrpn_pairs        : string;
  unitnames         : array[0..2] of string;
  localmarket       : markettype;
  soup_string       : string;
  
  i                 : integer;
  finished          : boolean;
  
  day_of_week       : integer;
  formatted_date    : string;

  
{* ******************************************** *}
{* External fuctions                            *}
{* ******************************************** *}

PROCEDURE RNDI$A(Seed:REAL); EXTERN;                                              {* Set random seed, and random number  *}
FUNCTION  RAND$A(VAR Seed : LONGINTEGER):REAL; EXTERN;                            {* SubRef Guide IV   13-2 - li vappl   *}

PROCEDURE CH$FX1(convert:STRING; VAR toint:INTEGER; VAR error:INTEGER); EXTERN;   {* SubRef Guide III  6-3               *}

PROCEDURE CASE$A(key:INTEGER; VAR convert:STRING; len:INTEGER); EXTERN;           {* SubRef Guide IV   14-2              *}

FUNCTION  EXST$A(name:STRING; namelen:INTEGER):BOOLEAN; EXTERN;                   {* SubRef Guide IV   15-4              *}
PROCEDURE SRCH$$(key:INTEGER; Name:STRING;namelen,funit:INTEGER;                  {* SubRef Guide II   4-110             *}
                  VAR ftype:INTEGER; VAR code:INTEGER);EXTERN;
                 
PROCEDURE TSRC$$(key:INTEGER; Name:STRING; funit:INTEGER;                         {* SubRef Guide II   A-17              *}
                 chrpos:chrpostype; ctype:INTEGER;                 
                  VAR code:INTEGER); EXTERN;
                  
FUNCTION  NLEN$A(instring:STRING; len:INTEGER):INTEGER; EXTERN;                   {* SubRef Guide IV   10-25             *}
FUNCTION  TNCHK$(key:INTEGER; Name:STRING):BOOLEAN; EXTERN;                       {* SubRef Guide II   4-121             *}

FUNCTION  DATE$:LONGINTEGER; EXTERN;                                              {* SubRef Guide III  2-11              *}
PROCEDURE CV$FDV(fsdate:LONGINTEGER; VAR day_of_week:INTEGER;                     {* SubRef Guide III  6-17              *}      
                  VAR formatted_date:STRING);EXTERN;
                  
{* ******************************************** *}
{* General fuctions                             *}
{* ******************************************** *}

procedure mysrand(set_seed:real);

begin
  RNDI$A(set_seed);
  lastrand := trunc(set_seed - 1);
end;

{* ============================================ *}

function myrand:longinteger;

var
  r : longinteger;
  
begin
  r := (((((((((lastrand * 8) - lastrand) * 8) + lastrand) * 2) + lastrand) * 16) - lastrand) * 2) - lastrand;
  r := r + 3680;
  r := r & 2147483647;
 	lastrand := r - 1;	
  myrand := r;
end;

{* ============================================ *}

function XOR(a, b: longinteger): longinteger;

begin
  {* Because Prime Pascal is brain-dead and has no native XOR function *}
  XOR := (a ! b) &  (-1 - (a & b));
end;

{* ============================================ *}

function gen_rnd_number: longinteger;

var
  a, x: longinteger;
  
begin
  x := (rnd_seed.a * 2) & 255;
  a := x + rnd_seed.c;
  if rnd_seed.a > 127 then a := a + 1;
  rnd_seed.a := a & 255;
  rnd_seed.c := x;
  a := (a div 256);
  x := rnd_seed.b;
  a := (a + x + rnd_seed.d) & 255;
  rnd_seed.b := a;
  rnd_seed.d := x;
  gen_rnd_number := a;
end;

{* ============================================ *}

function strc(c:integer):string;

begin
  {* Because Prime Pascal is dumb and will not take a single char to a string *}
  strc := str(chr(c));
end;

{* ============================================ *}

function ToUpper(in_string: string): string;
{* Because Prime Pascal is brain-dead and has no native function *}
  
begin  
  CASE$A(A$FUPP,in_string,length(in_string)+2);
  ToUpper := in_string;
end;

{* ============================================ *}

function ToLower(in_string: string): string;
{* Because Prime Pascal is brain-dead and has no native function *}

begin
  CASE$A(A$FLOW,in_string,length(in_string)+2);
  ToLower := in_string;
end;

{* ============================================ *}

function ToScase(in_string: string): string;
 
begin
  ToScase := ToUpper(substr(in_string,1,1)) + ToLower(substr(in_string,2,length(in_string)-1));
end;

{* ============================================ *}

function DblSpaceStrip(instring:string):string;

begin
  instring := trim(instring);
  instring := ltrim(instring);  
  instring := ToUpper(instring);
  while index(instring,'  ') <> 0 do begin
    instring := delete(instring,index(instring,'  '),1)
  end;
  DblSpaceStrip := instring;
end;

{* ============================================ *}

procedure StripOut(var s: string; c:char);

begin
  while index(s,c) <> 0 do begin
     s := delete(s,index(s,c),1);
  end;
end;

{* ============================================ *}

procedure StrToInt(amount:string; var toint:integer; byten:boolean;var ok:boolean);

var
  error : integer;
  
begin
  ok := false;

  {* Sometimes, like fuel, numbers are ten times bigger than user sees *}
  
  StripOut(amount,' ');
  
  if byten then begin
    if index(amount,'.') <> 0 then StripOut(amount,'.') else amount := amount + str('0');
  end;
                            
  CH$FX1(amount,toint,error);
  
  case error of
    1 : writeln('Not a number?');         {* Blanks   *}
    2 : writeln('Not a number ...');      {* Overflow *}
    3 : writeln('Not a number.');         {* Bad Char *}
    4 : writeln('Not a number!');         {* Illegal  *}
  otherwise begin
      toint := abs(toint);  
      ok := true;
    end;
  end; 
end;

{* ============================================ *}

function Scale(value,oldmin,oldmax,newmin,newmax: longinteger): longinteger;

  
begin
  Scale := Round((value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin);
end;

{* ============================================ *}

function InRange(v,low,high:integer):boolean;

begin
  if (v >= low) and (v <= high) then InRange := true else InRange := false;
end;

{* ============================================ *}

function File_Exists(FileName: string):boolean;

var
  ftype,errcode : integer;
  chrpos        : chrpostype;
  
begin
  FileName := ToUpper(FileName);

  ftype := 0;
  errcode := 0;
  
  chrpos[1] := 2;                  
  chrpos[2] := length(filename)+2;
  
  TSRC$$(k$exst, FileName,1,chrpos,ftype, errcode);
  
  if errcode = 0  then File_Exists := true
                  else File_Exists := false;
end;

{* ******************************************** *}
{* Game setup fuctions                          *}
{* ******************************************** *}

procedure INIT_Pairs;

begin
  {* Galaxy Planet Names *}
  Upairs := '..LEXEGEZACEBISOUSESARMAINDIREA.ERATENBERALAVETIEDORQUANTEISRION';

  {* Random Planet Names *}
  Urpn_pairs := 'ABOUSEITILETSTONLONUTHNOALLEXEGEZACEBISOUSESARMAINDIREA.ERATENBERALAVETIEDORQUANTEISRION';
  Lrpn_pairs := 'abouseitiletstonlonuthnoallexegezacebisousesarmaindirea.eratenberalavetiedorquanteisrion';
end;

{* ============================================ *}

procedure INIT_PlanetDesc_List;

begin
  {* 
  * < = <planet name>
  * > = <planet name>ian
  * @ = <random name>
  *}
  Desc_List[129].option[1] := 'fabled';
  Desc_List[129].option[2] := 'notable';
  Desc_List[129].option[3] := 'well known';
  Desc_List[129].option[4] := 'famous';
  Desc_List[129].option[5] := 'noted';

  Desc_List[130].option[1] := 'very';
  Desc_List[130].option[2] := 'mildly';
  Desc_List[130].option[3] := 'most';
  Desc_List[130].option[4] := 'reasonably';
  Desc_List[130].option[5] := '';

  Desc_List[131].option[1] := 'ancient';
  Desc_List[131].option[2] := strc(149);
  Desc_List[131].option[3] := 'great';
  Desc_List[131].option[4] := 'vast';
  Desc_List[131].option[5] := 'pink';

  Desc_List[132].option[1] := strc(158)+str(' ')+strc(157)+' plantations';
  Desc_List[132].option[2] := 'mountains';
  Desc_List[132].option[3] := strc(156);
  Desc_List[132].option[4] := strc(148)+' forests';
  Desc_List[132].option[5] := 'oceans';

  Desc_List[133].option[1] := 'shyness';
  Desc_List[133].option[2] := 'silliness';
  Desc_List[133].option[3] := 'mating traditions';
  Desc_List[133].option[4] := 'loathing of '+strc(134);
  Desc_List[133].option[5] := 'love for '+strc(134);

  Desc_List[134].option[1] := 'food blenders';
  Desc_List[134].option[2] := 'tourists';
  Desc_List[134].option[3] := 'poetry';
  Desc_List[134].option[4] := 'discos';
  Desc_List[134].option[5] := strc(142);

  Desc_List[135].option[1] := 'talking tree';
  Desc_List[135].option[2] := 'crab';
  Desc_List[135].option[3] := 'bat';
  Desc_List[135].option[4] := 'lobst';
  Desc_List[135].option[5] := str('@');

  Desc_List[136].option[1] := 'beset';
  Desc_List[136].option[2] := 'plagued';
  Desc_List[136].option[3] := 'ravaged';
  Desc_List[136].option[4] := 'cursed';
  Desc_List[136].option[5] := 'scourged';

  Desc_List[137].option[1] := strc(150)+' civil war';
  Desc_List[137].option[2] := strc(155)+str(' ')+strc(152)+str(' ')+strc(153)+str('s');
  Desc_List[137].option[3] := 'a '+strc(155)+' disease';
  Desc_List[137].option[4] := strc(150)+' earthquakes';
  Desc_List[137].option[5] := strc(150)+' solar activity';

  Desc_List[138].option[1] := 'its '+strc(131)+str(' ')+strc(132);
  Desc_List[138].option[2] := 'the > '+strc(152)+str(' ')+strc(153);
  Desc_List[138].option[3] := 'its inhabitants'' '+strc(154)+str(' ')+strc(133);
  Desc_List[138].option[4] := strc(161);
  Desc_List[138].option[5] := 'its '+strc(141)+str(' ')+strc(142);

  Desc_List[139].option[1] := 'juice';
  Desc_List[139].option[2] := 'brandy';
  Desc_List[139].option[3] := 'water';
  Desc_List[139].option[4] := 'brew';
  Desc_List[139].option[5] := 'gargle blasters';

  Desc_List[140].option[1] := str('@');
  Desc_List[140].option[2] := '> '+strc(153);
  Desc_List[140].option[3] := '> @';
  Desc_List[140].option[4] := '> '+strc(155);
  Desc_List[140].option[5] := strc(155)+' @';

  Desc_List[141].option[1] := 'fabulous';
  Desc_List[141].option[2] := 'exotic';
  Desc_List[141].option[3] := 'hoopy';
  Desc_List[141].option[4] := 'unusual';
  Desc_List[141].option[5] := 'exciting';

  Desc_List[142].option[1] := 'cuisine';
  Desc_List[142].option[2] := 'night life';
  Desc_List[142].option[3] := 'casinos';
  Desc_List[142].option[4] := 'sit coms';
  Desc_List[142].option[5] := str(' ')+strc(161);

  Desc_List[143].option[1] := str('<');
  Desc_List[143].option[2] := 'The planet <';
  Desc_List[143].option[3] := 'The world <';
  Desc_List[143].option[4] := 'This planet';
  Desc_List[143].option[5] := 'This world';

  Desc_List[144].option[1] := 'n unremarkable';
  Desc_List[144].option[2] := ' boring';
  Desc_List[144].option[3] := ' dull';
  Desc_List[144].option[4] := ' tedious';
  Desc_List[144].option[5] := ' revolting';

  Desc_List[145].option[1] := 'planet';
  Desc_List[145].option[2] := 'world';
  Desc_List[145].option[3] := 'place';
  Desc_List[145].option[4] := 'little planet';
  Desc_List[145].option[5] := 'dump';

  Desc_List[146].option[1] := 'wasp';
  Desc_List[146].option[2] := 'moth';
  Desc_List[146].option[3] := 'grub';
  Desc_List[146].option[4] := 'ant';
  Desc_List[146].option[5] := str('@');

  Desc_List[147].option[1] := 'poet';
  Desc_List[147].option[2] := 'arts graduate';
  Desc_List[147].option[3] := 'yak';
  Desc_List[147].option[4] := 'snail';
  Desc_List[147].option[5] := 'slug';

  Desc_List[148].option[1] := 'tropical';
  Desc_List[148].option[2] := 'dense';
  Desc_List[148].option[3] := 'rain';
  Desc_List[148].option[4] := 'impenetrable';
  Desc_List[148].option[5] := 'exuberant';

  Desc_List[149].option[1] := 'funny';
  Desc_List[149].option[2] := 'wierd';
  Desc_List[149].option[3] := 'unusual';
  Desc_List[149].option[4] := 'strange';
  Desc_List[149].option[5] := 'peculiar';

  Desc_List[150].option[1] := 'frequent';
  Desc_List[150].option[2] := 'occasional';
  Desc_List[150].option[3] := 'unpredictable';
  Desc_List[150].option[4] := 'dreadful';
  Desc_List[150].option[5] := 'deadly';

  Desc_List[151].option[1] := strc(130)+str(' ')+strc(129)+' for '+strc(138);
  Desc_List[151].option[2] := strc(130)+str(' ')+strc(129)+' for '+strc(138)+' and '+strc(138);
  Desc_List[151].option[3] := strc(136)+' by '+strc(137);
  Desc_List[151].option[4] := strc(130)+str(' ')+strc(129)+' for '+strc(138)+' but '+strc(136)+' by '+strc(137);
  Desc_List[151].option[5] := str('a')+strc(144)+str(' ')+strc(145);

  Desc_List[152].option[1] := strc(155);
  Desc_List[152].option[2] := 'mountain';
  Desc_List[152].option[3] := 'edible';
  Desc_List[152].option[4] := 'tree';
  Desc_List[152].option[5] := 'spotted';

  Desc_List[153].option[1] := strc(159);
  Desc_List[153].option[2] := strc(160);
  Desc_List[153].option[3] := strc(135)+'oid';
  Desc_List[153].option[4] := strc(147);
  Desc_List[153].option[5] := strc(146);

  Desc_List[154].option[1] := 'ancient';
  Desc_List[154].option[2] := 'exceptional';
  Desc_List[154].option[3] := 'eccentric';
  Desc_List[154].option[4] := 'ingrained';
  Desc_List[154].option[5] := strc(149);

  Desc_List[155].option[1] := 'killer';
  Desc_List[155].option[2] := 'deadly';
  Desc_List[155].option[3] := 'evil';
  Desc_List[155].option[4] := 'lethal';
  Desc_List[155].option[5] := 'vicious';

  Desc_List[156].option[1] := 'parking meters';
  Desc_List[156].option[2] := 'dust clouds';
  Desc_List[156].option[3] := 'ice bergs';
  Desc_List[156].option[4] := 'rock formations';
  Desc_List[156].option[5] := 'volcanoes';

  Desc_List[157].option[1] := 'plant';
  Desc_List[157].option[2] := 'tulip';
  Desc_List[157].option[3] := 'banana';
  Desc_List[157].option[4] := 'corn';
  Desc_List[157].option[5] := '@weed';

  Desc_List[158].option[1] := str('@');
  Desc_List[158].option[2] := '> @';
  Desc_List[158].option[3] := '> '+strc(155);
  Desc_List[158].option[4] := 'inhabitant';
  Desc_List[158].option[5] := '> @';

  Desc_List[159].option[1] := 'shrew';
  Desc_List[159].option[2] := 'beast';
  Desc_List[159].option[3] := 'bison';
  Desc_List[159].option[4] := 'snake';
  Desc_List[159].option[5] := 'wolf';

  Desc_List[160].option[1] := 'leopard';
  Desc_List[160].option[2] := 'cat';
  Desc_List[160].option[3] := 'monkey';
  Desc_List[160].option[4] := 'goat';
  Desc_List[160].option[5] := 'fish';

  Desc_List[161].option[1] := strc(140)+str(' ')+strc(139);
  Desc_List[161].option[2] := '> '+strc(159)+str(' ')+strc(162);
  Desc_List[161].option[3] := 'its '+strc(142)+str(' ')+strc(162);
  Desc_List[161].option[4] := strc(163)+str(' ')+strc(164);
  Desc_List[161].option[5] := strc(140)+str(' ')+strc(139);

  Desc_List[162].option[1] := 'meat';
  Desc_List[162].option[2] := 'cutlet';
  Desc_List[162].option[3] := 'steak';
  Desc_List[162].option[4] := 'burgers';
  Desc_List[162].option[5] := 'soup';

  Desc_List[163].option[1] := 'ice';
  Desc_List[163].option[2] := 'mud';
  Desc_List[163].option[3] := 'Zero-G';
  Desc_List[163].option[4] := 'vacuum';
  Desc_List[163].option[5] := '> ultra';

  Desc_List[164].option[1] := 'hockey';
  Desc_List[164].option[2] := 'cricket';
  Desc_List[164].option[3] := 'karate';
  Desc_List[164].option[4] := 'polo';
  Desc_List[164].option[5] := 'tennis';

end;

{* ============================================ *}

procedure INIT_Commodities;

var
   i: integer;

begin
  unitnames[0] := 't '; 
  unitnames[1] := 'kg'; 
  unitnames[2] := 'g '; 

  commodities[0].legal     := true;
  commodities[0].baseprice := 19;
  commodities[0].gradient  := -2;
  commodities[0].basequant := 6;
  commodities[0].maskbyte  := 1;
  commodities[0].units     := 0;
  commodities[0].name      := 'Food        ';

  commodities[1].legal     := true;
  commodities[1].baseprice := 20;
  commodities[1].gradient  := -1;
  commodities[1].basequant := 10;
  commodities[1].maskbyte  := 3;
  commodities[1].units     := 0;
  commodities[1].name      := 'Textiles    ';

  commodities[2].legal     := true;
  commodities[2].baseprice := 65;
  commodities[2].gradient  := -3;
  commodities[2].basequant := 2;
  commodities[2].maskbyte  := 7;
  commodities[2].units     := 0;
  commodities[2].name      := 'Radioactives';

  commodities[3].legal     := false;
  commodities[3].baseprice := 40;
  commodities[3].gradient  := -5;
  commodities[3].basequant := 226;
  commodities[3].maskbyte  := 31;
  commodities[3].units     := 0;
  commodities[3].name      := 'Robo-Slaves ';

  commodities[4].legal     := true;
  commodities[4].baseprice := 83;
  commodities[4].gradient  := -5;
  commodities[4].basequant := 507;
  commodities[4].maskbyte  := 15;
  commodities[4].units     := 0;
  commodities[4].name      := 'Liquor      ';

  commodities[5].legal     := true;
  commodities[5].baseprice := 196;
  commodities[5].gradient  := 8;
  commodities[5].basequant := 54;
  commodities[5].maskbyte  := 3;
  commodities[5].units     := 0;
  commodities[5].name      := 'Luxuries    ';

  commodities[6].legal     := false;
  commodities[6].baseprice := 235;
  commodities[6].gradient  := 29;
  commodities[6].basequant := 8;
  commodities[6].maskbyte  := 120;
  commodities[6].units     := 0;
  commodities[6].name      := 'Narcotics   ';

  commodities[7].legal     := true;
  commodities[7].baseprice := 154;
  commodities[7].gradient  := 14;
  commodities[7].basequant := 56;
  commodities[7].maskbyte  := 7;
  commodities[7].units     := 0;
  commodities[7].name      := 'Computers   ';

  commodities[8].legal     := true;
  commodities[8].baseprice := 117;
  commodities[8].gradient  := 6;
  commodities[8].basequant := 40;
  commodities[8].maskbyte  := 7;
  commodities[8].units     := 0;
  commodities[8].name      := 'Machinery   ';

  commodities[9].legal     := true;
  commodities[9].baseprice := 78;
  commodities[9].gradient  := 1;
  commodities[9].basequant := 17;
  commodities[9].maskbyte  := 31;
  commodities[9].units     := 0;
  commodities[9].name      := 'Alloys      ';

  commodities[10].legal     := false;
  commodities[10].baseprice := 124;
  commodities[10].gradient  := 13;
  commodities[10].basequant := 29;
  commodities[10].maskbyte  := 7;
  commodities[10].units     := 0;
  commodities[10].name      := 'Weapons     ';

  commodities[11].legal     := true;
  commodities[11].baseprice := 176;
  commodities[11].gradient  := -9;
  commodities[11].basequant := 220;
  commodities[11].maskbyte  := 63;
  commodities[11].units     := 0;
  commodities[11].name      := 'Furs        ';

  commodities[12].legal     := true;
  commodities[12].baseprice := 32;
  commodities[12].gradient  := -1;
  commodities[12].basequant := 53;
  commodities[12].maskbyte  := 3;
  commodities[12].units     := 0;
  commodities[12].name      := 'Minerals    ';

  commodities[13].legal     := true;
  commodities[13].baseprice := 97;
  commodities[13].gradient  := -1;
  commodities[13].basequant := 66;
  commodities[13].maskbyte  := 7;
  commodities[13].units     := 1;
  commodities[13].name      := 'Gold        ';

  commodities[14].legal     := true;
  commodities[14].baseprice := 171;
  commodities[14].gradient  := -2;
  commodities[14].basequant := 55;
  commodities[14].maskbyte  := 31;
  commodities[14].units     := 1;
  commodities[14].name      := 'Platinum    ';

  commodities[15].legal     := true;
  commodities[15].baseprice := 45;
  commodities[15].gradient  := -1;
  commodities[15].basequant := 250;
  commodities[15].maskbyte  := 15;
  commodities[15].units     := 2;
  commodities[15].name      := 'Gem-Strones ';

  commodities[16].legal     := true;
  commodities[16].baseprice := 53;
  commodities[16].gradient  := 15;
  commodities[16].basequant := 192;
  commodities[16].maskbyte  := 7;
  commodities[16].units     := 0;
  commodities[16].name      := 'Alien Items ';

  
end;

{* ============================================ *}

procedure INIT_Govnames;

begin
  govnames[0] := 'Anarchy';
  govnames[1] := 'Feudal';
  govnames[2] := 'Multi-Gov';
  govnames[3] := 'Dictatorship';
  govnames[4] := 'Communist';
  govnames[5] := 'Confederacy';
  govnames[6] := 'Democracy';
  govnames[7] := 'Corporate State';
end;

{* ============================================ *}

procedure INIT_Econnames;

begin
  econnames[0] := 'Rich Ind';
  econnames[1] := 'Average Ind';
  econnames[2] := 'Poor Ind';
  econnames[3] := 'Mainly Ind';
  econnames[4] := 'Mainly Agri';
  econnames[5] := 'Rich Agri';
  econnames[6] := 'Average Agri';
  econnames[7] := 'Poor Agri';
end;

{* ============================================ *}

procedure INIT_Upgrades;

begin
  Upgrades[1].Name :=  'Missile            ';
  Upgrades[1].TechLevel := 1;
  Upgrades[1].Price := 250;

  Upgrades[2].Name :=  'Large Cargo Bay    ';
  Upgrades[2].TechLevel := 2;
  Upgrades[2].Price := 4000;

  Upgrades[3].Name :=  'ECM System         ';
  Upgrades[3].TechLevel := 2;
  Upgrades[3].Price := 5000;

  Upgrades[4].Name :=  'Laser Cooling      ';
  Upgrades[4].TechLevel := 3;
  Upgrades[4].Price := 4000;

  Upgrades[5].Name :=  'Laser Power        ';
  Upgrades[5].TechLevel := 4;
  Upgrades[5].Price := 7500;

  Upgrades[6].Name :=  'Fuel Tank          ';
  Upgrades[6].TechLevel := 5;
  Upgrades[6].Price := 4250;

  Upgrades[7].Name :=  'Escape Capsule     ';
  Upgrades[7].TechLevel := 6;
  Upgrades[7].Price := 10000;

  Upgrades[8].Name :=  'Energy Bomb        ';
  Upgrades[8].TechLevel := 7;
  Upgrades[8].Price := 4500;

  Upgrades[9].Name :=  'Extra Energy Unit  ';
  Upgrades[9].TechLevel := 8;
  Upgrades[9].Price := 8000;

  Upgrades[10].Name := 'Docking Computers  ';
  Upgrades[10].TechLevel := 9;
  Upgrades[10].Price := 7500;

  Upgrades[11].Name := 'Galactic HyperWarp';
  Upgrades[11].TechLevel := 10;
  Upgrades[11].Price := 50000;
end;

{* ============================================ *}

procedure INIT_Legal;

begin
  LegalDesc[1]  := 'CLEAN';
  LegalDesc[2]  := 'OFFENDER';
  LegalDesc[3]  := 'FUGATIVE';
end;

{* ============================================ *}

procedure INIT_Ratings;

begin
  RatingDesc[1] := 'HARMLESS';
  RatingDesc[2] := 'MOSTLY';
  RatingDesc[3] := 'HARMLESS';
  RatingDesc[4] := 'POOR';
  RatingDesc[5] := 'AVERAGE';
  RatingDesc[6] := 'ABOVE';
  RatingDesc[7] := 'AVERAGE';
  RatingDesc[8] := 'COMPETENT';
  RatingDesc[9] := 'DANGEROUS';
  RatingDesc[10] := 'DEADLY';
  RatingDesc[11] := 'ELITE';
end;


{* ******************************************** *}
{* System fuctions                              *}
{* ******************************************** *}

{* =============================================*}
{* "Goat Soup" planetary description string code*}
{*  - adapted from Christian Pinder's           *}
{*  reverse engineered sources.                 *}
{* ============================================ *}

function GoatSoup(source: string; ThisSys: plansys):string;

var
  c           : char;
  rnd,len     : longinteger;
  i,x,rc      : integer;  
  r1,r2,r3,r4 : integer;
  offset      : longinteger;
  
  SoupString  : string;

begin
  SoupString := '';
  
  for i := 1 to length(source) do begin
    c := unstr(substr(source,i,1));
    case c of
      '<' : SoupString := SoupString + ToScase(ThisSys.name);    {* Planet name in Sentence case *}
      '>' : SoupString := SoupString + ToScase(ThisSys.Iname);   {* Planet name..ian             *}
      '@' : begin               
              {* Random Planet Name *}
              len := (gen_rnd_number & 3);
              for x := 0 to len do begin
                rc := (gen_rnd_number & 62);
                if x = 0  then SoupString := SoupString + substr(Urpn_pairs,rc+1,1)
                          else SoupString := SoupString + substr(Lrpn_pairs,rc+1,1); 
                SoupString := SoupString + substr(Lrpn_pairs,rc+2,1);
              end;
            end;
      ' ' : SoupString := SoupString + str(' ');
      otherwise begin
        if (ord(c) >= 129) and (ord(c) <= 164) then begin
          rnd := gen_rnd_number;
          if rnd >=  51 then r1:=1 else r1:=0;
          if rnd >=  92 then r2:=1 else r2:=0;
          if rnd >= 153 then r3:=1 else r3:=0;
          if rnd >= 204 then r4:=1 else r4:=0;
          offset := ord(c); 
          {* writeln(offset:3,' (',rnd:3,') [',1+r1+r2+r3+r4:1,'] '); *}     
          SoupString := SoupString + GoatSoup(Desc_List[offset].option[1+r1+r2+r3+r4],ThisSys);
        end;
        if (ord(c) >= 225) and (ord(c) <= 250) then SoupString := SoupString + str(c); {* a-z *} 
        if (ord(c) >= 193) and (ord(c) <= 218) then SoupString := SoupString + str(c); {* A-Z *}    
      end;
    end;
  end;
  GoatSoup := SoupString;
end;

{* ============================================ *}

procedure PriSys(ThisSys: plansys; format: integer);

begin
  case format of 
    0: begin
        writeln('System     : ', ToScase(ThisSys.name));
        writeln('Economy    : ', econnames[ThisSys.economy]);
        writeln('Government : ', govnames[ThisSys.govtype]);
        writeln('Tech Level : ', ThisSys.techlev + 1:2);
      end;
    1: begin
        write(' ',ToScase(ThisSys.name):10);
        write(' | ', ThisSys.techlev + 1:2);
        write(' | ', econnames[ThisSys.economy]:19);
        write(' | ', govnames[ThisSys.govtype]:19,' |');
      end;
    2: begin
        writeln('System      : ', ToScase(ThisSys.name));
        {* writeln('ID:         ', Ship.CurrentPlanet:3); *}
        writeln('Position    : (', ThisSys.x:3, ',', ThisSys.y:3, ')');
        writeln('Economy     : ', econnames[ThisSys.economy]);
        writeln('Government  : ', govnames[ThisSys.govtype]);
        writeln('Tech Level  : ', ThisSys.techlev + 1:2);
        writeln('Turnover    : ', ThisSys.productivity:4);
        writeln('Radius      : ', ThisSys.radius:4);
        writeln('Population  : ', ((ThisSys.population div 8) & 7):2, ' Billion');

        rnd_seed := ThisSys.goatsoupseed;
           
        writeln(GoatSoup(strc(143)+' is '+strc(151),ThisSys));
    end;
   end;
end;

{* ============================================ *}

procedure GenMarket(fluct: longinteger; ThisSys: plansys; var market: markettype);

var
  i: longinteger;
  q, product, changing: longinteger;
  
begin
  for i := 0 to lasttrade do begin
    product := ThisSys.economy * commodities[i].gradient;
    changing := fluct & commodities[i].maskbyte;
    q := commodities[i].basequant + changing - product;
    q := q & 255;
    if (q & 128) <> 0 then q := 0; {* Clip to positive 8-bit *}

    market.quantity[i] := q & 63;  {* Mask to 6 bits *}

    q := commodities[i].baseprice + changing + product;
    q := q & 255;
    market.price[i] := (q * 4);
  end;

  {* Override to force non-availability *}
  {* market.quantity[AlienItems] := 0; *}
end;

{* ============================================ *}

procedure DisplayMarket(m: markettype);

var
  i: longinteger;
  
begin
  writeln('    +--------------+------+--------+--------+');
  writeln('    | Commodity    | Price|  Avail | In Hold|');
  writeln('    +--------------+------+--------+--------+');
  for i := 0 to lasttrade do begin
    if m.quantity[i] <> 0 then begin
      write('    | ',commodities[i].name);
      write(' |', m.price[i]/10:6:1);
      write('|', m.quantity[i]:6); write(unitnames[commodities[i].units]);
      write('|');
      if Ship.Hold[i] <> 0 then write(Ship.Hold[i]:6,unitnames[commodities[i].units]:2)
                          else write('        ');
      writeln('|');
    end;
  end;
  writeln('    +--------------+------+--------+--------+');
  writeln('    | Cargo space free             |',Ship.Holdspace:6,'t |');
  writeln('    +--------------+------+--------+--------+');

end;

{* ******************************************** *}
{* BuildGalaxy and functions                    *}
{* ******************************************** *}

procedure TweakSeed(var s: seedtype);

var
  temp: longinteger;
  
begin
  {* https://www.bbcelite.com/deep_dives/twisting_the_system_seeds.html *}

  temp := (s.w0 + s.w1 + s.w2) mod 65536;
  s.w0 := s.w1;
  s.w1 := s.w2;
  s.w2 := temp;

end;

{* ============================================ *}

procedure MakeSystem(var s: seedtype; var ThisSys: plansys);

var
  pair1, pair2, pair3, pair4  : longinteger;
  p1, p2, p3, p4              : integer;

  longnameflag                : longinteger;
  ts                          : seedtype;
  lc                          : char;
  
begin
  longnameflag := s.w0 & 64;

  ThisSys.x := (s.w1 & 65280) mod 255; 
  ThisSys.y := (s.w0 & 65280) mod 255;

  ThisSys.govtype := ((s.w1 div 8) & 7);    { bit 5,4,3 }
  
  ThisSys.economy := ((s.w0 div 256) & 7);  { bit 9,9,8 }
  if (ThisSys.govtype <= 1) then
    ThisSys.economy := (ThisSys.economy ! 2);

  ThisSys.techlev := ((s.w1 div 256) & 3) + XOR(ThisSys.economy,7);
  ThisSys.techlev := ThisSys.techlev + (ThisSys.govtype div 2); 
  if odd(ThisSys.govtype) then ThisSys.techlev := ThisSys.techlev + 1;

  ThisSys.population := 4 * ThisSys.techlev + ThisSys.economy;
  ThisSys.population := ThisSys.population + ThisSys.govtype + 1;

  ThisSys.productivity := (XOR(ThisSys.economy,7) + 3) * (ThisSys.govtype + 4);
  ThisSys.productivity := ThisSys.productivity * (ThisSys.population * 8);

  ThisSys.radius := 256 * (((s.w2 div 256) & 15) + 11) + ThisSys.x;
  
  ThisSys.goatsoupseed.a := s.w1 & 255;
  ThisSys.goatsoupseed.b := s.w1 div 256;
  ThisSys.goatsoupseed.c := s.w2 & 255;
  ThisSys.goatsoupseed.d := s.w2 div 256;

  pair1 := (2 * (((s.w2 div 256) mod 32))+1);
  TweakSeed(s);
  pair2 := (2 * (((s.w2 div 256) mod 32))+1);
  TweakSeed(s); 
  pair3 := (2 * (((s.w2 div 256) mod 32))+1);
  TweakSeed(s);  
  pair4 := (2 * (((s.w2 div 256) mod 32))+1);
  TweakSeed(s);   

  p1 := pair1;
  p2 := pair2;
  p3 := pair3;
  p4 := pair4;
  
  ThisSys.name := substr(Upairs,p1,1);
  ThisSys.name := ThisSys.name + substr(Upairs,p1+1,1);
  ThisSys.name := ThisSys.name + substr(Upairs,p2,1);
  ThisSys.name := ThisSys.name + substr(Upairs,p2+1,1);
  ThisSys.name := ThisSys.name + substr(Upairs,p3,1);
  ThisSys.name := ThisSys.name + substr(Upairs,p3+1,1); 
  
  if (longnameflag <> 0) then begin
    ThisSys.name := ThisSys.name + substr(Upairs,p4,1);
    ThisSys.name := ThisSys.name + substr(Upairs,p4+1,1);
  end;

  StripOut(ThisSys.name, '.');
 
  lc := unstr(substr(ThisSys.name,length(ThisSys.name),1));
  if (lc = 'E') or (lc = 'I')
    then ThisSys.Iname := substr(ThisSys.name,1,length(ThisSys.name)-1) + 'ian'
    else ThisSys.Iname := ThisSys.name + 'ian'
end;

{* ============================================ *}

function RotateLeft(x: longinteger): longinteger;

var
  temp: longinteger;
  
begin
  { Extract the most significant bit }
  temp := x & 128;

  { Clear the most significant bit }
  x := x & 127;

  {  Shift the extracted bit to the least significant bit position *}
  temp := temp div 128; { Equivalent to temp >> 7 in C }

  { Perform left rotation and combine the bits }
  RotateLeft := (temp * 256) + (x * 2);
end;

{* ============================================ *}

function Twist(x: longinteger): longinteger;

begin
  Twist := (256 * RotateLeft(x div 256)) + RotateLeft(x mod 256);
end;

{* ============================================ *}

procedure NextGalaxy(var s: seedtype);

begin
  s.w0 := Twist(s.w0);  
  s.w1 := Twist(s.w1);  
  s.w2 := Twist(s.w2);  
end;

{* ============================================ *}

procedure BuildGalaxy(num: longinteger);

var
  newseed: seedtype;
  syscount,galcount: integer;
  
begin
  seed.w0 := base0;
  seed.w1 := base1;
  seed.w2 := base2; { Initialise seed for galaxy 1 }
  
  if num > 1 then begin 
    for galcount := 1 to num - 1 do begin
      NextGalaxy(seed);
    end;
  end;  
  { Put galaxy data into array of structures }
  for syscount := 0 to galsize - 1 do begin
    {* Ship.CurrentPlanet := syscount; *}
    MakeSystem(seed,galaxy[syscount]);
  end;
end;

{* ******************************************** *}
{* Game Procedures                              *}
{* ******************************************** *}

function distance(a,b:plansys):longinteger;

var
  r : longreal;
  
begin
  r := 4 * Sqrt(Sqr(a.x - b.x) + Sqr(a.y - b.y) / 4);
  distance := trunc(r);
end;

{* ============================================ *}

function matchsys(pname:string): integer;

var
  syscount  : integer;
  p         : integer;
  d         : longinteger;
  
begin
  p := Ship.CurrentPlanet;
  d := 9999;

  for syscount := 0 to galsizem do begin
    if pname = galaxy[syscount].name then begin
      if distance(galaxy[syscount], galaxy[Ship.CurrentPlanet]) < d then begin
        d := distance(galaxy[syscount], galaxy[Ship.CurrentPlanet]);
        p := syscount;
      end;
    end;
  end;

  matchsys := p;
end;

{* ============================================ *}

procedure dosell(selling: string; var m: markettype);

var
  i, b            : longinteger;
  amountin        : string;
  amount          : integer;
  ok,trade_ok     : boolean;

begin
  ok := false;
  trade_ok := false;
  
  for b := 0 to lasttrade do begin
    if index(ToUpper(commodities[b].name), selling) = 1 then begin
      i := b;
      ok := true;
    end;
  end;
  {* If the selling item is found *}
  writeln('    +--------------+------+--------+');
  if ok then begin 
    writeln('    | Commodity    | Price| In Hold|');
    writeln('    +--------------+------+--------+');
    {* If the player has the item to sell *}
    if Ship.Hold[i] <> 0 then begin
      write('    | ', commodities[i].name);
      write(' |', m.price[i]/10:6:1);
      write('|', Ship.Hold[i]:6);
      write(unitnames[commodities[i].units]:2);
      write('| > '); 
      readln(amountin);
      StrToInt(amountin,amount,normal,ok);
      if ok and (amount <= 0) then ok := not ok;    {* ignore blank or zero       *}
      if ok then begin
        if amount <= Ship.Hold[i] then begin         {* Is there that much ?       *}
          if commodities[i].units = tonnes then Ship.Holdspace := Ship.Holdspace + amount;
          Ship.Hold[i] := Ship.Hold[i] - amount;
          m.quantity[i] := m.quantity[i] + amount;
          Ship.Credit := Ship.Credit + (amount * m.price[i]);
          write( '|         ==> ',(amount * m.price[i])/10:6:1,'C');
          write(amount:6,unitnames[commodities[i].units]);
          writeln('|');
          if commodities[i].legal = false then Ship.LegalStatus := LegalOFFENDER;

          trade_ok := true;
        end
        else begin
          writeln('    |      You don''t have that much|');
        end;
      end;
    end
    else begin 
      writeln('    |           You don''t have that|');
    end;
  end
  else begin  
    writeln('    |              No trade in that|');
  end;
  writeln('    +--------------+------+--------+');
  if trade_ok then begin
    writeln('    | Cargo space free    |',Ship.Holdspace:6,'t |');
    writeln('    +--------------+------+--------+');
  end;
end;

{* ============================================ *}

procedure dosell_bylist(var m:markettype);

var
  i         : longinteger;
  amountin  : string;
  amount    : integer;
  ok        : boolean;
  
begin
  writeln('    +--------------+------+--------+');
  writeln('    | Commodity    | Price| In Hold|');
  writeln('    +--------------+------+--------+');
  for i := 0 to lasttrade do begin
    if Ship.Hold[i] <> 0 then begin
      write('    | ', commodities[i].name);
      write(' |', m.price[i]/10:6:1);
      write('|', Ship.Hold[i]:6);
      write(unitnames[commodities[i].units]);
      write('| > '); 
      readln(amountin);
      StrToInt(amountin,amount,normal,ok);
      
      if ok and (amount <= 0) then ok := not ok; {* ignore blank or zero *}
      
      if ok then begin
        if amount <= Ship.Hold[i] then begin
          Ship.Hold[i] := Ship.Hold[i] - amount;
          m.quantity[i] := m.quantity[i] + amount;
          Ship.Holdspace := Ship.Holdspace + amount;
          Ship.Credit := Ship.Credit + (amount * m.price[i]);
          write( '    |           ==> ',(amount * m.price[i])/10:6:1,'C');
          write(amount:6,unitnames[commodities[i].units]);
          writeln('|');
          if commodities[i].legal = false then Ship.LegalStatus := LegalOFFENDER;
        end
        else begin 
          writeln('    |      You don''t have that much|');
        end;
      end;
    end;
  end; {* end of for loop *}
  writeln('    +--------------+------+--------+');
  writeln('    | Cargo space free    |',Ship.Holdspace:6,'t |');
  writeln('    +--------------+------+--------+');
end; {* end of procedure dosell_bylist *}

{* ============================================ *}

procedure dobuy(buying:string; var m:markettype);

var
  i,b             : longinteger;
  amountin        : string;
  amount          : integer;
  newload         : integer;
  ok,trade_ok     : boolean;
  
begin
  ok := false;
  trade_ok := false;
  
  for b := 0 to lasttrade do begin
    if index(ToUpper(commodities[b].name),buying) = 1 then begin
      i := b;
      ok := true;
    end;
  end;
  writeln('    +--------------+------+--------+--------+');
  if ok then begin
  writeln('    | Commodity    | Price|  Avail | In Hold|');
  writeln('    +--------------+------+--------+--------+');
    if m.quantity[i] <> 0 then begin
      write('    | ',commodities[i].name);
      write(' |', m.price[i]/10:6:1);
      write('|', m.quantity[i]:6);
      write(unitnames[commodities[i].units]);
      write('|', Ship.Hold[i]:6,unitnames[commodities[i].units]:2,'| > ');
      readln(amountin);
      StrToInt(amountin,amount,normal,ok);
      if ok and (amount <= 0) then ok := not ok;                    {* ignore blank or zero       *}
      if ok then begin
        if amount <= m.quantity[i] then begin                       {* Is there that much ?       *}
          if Ship.Credit - (m.price[i] * amount) >= 0 then begin           {* Can we aford it?           *}
            if commodities[i].units = tonnes then newload := amount {* Don't fret the small stuff *}
                                             else newload := 0;
            if Ship.Holdspace - newload >= 0 then begin                  {* Have we got space for it? *}
              Ship.Hold[i] := amount;
              m.quantity[i] := m.quantity[i] - amount;
              Ship.Holdspace := Ship.Holdspace - newload;
              Ship.Credit := Ship.Credit - (amount * m.price[i]);
              write('    |           <== ',(amount * m.price[i])/10:6:1,'C');
              write(amount:6,unitnames[commodities[i].units]);
              writeln('         |');
              if commodities[i].legal = false then Ship.LegalStatus := LegalOFFENDER;
              trade_ok := true;
            end
            else begin
              writeln('    |              Insufficent space in hold|');
            end;
          end
          else begin
             writeln('    |                     Insufficent credit|');
          end;
        end
        else begin
          writeln('    |                That much not available|');
        end;
      end;
    end
    else begin               
      writeln('    |                        Not traded here|');
    end;
  end
  else begin
    writeln('    |                             Not traded|');
  end;
  writeln('    +--------------+------+--------+--------+');
  if trade_ok then begin
    writeln('    | Cargo space free             |',Ship.Holdspace:6,'t |');
    writeln('    +--------------+------+--------+--------+');
  end;
end;

{* ============================================ *}

procedure dobuy_bylist(var m:markettype);

var
  i           : longinteger;
  amountin    : string;
  amount      : integer;
  newload     : integer;
  ok          : boolean;

begin
  writeln('    +--------------+------+--------+--------+');
  writeln('    | Commodity    | Price|  Avail | In Hold|');
  writeln('    +--------------+------+--------+--------+');
  for i := 0 to lasttrade do begin
    if m.quantity[i] <> 0 then begin
      write('    | ',commodities[i].name);
      write(' |', m.price[i]/10:6:1);
      write('|', m.quantity[i]:6);
      write(unitnames[commodities[i].units]);
      write('|', Ship.Hold[i]:6,unitnames[commodities[i].units]:2,'| > '); 
      readln(amountin);
      StrToInt(amountin,amount,normal,ok);
      if ok and (amount <= 0) then ok := not ok;                    {* ignore blank or zero       *}
      if ok then begin
        if amount <= m.quantity[i] then begin                       {* Is there that much ?       *}
          if Ship.Credit - (m.price[i] * amount) >= 0 then begin           {* Can we aford it?           *}
            if commodities[i].units = tonnes then newload := amount {* Don't fret the small stuff *}
                                             else newload := 0;
            if Ship.Holdspace - newload >= 0 then begin                  {* Have we got space for it? *}
              Ship.Hold[i] := amount;
              m.quantity[i] := m.quantity[i] - amount;
              Ship.Holdspace := Ship.Holdspace - newload;
              Ship.Credit := Ship.Credit - (amount * m.price[i]);
              write('    |           <== ',(amount * m.price[i])/10:6:1,'C');
              write(amount:6,unitnames[commodities[i].units]);
              writeln('         |');
              if commodities[i].legal = false then Ship.LegalStatus := LegalOFFENDER;
            end
            else begin
              writeln('    |              Insufficent space in hold|');
            end;
          end
          else begin
             writeln('    |                     Insufficent credit|');
          end;
        end
        else begin
          writeln('    |                That much not available|');
        end;
      end;
    end;
  end; {* for *}
  writeln('    +--------------+------+--------+--------+');
  writeln('    | Cargo space free             |',Ship.Holdspace:6,'t |');
  writeln('    +--------------+------+--------+--------+');
end;

{* ============================================ *}

procedure dofuel(amount:string);

const
  cost = 2;
  
var
  toint   : integer;
  addfuel : integer;
  pay     : integer;
  ok      : boolean;
  
begin  
  if index(amount,'.') <> 0 then begin
    {* make sure only 1 digit after the . else it throws off multiply by 9 *}
    if length(amount) > index(amount,'.')+1 then amount := substr(amount,1,length(amount)-1);
    {* is it .0? Nope. Not having that  *}
    if (amount = '.0') or (amount = '0.0') then amount := str('0');
    {* Is it JUST '.'  Not having that  *}
    if amount = str('.') then amount := str('!');
  end;
  
  if amount = str('0') then ok := false else StrToInt(amount,toint,DoByTen,ok);
  
  if ok then begin
    if toint = 0 then addfuel := Ship.Fueltank - Ship.Fuel else addfuel := toint;
    pay := addfuel * cost;
    if addfuel + Ship.Fuel <= Ship.Fueltank then begin
      if Ship.Credit - pay <= 0 then begin
          writeln('    Insuffient credit.');
        end
        else begin
          Ship.Fuel := Ship.Fuel + addfuel;
          writeln('    ',addfuel/10:1:1,'LY of fuel ',pay/10:1:1,'C');
          Ship.Credit := Ship.Credit - pay;
      end;
    end
    else begin
        writeln('    You cannot hold that much fuel.');
    end;
  end
  else begin
    writeln('    No fuel purchased.');
  end; (* if *)
end; (* begin *)

{* ============================================ *}

procedure doGalaxyMap;

var
  map     : array[1..21,1..71] of integer;
  i,x,y   : integer;
  dx,dy   : integer;

begin  

  for y := 1 to 21 do for x := 1 to 71 do map[y,x] := 0;
  
  for i := 0 to 255 do begin
    {* if InRange(galaxy[i].x,1,71) and InRange(galaxy[i].y,1,20)  then begin
      map[galaxy[i].y,galaxy[i].x] := true;
      writeln('.',galaxy[i].y,galaxy[i].x);
    end; *}
    dx := Scale(galaxy[i].x,0,255,1,71);
    dy := Scale(galaxy[i].y,0,255,1,21);
    if i = Ship.CurrentPlanet then map[dy,dx] := 99 else map[dy,dx] := map[dy,dx] + 1;
  end;
  writeln('    +--[Galaxy Number ',Ship.CurrentGalaxy:1,']----------------------------------------------------+');
  for y := 1 to 21 do begin
    write('    |');
    for x := 1 to 71 do begin
      case map[y,x] of
        99 : write('#');
        1  : write('.');
        2  : write(':');
        0  : write(' ');
       end;
    end;
    writeln('|');
  end;
  writeln('    +-----------------------------------------------------------------------+');  
end;

{* ============================================ *}

procedure doLocalMap;

var
  map       : array[-10..10,-10..10] of integer;
  i         : integer;
  dx,dy     : longinteger;
  d         : longinteger;
  mapout    : string;
  plook     : string;
  
begin
  for dx := -10 to 10 do for dy := -10 to 10 do map[dx,dy] := 0; 
  map[0,0] := Ship.CurrentPlanet;
  
  for i := 0 to galsizem do begin
    d := distance(galaxy[i], galaxy[Ship.CurrentPlanet]);
    if d <= 100 then begin
      dx := (galaxy[i].x - galaxy[Ship.CurrentPlanet].x) div 3;
      dy := (galaxy[i].y - galaxy[Ship.CurrentPlanet].y) div 3;
      map[dx,dy] := i;
      {* writeln(galaxy[i].x,dx,galaxy[i].y,dy,galaxy[i].name); *}
    end;
  end;
                   
  write('    +--[Local To ',ToUpper(galaxy[Ship.CurrentPlanet].name):8);
  writeln(']--------------------------------------------------+');
  for dy := 10 downto -10 do begin
    mapout := '';
    for dx := -10 to 10 do begin
      if map[dx,dy] <> 0 then begin
        if (dx=0) and (dy=0) then 
          mapout := mapout + '# ' + galaxy[Ship.CurrentPlanet].name+str(' ')
        else begin
          d := distance(galaxy[map[dx,dy]], galaxy[Ship.CurrentPlanet]);
          if d <= Ship.Fuel then plook := str('*')
                       else plook := str('.');
          if dx < 0 then plook := ToScase(galaxy[map[dx,dy]].name) + str(' ') + plook
                    else plook := plook + str(' ') + ToScase(galaxy[map[dx,dy]].name);
          mapout := mapout + plook;
        end;
      end
      else
        mapout := mapout + '   '   
    end;
    if length(mapout) < 71 then repeat mapout := mapout + str(' ') until length(mapout) = 71;
   
    writeln('    |',substr(mapout,1,71),'|'); 
  end;
  writeln('    +-----------------------------------------------------------------------+');
end;

{* ============================================ *}

procedure doLocalList;

var
  i : integer;
  d : longinteger;
  
begin
  writeln('    +-+------------+----+---------------------+---------------------+-------+'); 
  writeln('    | | System     | TL |             Economy |          Government |    LY |');
  writeln('    +-+------------+----+---------------------+---------------------+-------+');
  for i := 0 to galsizem do begin
    d := distance(galaxy[i], galaxy[Ship.CurrentPlanet]);
    if d <= Ship.Fueltank then begin
      write('    |');
      if d <= Ship.Fuel then write('*')
                        else write('.');
      write('|');
      prisys(galaxy[i], coldesc);
      writeln('   ',d/10:1:1, ' |');
    end; 
  end;
  writeln('    +-+------------+----+---------------------+---------------------+-------+');
end;

{* ============================================ *}

procedure dojump(pname:string);

var
  d    : longinteger;
  dest : integer;
  
begin
  if pname <> '' then begin
    dest := matchsys(pname);
    if dest = Ship.CurrentPlanet then 
      writeln('    Bad Jump')
    else begin
      d := distance(galaxy[dest], galaxy[Ship.CurrentPlanet]);
      if d > Ship.Fuel then 
        writeln('    Jump too far')
      else begin
        Ship.Fuel := Ship.Fuel - d;
        Ship.CurrentPlanet := dest;
        prisys(galaxy[Ship.CurrentPlanet], shortdesc);
        GenMarket(myrand & 255,galaxy[Ship.CurrentPlanet],localmarket); 
      end;
    end;
  end
  else begin
    writeln('    No destination given.');
    doLocalList;
  end;
end;

{* ============================================ *}

procedure dosneak(pname:string);

var
  prejump : longinteger;
  
begin
  prejump := Ship.Fuel;
  Ship.Fuel := 999;
  dojump(pname);
  Ship.Fuel := prejump;
end;

{* ============================================ *}

procedure doinfo(pname:string);

var
  i,ShowSys : integer;
  found     : boolean;
  
begin
  found := false;
  if pname = '' then begin
    ShowSys := Ship.CurrentPlanet;
    found := true;
  end
  else begin
    pname := ToUpper(pname);
    for i := 0 to galsizem do begin
      if galaxy[i].Name = pname then begin
        ShowSys := i;
        found := true;
      end;
    end;
  end;

  if found then prisys(galaxy[ShowSys],fulldesc)
           else writeln('    Planet ',pname,' could not be found.');

end;

{* ============================================ *}

procedure dogalhyp;

var
  i : integer;
  
begin
  Ship.CurrentGalaxy := Ship.CurrentGalaxy + 1;
  if Ship.CurrentGalaxy = 9 then Ship.CurrentGalaxy := 1;
  write('    Jumping to ');
  i := Ship.CurrentPlanet;
  buildgalaxy(Ship.CurrentGalaxy);
  writeln('    Galaxy ', Ship.CurrentGalaxy:1);
  Ship.CurrentPlanet := i;
  prisys(galaxy[Ship.CurrentPlanet], shortdesc);
  writeln;
end;

{* ============================================ *}

procedure doUpgrades;

var
  i     : integer;
  upYN  : string;
  
begin

  writeln('    +---------------------+--------+');
  writeln('    | Available Upgrades  |  Price |');
  writeln('    +---------------------+--------+');
          
  for i := 2 to NumUpgrades do begin
    if (Upgrades[i].TechLevel <= (galaxy[Ship.CurrentPlanet].techlev+1)) and (Ship.Upgraded[i] = false) then begin
      write('    | ',Upgrades[i].Name, ' | ',Upgrades[i].Price/10:6:1, ' | >' );
      readln(upYN);
      if ToUpper(upYN) = str('Y') then begin
        if Ship.Credit - Upgrades[i].price > 0 then begin
           writeln('    |        <== ',Upgrades[i].Price/10:6:1, 'C Installed |');
           Ship.Upgraded[i] := true;
           if i = UPG_CARGO then begin 
              Ship.MaxHold := LargeHold; 
              Ship.Holdspace := Ship.Holdspace + (LargeHold-RegularHold)
           end;
           if i = UPG_FTANK then Ship.Fueltank  := LargeFuelTank;        
           Ship.Credit := Ship.Credit - Upgrades[i].Price;
        end
        else begin
           writeln('    |            Insufficent credit|')
        end;
      end;
    end;
  end;
  writeln('    +---------------------+--------+');
end;

{* ============================================ *}

procedure doCobra(arg:string);

var
  i       : integer;
  
begin;
  writeln('     COMMANDER ',Ship.Name);
  writeln('     Current System  : ',galaxy[Ship.CurrentPlanet].name);
  writeln('     Fuel            : ',Ship.Fuel/10:1:1,'LY');
  writeln('     Credit          : ',Ship.Credit/10:1:1,'C');
  writeln('     Status          : ',LegalDesc[Ship.LegalStatus]);
  
  if Ship.Holdspace <> Ship.MaxHold  then begin
    writeln('    +------------------+--------+');
    writeln('    | Commodity        | In Hold|');
    writeln('    +------------------+--------+');
    for i := 0 to lasttrade do begin
      if Ship.Hold[i] <> 0 then begin
        write('    | ', commodities[i].name);
        write('     |', Ship.Hold[i]:6);
        write(unitnames[commodities[i].units]);
        writeln('|');
      end;
    end;
  end;
  
  writeln('    +------------------+--------+');
  writeln('    | Cargo space free |',Ship.Holdspace:6,'t |');
  writeln('    +------------------+--------+');
  
  for i := 2 to NumUpgrades do begin
    if Ship.Upgraded[i] then writeln('    ',Upgrades[i].Name);
  end;
end;

{* ============================================ *}

procedure parse(instring:string; var cmd:char; var argument:string);

{* Parse into a single leading character and a possible second word *}

var
  i : integer;
  
begin
  if instring <> '' then begin
    instring := DblSpaceStrip(instring);
    i := index(instring,' ');
    if i = 0 then begin
      cmd := unstr(instring);
      argument := '';
    end
    else begin
      cmd := unstr(substr(instring,1,1));
      argument := substr(instring,i+1,length(instring)-i);
    end;
  end
  else begin
    cmd := '.';
    argument := '';
  end;
end;

{* ============================================ *}

procedure doSave(ShipInfo: ShipType);

const
  maxslot   = 10;
  
var
  DataFile    : file of SaveData;
  i,slot      : integer;
  SaveSlot    : array[1..10] of SaveData;
  
begin
  slot := 0;
    
  if File_Exists(SaveDataFileName) then begin 
    reset(DataFile,SaveDataFileName);
    while not eof(DataFile) do begin
      slot := slot + 1;
      read(DataFile,SaveSlot[slot]);
    end;
    close(DataFile);
  end;
  
  if slot+1 < maxslot then begin
    slot := slot + 1;
  end
  else begin
    for slot := 1 to 9 do begin
      SaveSlot[slot] := SaveSlot[slot+1];
    end;
    slot := 10;
  end;
  
  with SaveSlot[slot] do begin
    ShipSaveData  := ShipInfo;
    DateSaved     := DATE$;
  end;
  
  rewrite(DataFile,SaveDataFileName);
  for i := 1 to slot do begin
    write(DataFile,SaveSlot[i]);
  end;
  close(DataFile);

  writeln('    +---+----------+--------------------+');
  writeln('    |   | Planet   | Date Saved         |');
  writeln('    +---+----------+--------------------+');
  for i := slot downto 1 do begin
    cv$fdv(SaveSlot[i].DateSaved,day_of_week, formatted_date);
    writeln('    | ',strc(175+i),' | ',
                galaxy[SaveSlot[i].ShipSaveData.CurrentPlanet].name:8,
                ' | ', substr(formatted_date,1,18),' |');
  end;
  writeln('    +---+----------+--------------------+');

end;

{* ============================================ *}

procedure doLoad(var ShipData: ShipType);

const
  maxslot   = 10;
  
var
  DataFile    : file of SaveData;
  i,slot      : integer;
  SaveSlot    : array[1..10] of SaveData;
  getslot     : char;
  
begin
  if File_Exists(SaveDataFileName) then begin
    reset(DataFile, SaveDataFileName);
    slot := 0;
    while not eof(DataFile) do begin
      slot := slot + 1;
      read(DataFile, SaveSlot[slot]);  
    end;
    close(DataFile);    

    writeln('    +----------+--------------------+---+');
    writeln('    | Planet   | Date Saved         |   |');
    writeln('    +----------+--------------------+---+');
    for i := slot downto 1 do begin
      cv$fdv(SaveSlot[i].DateSaved,day_of_week, formatted_date);
      writeln('    | ',galaxy[SaveSlot[i].ShipSaveData.CurrentPlanet].name:8,
                 ' | ',substr(formatted_date,1,18),' | ',strc(175+i),' | ');
    end;
    writeln('    +----------+--------------------+---+');
    write(  '                    Load Saved Slot > ');
    readln(getslot);
    
    if InRange(ord(getslot),176,185) then begin
      slot := ord(getslot) - 175;
      cv$fdv(SaveSlot[slot].DateSaved,day_of_week, formatted_date);
      writeln('   Restoring ',substr(formatted_date,1,18));
      ShipData := SaveSlot[slot].ShipSaveData;
      buildgalaxy(ShipData.CurrentGalaxy);
      GenMarket(myrand & 255,galaxy[ShipData.CurrentPlanet],localmarket); 
    end
    else begin
      writeln('    Not a valid slot.');
    end;
  end
  else begin
    writeln('Data File ',SaveDataFileName,' not found.');
  end;
  
end;

{* ============================================ *}

procedure doSaveLoadUI(argument:string);

var
  getcommand  : string;
  action      : char;
  arg         : string;
  cname       : string;
  FileName    : string;
  code        : integer;
  
begin
  cname := ToSCase(Ship.Name);

  if argument = '' then begin
    write('   [S]ave or [L]oad Commander ',cname,' ? ');
    readln(getcommand);
    parse(getcommand,action,arg);
  end
  else begin
    action := unstr(substr(argument,1,1));
  end;
  
  case action of
    'S'  : doSave(Ship);
    'L'  : doLoad(Ship);
    '.'  : {* do nothing *}
  otherwise
    writeln('   Bad command (',getcommand,')')
  end;
end;

{* ============================================ *}

procedure dohelp;

begin
  writeln('Commands are:');
  writeln('   [B]uy    tradegood       Buy cargo');
  writeln('   [S]ell   tradegood       Sell cargo');
  writeln('   [F]uel   amount          Buy amount LY of fuel');
  writeln('   [J]ump   planetname      Limited by fuel');
  {( writeln('[X]      planetname      Any distance - no fuel cost'); *}
  writeln('   [I]nfo   planetname      Shows info on system');
  writeln('   [P]rices                 Shows local market prices');
  writeln('   [L]ocal                  Systems within 7 light years');
  writeln('   [M]ap                    Map of local systems');
  writeln('   [G]alaxy Map             Map of current galaxy');
  if Ship.Upgraded[UPG_GALHYP] then writeln('    [W]arp                   Warp to next galaxy');
  writeln('   [U]pgrade                Upgade ship');
  writeln('   [C]obra Mk III           Show my Cobra Mk III');
  writeln('   [@]                      Save and Load');
  writeln('   [Q]uit or ^P             Exit');
  writeln('   [?]                      Display this text');
  writeln;
end;

{* ============================================ *}

procedure DoUI;

var
  getcommand  : string;
  action      : char;
  arg         : string;
  
begin
  write('[',galaxy[Ship.CurrentPlanet].name,'] ');
  write('Fuel ',Ship.Fuel/10:1:1,'LY | ');
  write('Credit ',Ship.Credit/10:1:1,'C > ');

  readln(getcommand);
  parse(getcommand,action,arg);

  case action of
    'B'  : if arg = '' then dobuy_bylist(localmarket) else dobuy(arg,localmarket);
    'S'  : if arg = '' then dosell_bylist(localmarket) else dosell(arg,localmarket);
    'F'  : if Ship.Fuel = Ship.Fueltank then writeln('    Fuel already full') else dofuel(arg);
    'J'  : dojump(arg);
    'X'  : dosneak(arg);
    'W'  : if Ship.Upgraded[UPG_GALHYP] then dogalhyp else writeln('   Galactic HyperWarp Not Installed');
    'I'  : doinfo(arg);
    'P'  : displaymarket(localmarket);
    'L'  : doLocalList;
    'M'  : doLocalMap;
    'G'  : doGalaxyMap;
    'U'  : doUpgrades;
    'C'  : doCobra(arg);
    '@'  : doSaveLoadUI(arg);
    '?'  : dohelp;
    'Q'  : Finished := true;
    '.'  : {* do nothing *}
  otherwise
    writeln('   Bad command (',getcommand,')')
  end;
end;

{* ******************************************** *}
{* The Game                                     *}
{* ******************************************** *}


begin

  reset(Input,'-interactive');
  writeln('[PRIME ELITE Rev. ',version,' Copyright (c) 2024]');
  writeln('[Serial #ABC1-DEFG23-HI3J (PRIME COMPUTER)]');
  
  CV$FDV(date$,day_of_week, formatted_date);
  writeln('[',formatted_date,']');

  {* Initialise lookup tables *}
  INIT_Pairs;
  INIT_PlanetDesc_List;
  INIT_Commodities;
  INIT_Govnames;
  INIT_Econnames;
  INIT_Upgrades;
  INIT_Legal;
  INIT_Ratings;

  mysrand(12345);   {* Ensure random repeats *}
    
  {* Let's start at the very beginning *}
  buildgalaxy(StartingGalaxy);

  with Ship do begin
    CurrentGalaxy := StartingGalaxy;
    CurrentPlanet := NumForLave;
    Credit        := 1000;     {* User only sees this divided by 10 *}
    Holdspace     := RegularHold;
    MaxHold       := RegularHold;
    Fueltank      := RegularFuelTank;
    Fuel          := RegularFuelTank;
    Missiles      := 4;
    for i := 0 to LargeHold do Hold[i] := 0;
    for i := 2 to NumUpgrades do Upgraded[i] := false;
    LegalStatus   := LegalCLEAN;
    Rating        := 1;
    Name          := 'JAMESON';
  end;
  
  GenMarket(0,galaxy[Ship.CurrentPlanet],localmarket);
  
  writeln;
  writeln('Welcome to Text Elite on Prime.');
  writeln;
  dohelp;
  finished  := false;

  repeat
    DoUI;
  until finished;

end.
