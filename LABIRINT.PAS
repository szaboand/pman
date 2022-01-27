

var pal:array[0..768] of byte;
    nul:array[0..768] of byte;

procedure setpalette(e,f:word;t:pointer);
begin
asm push es;push ax;push bx;push cx;push dx;
    mov ax,$1012;mov bx,e;mov cx,f;les dx,t;int $10;
    pop dx;pop cx;pop bx;pop ax;pop es;end;
end;

procedure getpalette(e,f:word;t:pointer);
begin
asm push es;push ax;push bx;push cx;push dx;
    mov ax,$1017;mov bx,e;mov cx,f;les dx,t;int $10;
    pop dx;pop cx;pop bx;pop ax;pop es;end;
end;

Procedure SetRGB(Palnum,Red,Green,Blue:byte);Assembler;
  Asm
   mov  dx,$3c8
   mov  al,palnum;out  dx,al
   inc  dx;
   mov  al,red;   out  dx,al
   mov  al,green; out  dx,al
   mov  al,blue;  out  dx,al
  End;

  Procedure GetRGB(Palnum:byte;var Red,Green,Blue:byte);
var r,g,b:byte;
begin
  Asm
   mov  dx,$3c7
   mov  al,palnum;out  dx,al
   mov dx,$03c9;
   in al,dx;mov  r,al;
   in al,dx;mov  g,al;
   in al,dx;mov  b,al;
  End;
red:=r;green:=g;blue:=b;
end;

Procedure Hatter;
var i,j:word;
begin
for i:=0 to 199 do for j:=0 to 319 do putpixel(j,i,255);
end;

procedure Brick(x,y:word);
const szeles=4;kszin=65;
var i,j:word;k:byte;
begin
k:=4;
for i:=0 to szeles do begin putpixel(y+i,x,kszin);putpixel(y+i,x+szeles,kszin);end;
for i:=0 to szeles do begin putpixel(y,x+i,kszin);putpixel(y+szeles,x+i,kszin);end;
for i:=1 to szeles-1 do
    for j:=1 to szeles-1 do
        begin putpixel(y+i,x+j,k);if k=0 then k:=4 else k:=0;end;
end;

procedure keret(x1,y1,x2,y2:word);
var i,j:word;
begin
i:=y1;repeat brick(x1,i);brick(x2,i);i:=i+4;until i>y2;
i:=x1;repeat brick(i,y1);brick(i,y2);i:=i+4;until i>x2;
end;

procedure ajto1(x,y:word;szin,szeles:byte);
var i,j:word;
begin
for i:=0 to szeles do for j:=0 to 2*16-2 do putpixel(j+x,y+i,szin);
end;

procedure ajto2(x,y:word;szin,szeles:byte);
var i,j:word;
begin
y:=y+1;
for i:=0 to szeles do for j:=0 to 2*16-2 do putpixel(i+x,y+j,szin);
end;

procedure labirintus;
const szeles=22;
var i1,j1,i2,j2:word;
begin
for i1:=0 to 768 do nul[i1]:=0;
setrgb(255,8,8,16); {hatter}
setrgb(65,1,1,1);   { fal }
setrgb(40,63,63,63); {pont}
setrgb(250,63,63,0);setrgb(251,63,0,0);setrgb(252,0,63,0);setrgb(253,0,0,63); { Bonus szinek }
setrgb(254,10,10,20); { Felirat }
getpalette(0,256,@pal);
setpalette(0,256,@nul);
hatter;
{setcolor(254);
ouTtextxy(9,10, ' S  Z  A  B  O       A  N  D  R  A  S');
outtextxy(9,185,' P  A  C  K  M  A  N    1  9  9  5  '+CHR(39));}
i1:=0;j1:=0;i2:=196;j2:=316;
repeat
      keret(i1,j1,i2,j2);
      i1:=i1+szeles;i2:=i2-szeles;
      j2:=j2-szeles;j1:=j1+szeles;
until i1>100;
i1:=10;
repeat
      j1:=10;
      repeat
      putpixel(j1,i1,40);
      j1:=j1+23;
      until j1>310;
      i1:=i1+22;
until i1>190;
ajto1(143,22,255,4);ajto1(143,196-22,255,4);ajto1(143,66,255,4);ajto1(143,196-66,255,4);
ajto1(81,44,255,4);ajto1(209,44,255,4);ajto1(81,196-44,255,4);ajto1(209,196-44,255,4);
ajto1(142-33,88,255,4);ajto1(144+33,196-88,255,4);
ajto2(22,78,255,4);ajto2(316-22,78,255,4);
ajto2(316,28,255,3);ajto2(0,28,255,4);
ajto2(316,136,255,3);ajto2(0,136,255,4);
{ajto1(157,197,54,3);
for i1:=159 to 185 do putpixel(i1,198,4);}
setpalette(0,256,@pal);
end;
