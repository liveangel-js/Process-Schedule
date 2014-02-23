org 100h		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Preprocessing
;You should implement step b and step d
;step b is a little bit non-trivial
;pay much attention and make use of debugging skills
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;step a
    mov ax,09000h
    mov es,ax
    mov word[es:0],0
   
	mov ax,cs
	mov	ds,ax		
	mov ss,ax		


;step b(implement by yourself)
;start with sti, initial all the registers in PCB blocks using loop
;you can derive some information from data segment
    sti
    mov cx,AllProcNum
    mov ax,word[BaseOfPro];07000h、07020h\07040h\07060h
   ; mov es,cs
	mov si,0000h;进程id
	mov bx,0;偏移指针分别为0、34、68、102
init:;初始化PCB
	
	
	mov word[PCB+bx],0b800h;GS
	mov word[PCB+bx+2],ax;FS
	mov word[PCB+bx+4],ax;ES
	mov word[PCB+bx+6],ax;DS
	mov word[PCB+bx+8],0000h;DI
	mov word[PCB+bx+10],0000h;SI
	mov word[PCB+bx+12],0000h;BP
	mov word[PCB+bx+14],0100h;SP
	mov word[PCB+bx+16],0000h;BX
	mov word[PCB+bx+18],0000h;DX
	mov word[PCB+bx+20],0000h;CX
	mov word[PCB+bx+22],0000h;AX
	mov word[PCB+bx+24],0100h;IP
	mov word[PCB+bx+26],ax;CS
	
	mov word[PCB+bx+30],ax;SS
	mov word[PCB+bx+32],si;ID
	pushf
	pop ax
	mov word[PCB+bx+28],ax;FLAGS
	mov ax,word[PCB+bx+2];还原ax
	
	add si,1
	add ax,20h
	add bx,34
	
loop init
	
;step c
	cli
	
	xor ax,ax			
	mov es,ax			
	mov word[es:20h],Clock_handler; 
	mov ax,cs 
	mov [es:22h],ax		
	
;step d(implement by yourself)
;prepare all the required registers for Process1
	;初始化进程
	mov gs,word[PCB+0];gs
	mov fs,word[PCB+2];fs
	mov es,word[PCB+4];es
	mov ds,word[PCB+6];ds
	mov di,word[PCB+8]
	mov si,word[PCB+10]
	mov bp,word[PCB+12]
	mov sp,word[PCB+14]
	mov bx,word[PCB+16]
	mov dx,word[PCB+18]
	mov cx,word[PCB+20]
	mov ax,word[PCB+22]
	push word[PCB+28]
	popf;flags出栈
	mov ss,word[PCB+30]
	
	;mov id,word[PCB+32]
	
;step e
    
	sti
	
	jmp 7000h:100h		

    hlt
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Clock_handler:											
	  ;
;you can follow the steps we have defined in Assignment[Final];
;or you can just implement your own version  				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
Clock_handler:
	dec word[cs:TimeCount];减1
	cmp word[cs:TimeCount],0;判断是否到300次
	jz change;是则进入进程切换
	jmp back

back:
	push ax;中断返回固定操作
	mov al,20h
	out 20h,al
	out 0A0h,al
	pop ax
	iret
change:
	mov word [cs:TimeCount],300   

Pro_schedule:;进入中断前	进程x的寄存器都放入对应的PCB块中
    push bx
	mov bx,word[cs:Pro_Ready]
	
	mov word[cs:bx],gs;gs
	mov word[cs:bx+2],fs;
	mov word[cs:bx+4],es
	mov word[cs:bx+6],ds
	mov word[cs:bx+8],di
	mov word[cs:bx+10],si
	mov word[cs:bx+12],bp
	mov word[cs:bx+14],sp
	;mov word[cs:bx+16],bx
	mov word[cs:bx+18],dx
	mov word[cs:bx+20],cx
	mov word[cs:bx+22],ax
	
	pop word[cs:bx+24];ip
	pop word[cs:bx+26];cs      从栈区拿cs、ip、flags
	pop word[cs:bx+28];flags
	mov word[cs:bx+30],ss
	pop bx
	mov word[cs:bx+16],bx
  
step_c:
     add word [cs:Pro_Ready],34
     cmp word [cs:Pro_Ready],PCB+34*AllProcNum
     jnz step_d
     mov word [cs:Pro_Ready],PCB
 
step_d:
;-------PCB块中的寄存器拿出，作为下一进程的状态    
     ;push si
    mov bx,[cs:Pro_Ready]
     ;取出相应寄存器
     mov gs,[cs:bx+0];gs
     mov fs,[cs:bx+2];fs
     mov es,[cs:bx+4] ;es
     mov ds,[cs:bx+6] ;ds
     mov si,[cs:bx+10];si
     mov di,[cs:bx+8] ;di
     
     mov bp,[cs:bx+12];bp 
     mov sp,[cs:bx+14];sp
    ; mov word bx,[bx+16];bx
     mov dx,[cs:bx+18];dx
     mov cx,[cs:bx+20];cx
     mov ax,[cs:bx+22];ax
     mov ss,[cs:bx+30];ss
     ;把FLAGS CS,IP 入栈
     push word[cs:bx+28] ;push flags
     push word[cs:bx+26] ;push cs
     push word[cs:bx+24] ;push ip
     mov bx,[cs:bx+16];bx
     
                 
     push ax;中断返回
     mov al,20h
     out 20h,al
     out 0A0h,al
     pop ax
    
     iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;data segment											
	  ;
;(better not modify the following assembly code)			  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AllProcNum equ 4
TimeCount dw 300
BaseOfPro dw 07000h,07020h,07040h,07060h
Pro_Ready dw PCB
PCB dw 0


;the third PCB Block should be the following after Preprocessing step b
 
;B800h;GS Process1
;7000h	;FS
;7000h	;ES
;7000h	;DS
;0000h	;DI
;0000h	;SI
;0000h	;BP
;0100h	;SP
;0000h	;BX
;0000h	;DX
;0000h	;CX
;0000h	;AX
;0100h	;IP
;7000h	;CS
;0000h	;Flags
;7000h	;SS
;0001h	;ID

;B800h	;GS
;7020h	;FS
;7020h	;ES
;7020h	;DS
;0000h	;DI
;0000h	;SI
;0000h	;BP
;0100h	;SP
;0000h	;BX
;0000h	;DX
;0000h	;CX
;0000h	;AX
;0100h	;IP
;7020h	;CS
;0000h	;Flags
;7020h	;SS
;0002h	;ID

;B800h   ;GS
;7040h   ;FS
;7040h   ;ES
;7040h   ;DS
;0000h   ;DI
;0000h   ;SI
;0000h   ;BP
;0100h   ;SP
;0000h   ;BX
;0000h   ;DX
;0000h   ;CX
;0000h   ;AX
;0100h   ;IP
;7040h   ;CS
;0000h   ;Flags
;7040h   ;SS
;0003h   ;ID

;B800h   ;GS
;7060h   ;FS
;7060h   ;ES
;7060h   ;DS
;0000h   ;DI
;0000h   ;SI
;0000h   ;BP
;0100h   ;SP
;0000h   ;BX
;0000h   ;DX
;0000h   ;CX
;0000h   ;AX
;0100h   ;IP
;7060h   ;CS
;0000h   ;Flags
;7060h   ;SS
;0004h   ;ID



















