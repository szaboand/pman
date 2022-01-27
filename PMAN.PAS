uses dos;

 Type SpriteType = record
                  PicPos : word;
                  Shapes  : word; { 2  }
                  Apic:word;      { 4  }
                  Bpic:word;      { 6  }
                  OldPicPos:word; { 8  }
                  UtkozesFigyeles:byte;   { 10 }
                  VegzetesUtkozes:byte;   { 11 }
                  Animacioszam: word;   { 12 }
                  AnimacioMut:  word;    { 14 }
                  AnimacioTime: word;    { 16 }
                  AnimacioCount: word;   { 18 }
                  AnimacioCircle: word;   { 20 }
                  AS: array [1..16] of byte;  { 22 }
                  Xseb,Yseb:word;
                  palya:array[1..100] of byte;
                  phossz:array[0..100] of word;
                  pmut:byte;ptime:word;
                  end;

const InAcScr     :    word   = $0000;
      InAcSeg     :    word   = $a000;
      OrgPicSeg   :    word   = $a7d0;
      SpriteOff   :    word   = $bb80;
      Act         :    word   = $0000;
      SegA        :    word   = $a000;
      SpriteNum               = 12;
      SpriteSize              = sizeof(SpriteType);
      SpriteSizeT :    word   = sizeof(SpriteType);

      PixelPos : Array [0..3] of byte = ($11,$22,$44,$88);

      cx   : word = 0;
      cy   : word = 0;
      JoyX : word = 0;
      JoyY : word = 0;

var
      Shapes :   array [0..4*2048-1] of byte;
      Masks  :   array [0..4*2560] of byte;

      Sprite :   array [1..SpriteNum] of SpriteType;
      r0,r1:word; r2,r3:byte;

      Ktb   : array[0..127] of boolean; { Billentyzet lenyom s t bl zat }
      oldKey : procedure;

      pscore,score,bscore:word;
      KILEP:BOOLEAN;

      JoyButton:byte;

 Procedure KeyIRQ;Assembler;
  Asm
   push    DS               { A haszn lt regiszterek elment‚se }
   push    ax
   push    bx
   push    cx
   mov     ax,SEG Ktb       { Inicializ l sok }
   mov     DS,ax
   xor     bh,bh            { BH = 00 }
   mov     cl,bh            { CL = 00 }
   in      al,60H           { A billenty SCAN k¢d beolvas sa }
   mov     bl,al            { BL = k¢d }
   and     bl,7fH           { A lenyom s/felenged‚s bit kimaszkol sa }
   shl     al,1             { A lenyom s/felenged‚s bit a Cy-be      }
   cmc                      { Neg l s }
   adc     cl,00            { T rol s a t bl zatban }
   mov     [bx+OFFSET Ktb],cl
   in      al,61H           { A megszak¡t s csatorna vissza ll¡t sa  }
   mov     ah,al
   or      al,80H
   out     61H,al           { billentyzet "data acknowledge" jelz‚s }
   mov     al,ah
   nop                      { Kev‚s v rakoz s (soros adatkikld‚s)   }
   nop
   nop
   out     61H,al
   cli
   mov     al,20H           { 8259 "megszak¡t s v‚ge" jelz‚s }
   out     20H,al
   sti
   pop     cx               { Regiszterek vissza a veremb”l }
   pop     bx
   pop     ax
   pop     DS
   iret                     { Megszak¡t s v‚ge }
  End;

 Procedure ClearScreen; Assembler;
  Asm
     mov   dx,03c4h
     mov   ax,0f02h             { Minden bitplane-t ¡r sra enged‚lyeznk  }
     out   dx,ax
     mov   Ax,$a000;
     mov   ES,AX           { ES:DI mutatja a c‚lc¡met                }
     xor   ax,ax                { Null kat kell kivinni a mem¢ri ba       }
     mov   di,ax
     mov   cx,32768             { 32768 word, azaz 65536 b jt kinull z sa }
     cld
     rep stosw                  { Kinull zzuk a videomem¢ri t             }
  End;



Procedure _320x200; Assembler;
asm
     mov   ax,0013h
     int   10h
     mov   dx,03D4h
     mov   ax,0014h
     out   dx,ax
     mov   ax,0e317h
     out   dx,ax
     mov   dx,03C4h
     mov   ax,0604h
     out   dx,ax
     call clearscreen
