org 100h
	
	
%macro HONG 4 ;input the # paramters you want to define
;code in macro
	;%1 :
;mov dx , 0
;%2 :
;mov al ,%3
;loop %2
	
%4:	
	mov cx,65535;2*FFFF¥Œø’—≠ª∑
%1:	mov ax,1
	loop %1
	mov cx,65535
%2:
	mov ax,1
	loop %2

	mov ax,09000h
	mov es,ax
	mov bx,[es:0];ªÒ»°–¥œ‘¥ÊŒª÷√
	
	mov ax,0b800h
	mov gs,ax
	
	mov ah,0fh
	mov al,%3
	mov [gs:bx],ax;–¥œ‘¥Ê
	
	add bx,2;“∆∂Øœ‘¥ÊŒª÷√
	
	mov ax,09000h;±£¥Êœ‘¥ÊŒª÷√
	mov es,ax
	mov [es:0],bx
	loop %4
%endmacro	


;The followings call 4 times HONG
;parameters for Process1
HONG a1,b1,'A',c1
times 459 db 0
HONG a2,b2,'B',c2;parameters for Process2
times 459 db 0
HONG a3,b3,'C',c3;parameters for Process3
times 459 db 0
HONG a4,b4,'D',c4;parameters for Process4
times 203 db 0




