end;

 Procedure Convert_Datas(var Source; DestSeg,Bnum:word);Assembler;
  Asm
   push  ds
   push  es

   lds   si,Source      { DS:SI a forr sadatokra mutat }
   mov   ES,DestSeg
   xor   di,di          { ES:DI a videomem¢ri ra mutat }
   cld
   mov   dx,03c4h       { A plane-maszk regiszter lesz haszn lva }
   mov   bx,Bnum        { Ennyi BOB-ot kell  tkonvert lni, de a BH nulla ! }

@put_all:               { A maszk el” ll¡t sa a BH-ban t”rt‚nik !! }
   mov   ax,0102h       { Kezd‚s a 01-es bitpalne-nel }
@put_phases:
   push  si
   push  ax
   mov   ch,16          { Egy BOB 16 sorb¢l  ll }
@put_bob:
   mov   cl,16          { X ir nyban pedig 16 (+4) pontb¢l }
@put_line:
   out   dx,ax          { a soron k”vetkez” pont kimaszkol sa }
   cmp   byte ptr [si],0
   jz    @p2            { Ugr s, ha a pont h tt‚rsz¡n }
   or    bh,ah          { Be¡rja a bitet a maszkba, ha szks‚ges }
@p2:
   movsb
   dec   di             {  tm sol s, de a c‚lc¡m nem n”het }
   test  ah,8
   jz    @next          { csak ha el‚rtk a b jt sz‚l‚t }
   mov   [di+offset Masks],bh   { A maszkadat t rol sa }
   xor   bh,bh          { null zza a BH-t az £jabb maszk el” ll¡t s hoz }
   inc   di             { most n”het a c¡m, mert v‚gigvette a n‚gy bitet }
   mov   ah,128
@next:
   rol   ah,1           { a k”vetkez” bitplane (£jabb pont) kiv laszt sa }
   dec   cl
   jnz   @put_line      { kirakja mind a 16 pontot }

   mov   [di+offset Masks],bh
   xor   bh,bh

   inc   di             { a DI n”vel‚se 4 plusz pixelt jelent a BOB m”g”tt }
   dec   ch
   jnz   @put_bob       { kirakja mind a 16 sort }
   pop   ax
   pop   si
   shl   ah,1           { eggyel eltolja az eg‚sz kirak st (az eg‚sz BOB-ot) }
   test  ah,16
   jz    @put_phases    { n‚gy f zis van egy BOB-n l }
   add   si,256         { egy BOB 256 b jt hossz£ a forr sadatban }
   dec   bl
   jnz   @put_all       { minden BOB konvert l sa }

   mov   ax,0f02h
   out   dx,ax
   mov   dx,03ceh
   mov   ax,0008h
   out   dx,ax

   pop   es
   pop   ds
  End;

 Procedure Load_Datas;
var f:file;
  Begin
     assign(f,'p1.dat');reset(f,1);blockread(f,Shapes,2048);close(f);
     assign(f,'p2.dat');reset(f,1);blockread(f,Shapes[2048],2048);close(f);
     assign(f,'p3.dat');reset(f,1);blockread(f,Shapes[4096],2048);close(f);
  End;


Procedure ChangePic; assembler;
asm
   mov   al,0ch
   mov   dx,03d4h
   mov   bx,InAcScr
   mov   ah,bh
   out   dx,ax
   mov   ah,bl
   inc   al
   out   dx,ax
   mov   dx,$03da
@Wait:
   in    al,dx
   and   al,8
   jz    @Wait         { V rakoz s az elektronsug r visszafut sra }
   xor   Act,2
   xor   InacScr,$3e80
   xor   InacSeg,$03e8
end;

procedure hattervissza; assembler;
asm
   push  DS
   push  bp

   cld
   mov   bp,DS          { A BP az eredeti DS-t t rolja }
   mov   ES,InacSEG     { Az ES az inakt¡v k‚pre mutat }

   lea   bx,Sprite        { BOB adatok }
   add   bx,Act         { Az inakt¡v k‚p c¡mei }
   add   bx,4           { Most vagy AdA-ra vagy AdB-re mutat a BX }

   mov   dx,03c4h       { Minden plane-t enged‚lyeznk ¡r sra     }
   mov   ax,0f02h
   out   dx,ax

   mov   al,SpriteNum
@restore_all:
   mov   DS,bp
   mov   di,[bx]        { Beolvassuk a k‚pc¡met AdA vagy AdB }
   mov   si,di

   { Most a DS:SI a bufferk‚pre mutat }
   { Az ES:DI pedig az inakt¡v k‚pre  }

   mov   DS,OrgPicSeg
   mov   cx,16          { 16 sor  tm sol sa k”vetkezik }
@restore_bytes:
   movsb                { 5*4 pixel, azaz 5 sz¡nes b jt m sol sa }
   movsb
   movsb
   movsb
   movsb
   add   di,75          { A c¡meket n”veljk }
   add   si,75
   loop  @restore_bytes
   add   bx,SpriteSize
   dec   al
   jnz   @restore_all
   { Most a k‚p helyre van  ll¡tva }
   pop bp
   pop ds
end;

Procedure Cim_Poz; assembler;  { In CX:Num, DI:PicPos -  Out DI,BX,SI }
asm
   MOV AX,320;MUL cx;mov cx,ax;                     {SpriteEltolas}
   MOV SI,cX;sub si,InAcScr;add si,SpriteOff;       {SpriteCim}
   mov ax,di;and ax,3;mov bx,80;mul bx;             {SpritePozicioEltolas}
   add si,ax;                                       {SpriteCimek  ES:SI}
   LEA BX,MASKS;ADD BX,cX;add bx,ax;                {MASKCIM DS:BX}
   shr di,2;                                        {Kepernyocim ES:DI}
end;

procedure Num_Cim; assembler;  { In AX:num - Out CX,DI }
asm
   lea bx,Sprite;
   mul SpriteSizeT;
   add bx,ax                              { BX = SpriteAdatCim }
   mov cx,[bx+2]                          { CX = Shapes}
   mov di,[bx]                            { DI = PicPos}
end;

procedure Utkozes; assembler;  { CL-ben az utkozesi kod }
asm
   push ax
   push dx
   test cl,64
   jz @i1
   mov r2,1        { Ha 64-nel nagyobb a szin,akkor nem mehet tovabb }
@i1:
    cmp cl,16
    jnz  @i2
    mov r3,1     { Ha a 16-os szinnel utkozik az vegzetes! }
@i2:
    cmp cl,40      { Pont szinnel utkozott }
    jnz @i3
    mov   dx,03c4h       { Minden plane-t enged‚lyeznk ¡r sra     }
    mov   ax,0f02h
    out   dx,ax
    push  es
    mov es,OrgPicseg
    MOV SI,DI
    INC  SI
    seges movsb
    dec di
    pop es
    inc pscore        { PalyaScore novelese }
    jmp @exit
@i3: cmp cl,17         { Ha almanak utkozott }
     jnz @i4
     mov ax,7;mov cl,8;mov dx,10;jmp @t
@i4: cmp cl,13         { Ha szilvanak utkozott }
     jnz @i5
     mov ax,6; mov cl,9;mov dx,20;jmp @t
@i5: cmp cl,4         { Ha cseresznye utkozott }
     jnz @i6
     mov ax,10; mov cl,10;mov dx,30;jmp @t
@i6: cmp cl,20         { Ha gyemant utkozott }
     jnz @i7
     mov ax,9; mov cl,11;mov dx,50;jmp @t
@i7: cmp cl,12         { Ha eper utkozott }
     jnz @i8
     mov ax,8; mov cl,11;mov dx,50;jmp @t
@i8: cmp cl,14         { Ha banan utkozott }
     jnz @i9
     mov ax,11; mov cl,10;mov dx,30;jmp @t
@i9: jmp @exit
@t:
     push bx
     push dx
     lea bx,Sprite;mul SpriteSizeT;add bx,ax
     pop  dx
     mov ax,30;cmp [bx+16],ax;jz @ii  { Ha mar lekezeltuk akkor kilepes }
     add bscore,dx                  { Pontszam       }
                ; mov [bx+16],ax    { AnimacioTime   }
     mov ax,2   ; mov [bx+12],ax    { Animacioszam   }
     mov ax,1   ; mov [bx+18],ax    { AnimacioCount  }
     mov ax,0   ; mov [bx+20],ax    { AnimacioCircle }
                  mov [bx+14],al    { AnimacioMut    }
     mov al,15  ; mov [bx+23],al    { AnimacioShapes }
                  mov [bx+22],cl    { BonusShape     }
     mov [bx+2],cl                  { Shape          }
@ii:
     pop bx
@exit:
      pop dx
      pop ax
end;


Procedure Color; assembler;  {In AH=MaskAdat, DI=PicCim - Out CH=Utkkod}
asm
   test ah,$ff          { HA A Mask byte 0 akkor kilepes}
   jz @exit
   mov al,$07;out dx,ax   {Mask kikuldese}
   mov al,es:[di];        { Byte olvasa}
   TEST al,128            { Teszt 128-nal nagyobb v. kisebb}
   jnz  @exit             { Ha 128-nal nagyobb akkor nincs utkozes }
       mov ch,ah                {Mask a CH-ben}
       mov ax,$4005;out dx,ax;  { 0.olvasasi mod}
       mov ax,$0004;
@ide:
       shr CH,1
       jnc @nomask    {Ha nincs mask akkor kilepes}
       out dx,ax      {BitPlanek Olvasasa}
       mov CL,es:[di]
       test cl,128
       jz @e
@nomask:
       inc ah
       cmp ah,$04
       jnz @ide
       jmp @exit2
@e:
       call utkozes
       jmp @nomask
@exit2:
      mov ax,$4a05;out dx,ax;       { 1. olvasasi mod         }
@exit:
end;

procedure Collosion;assembler;
asm
   mov ax,cx
   call num_cim    { CX = Shapes, DI = PicPos BX = SpriteCim }
   xor  al,al
   cmp  [bx+10],al { HA nincs utkozesfigyeles beallitva     }
   jnz @exit       { akkor kilepes                          }
   mov r0,bx
   call cim_poz    { BX = Mask, SI = SpriteCim, DI = PicCim  }
   mov  r3,0
   mov  r2,0

   MOV CX,16
   MOV DX,$03ce
@PUT:
   push cx
   MOV AH,[bx];call color;inc di;
   MOV AH,[bx+1];call color;inc di;
   MOV AH,[bx+2];call color;inc di;
   MOV AH,[bx+3];call color;inc di;
   MOV AH,[bx+4];call color;inc di;
   ADD DI,75;add bx,5;
   pop cx
   LOOP @PUT;
   mov bx,r0
   mov al,r3
   mov [bx+11],al    { Ha Vegzetes Sprite utkozes }
   cmp r2,0            { Ha R2 nem egyenlo 0-akkor eredeti pozicio }
   jz  @exit
   mov ax,[bx+8];    { Eredeti pozicio  visszaallitasa      }
   mov [bx],ax;
@exit:
end;


procedure ShowSprite;assembler;
asm
   mov ax,cx
   call num_cim                             { CX = Shapes, DI = PicPos               }
   mov [bx+8],di                            { OldPicPos elmentese}
   mov r0,bx                                { Spritecim megorzese }
   call cim_poz                             { BX = Mask, SI = SpriteCim, DI = PicCim }
   mov dx,bx;mov ax,si;mov bx,r0;mov si,act
   mov [bx+4+si],di;mov bx,dx;mov si,ax     {Apic vgy Bpic elmentese}

   mov DX,$03C4;  {Rajzolas}
   MOV AL,$02
   MOV CX,16
@PUT:
   MOV AH,[bx];OUT DX,AX;seges movsb
   MOV AH,[bx+1];OUT DX,AX;seges movsb
   MOV AH,[bx+2];OUT DX,AX;seges movsb
   MOV AH,[bx+3];OUT DX,AX;seges movsb
   MOV AH,[bx+4];OUT DX,AX;seges movsb
   ADD DI,75;add bx,5;
   LOOP @PUT;
end;

procedure SpriteAnimacio; assembler;
asm
   mov ax,cx
   lea bx,Sprite;
   mul SpriteSizeT;
   add bx,ax                              { BX = SpriteAdatCim }
   mov dx,[bx+18];     { DX-ben a animacioszamlalo }
   cmp dx,0
   jz  @vege           { Ha 0 akkor nincs animacio }
   inc dx
   cmp dx,[bx+16];     { animaciovaltas ? }
   jc @vege
   mov dx,1
   mov si,[bx+14]      { SI - AnimacioMutato }
   inc si
   mov aL,[bx+si+21]   { AL-ban az aktualis shape      }
   XOR AH,AH           { AH NULLAZASA }
   mov [bx+2],AL       { Aktualis Shape a Shapes-ba    }
   mov ax,[bx+12]
   cmp SI,[bx+12]      { Vege az animacios ciklusnak ? }
   jc @exit
   mov dx,[bx+20]      { Korkoros vagy sima animiacio }
   xor si,si
@exit:
   mov [bx+14],SI     { AnimacioMutato vissza }
@vege:
   mov [bx+18],DX     { Animacioszamlalo vissz }
end;


procedure SpriteMove; assembler;
asm
   call hattervissza
   mov cx,SpriteNum
@put:
     dec cx
     mov r1,cx
     call SpriteAnimacio
     call Collosion
     mov cx,r1
     call ShowSprite
     mov cx,r1
     cmp cx,0
     jnz @put
end;


Procedure Screen_Init; Assembler;
  Asm
   cld
   mov   AX,$A000;
   mov   ES,AX
   mov   cx,16000
   mov   si,00000
   mov   di,16000
   rep seges movsb  { "A" -> "B" }
   mov   cx,16000
   rep seges movsb  { "B" -> "C" }
   mov dx,$03ce           {Az utkozesvizsgalathoz kell!!}
   mov ax,$0f02;out dx,ax   {  Kerestt szin 15  }
   mov ax,$4805;out dx,ax  { 1. olvasasi mod}
  End;


 Procedure PutPixel(X,Y:word;Color:byte); Assembler;
  Asm
     mov   ES,SegA000
     mov   ax,80
     mul   Y
     mov   di,X
     mov   bx,di
     shr   di,2
     add   di,ax
     and   bx,3
     add   bx,offset PixelPos
     mov   dx,03c4h
     mov   al,02h
     mov   ah,[bx]
     out   dx,ax
     mov   al,Color
     mov   ES:[di],al
  End;

procedure SpriteLoad(num:byte);
var mi:string;f:file of spritetype;
begin
str(num,mi);assign(f,'sp'+mi+'.map');reset(f);read(f,sprite[num]);close(f);
end;

procedure spriteinit;
var i,j:word;
begin
spriteload(1);spriteload(2);spriteload(3);spriteload(4);
spriteload(5);spriteload(6);
for i:=2 to 6 do Sprite[i].animaciotime:=50;
sprite[1].utkozesfigyeles:=0;

sprite[7].picpos:=96*320+278;sprite[7].shapes:=13;   { szilva     }
sprite[8].picpos:=157*320+100;sprite[8].shapes:=7;   { alma       }
sprite[9].picpos:=5*320+299;sprite[9].shapes:=16;    { eper       }
sprite[10].picpos:=50*320+153;sprite[10].shapes:=6;  { gyemant    }
sprite[11].picpos:=93*320+152;sprite[11].shapes:=14; { cseresznye }
sprite[12].picpos:=6*320+50;sprite[12].shapes:=17;   { banan      }
for i:=7 to spritenum
    do with sprite[i]
       do begin
          oldpicpos:=picpos;
          apic:=0;bpic:=0;
          utkozesfigyeles:=1;
          animaciomut:=0;animacioszam:=0;
          animaciocount:=0;
          yseb:=1;xseb:=yseb*320;
          pmut:=1;ptime:=1;
          for j:=1 to 100 do begin palya[j]:=0;phossz[j]:=0;end;
          end;
for i:=7 to 12 do
    with sprite[i] do
         begin
         animacioszam:=2;animaciotime:=i*50;animaciocount:=1;
         animaciocircle:=1;
         as[1]:=shapes;as[2]:=15;
         end;
end;



procedure palya(n1,n2:byte);
var num:byte;
begin
for num:=n1 to n2
    do
    with sprite[num] do
     begin
     case palya[pmut] of
          1: picpos:=picpos-yseb;
          2: picpos:=picpos+yseb;
          3: picpos:=picpos+xseb;
          4: picpos:=picpos-xseb;
          end;
     ptime:=ptime+1;
     if ptime=phossz[pmut]
        then begin
             ptime:=1;pmut:=pmut+1;
             if palya[pmut]=0
                then pmut:=1;
             end;
     end;
end;

procedure ido; assembler;
asm
   xor al,al
   out $43,al
   push cx
   mov cx,2
@i1:
   in al,$40
   xchg ah,al
   loop @i1
   pop cx
   ret
end;

procedure hivas; assembler;
asm
   cli
   call ido
   mov dx,$0201
   out dx,al
   push ax
   mov cx,$04ff
@i1:
   in al,dx
   and al,bh
   loopnz @i1
@i5:
   pop dx
   jcxz @i3
   call ido
   xchg dx,ax
   cmp ax,dx
   sbb ax,dx
   mov cl,4
   shr ax,cl
   and ax,$0ff
   push ax
@i4:
   sti
   mov dx,$0201
   mov cx,$04ff
@i2:
   in al,dx
   and al,$0f
   loopnz @i2
   pop ax
   ret
@i3:
   push cx
   jmp @i4
end;

procedure joys1; assembler;
asm
   mov bh,2
@ide:
   call hivas
   push ax
   shr bh,1
   jne @ide
   pop ax
   pop bx
   clc
   sti
   mov joyx,ax
   mov joyy,bx
end;

procedure joygomb; assembler;
asm
   mov dx,$0201
   in al,dx
   and al,$f0
   mov joybutton,al
end;

procedure calibrat;
begin
joys1;cx:=joyx;cy:=joyy;
end;


PROCEDURE IRANYITAS(num:byte);
begin
    WITH Sprite[num] DO
     BEGIN
     if (ktb[$4b]) then PicPos:=PicPos-ySeb;
     if (ktb[$4d]) then PicPos:=Picpos+ySeb;
     if (ktb[$50]) then PicPos:=Picpos+xseb;
     if (ktb[$48]) then PicPos:=Picpos-xseb;
     END;
end;

{$I labirint}

PROCEDURE DEMO;
VAR R,G,B:BYTE;D:SHORTINT;C:BYTE;mi:string;
BEGIN
REPEAT
      load_datas;_320x200;Labirintus;
      for c:=0 to 255 do
          begin getrgb(c,r,g,b);r:=r div 2;g:=g div 2;b:=b div 2;setrgb(c,r,g,b);end;
      {setcolor(249);OUTtextXY(97,96,'G A M E  O V E R');}
      R:=20;G:=20;B:=40;D:=1;str(score,mi);
      {outtextxy(115,35,'Score = '+mi);}
      Convert_Datas(shapes,$ABB8,24);SpriteInit;
      Screen_Init;c:=0;
      repeat
            SpriteMove;
            changepic;
            palya(1,6);
            c:=c+1;
            if c>2
               then begin
                    R:=R+D;G:=G+D;B:=B+D;
                    SETRGB(249,R,G,B);SETRGB(254,R,G,B);
                    IF (B=62) OR (R=20) THEN D:=-D;
                    c:=0;
                    end;
            joygomb;
      until (sprite[1].vegzetesutkozes=1) OR (KTB[1]) OR (KTB[$39]) or (joybutton<>240);
      IF KTB[$1] THEN KILEP:=TRUE;
UNTIL (KILEP) OR (KTB[$39]) or (joybutton<>240);
END;

procedure palya1;
begin
_320x200;Labirintus;load_datas;
Convert_Datas(shapes,$ABB8,24);SpriteInit;
Screen_Init;pscore:=0;bscore:=0;
repeat
      SpriteMove;
      changepic;
      palya(2,6);
      iranyitas(1);
until (ktb[1]) or (sprite[1].vegzetesutkozes=1) OR (PSCORE>110);
score:=pscore+bscore;
end;

begin
GetintVec($09,@oldKEY);SetintVec($09,@KeyIRQ);
score:=0;KILEP:=FALSE;calibrat;
DEMO;
WHILE NOT KILEP DO BEGIN score:=0;palya1;DEMO;END;
SetintVec($09,@oldKEY);
asm mov ax,$0003;int $10;end;
end.