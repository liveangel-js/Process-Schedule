org  0100h
;BaseOfLoader		equ	09000h	; LOADER.BIN 被加载到的位置 ----  段地址
;OffsetOfLoader		equ	0100h	; LOADER.BIN 被加载到的位置 ---- 偏移地址

BaseOfKernel	equ	     08000h	; KERNEL.BIN 被加载到的位置 ----  段地址
OffsetOfKernel	equ	     0100h	; KERNEL.BIN 被加载到的位置 ---- 偏移地址
BaseOfProcess   equ      07000h ; PROCESS.BIN 被加载到的位置 ----  段地址
OffsetOfProcess equ      0100h ; PROCESS.BIN 被加载到的位置 ---- 偏移地址

	jmp	LABEL_START		; Start

; 下面是 FAT12 磁盘的头, 之所以包含它是因为下面用到了磁盘的一些信息
%include	"fat12hdr.inc"


LABEL_START:			; <--- 从这里开始 *************
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; 清屏
	mov	ax, 600h	; AH = 6,  AL = 0
	mov	bx, 700h	; 黑底白字(BL = 7)
	mov	cx, 0		; 左上角: (0, 0)
	mov	dx, 184fh	; 右下角: (24, 79)
	int	10h		; 显示中断
	
ITERATE_KERNEL_PROCESS:
    mov dh,byte [NumFile]
	call DispStr

	mov	word [wSectorNo], SectorNoOfRootDirectory
	mov word [wRootDirSizeForLoop], RootDirSectors	
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; `.
	jz	LABEL_NO_KERNELBIN		;  | 判断根目录区是不是已经读完,
	dec	word [wRootDirSizeForLoop]	; /  读完表示没有找到 KERNEL.BIN
	mov	ax, 04000h
	mov	es, ax			; es <- BaseOfKernel
	mov	bx, OffsetOfKernel	; bx <- OffsetOfKernel
	mov	ax, [wSectorNo]		; ax <- Root Directory 中的某 Sector 号
	mov	cl, 1
	call	ReadSector
    
    call Calculate
	mov	di, OffsetOfKernel
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_KERNELBIN:
	cmp	dx, 0				  ; `.
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR;  | 循环次数控制, 如果已经读完
	dec	dx				  ; /  了一个 Sector, 就跳到下一个
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0			; `.
	jz	LABEL_FILENAME_FOUND	;  | 循环次数控制, 如果比较了 11 个字符都
	dec	cx			; /  相等, 表示找到
	lodsb				; ds:si -> al
	cmp	al, byte [es:di]	; if al == es:di
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME	;	继续循环

LABEL_DIFFERENT:
	and	di, 0FFE0h		; else`. 让 di 是 20h 的倍数
	add	di, 20h			;      |
    call Calculate
	jmp	LABEL_SEARCH_FOR_KERNELBIN;   /

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_KERNELBIN:
	mov	dh, 3			; "Sth.wrong"
	call	DispStr			; 显示字符串

%ifdef	_LOADER_DEBUG_
	mov	ax, 4c00h		; `.
	int	21h			; / 没有找到 KERNEL.BIN, 回到 DOS
%else
	jmp	$			; 没有找到 KERNEL.BIN, 死循环在这里
%endif

LABEL_FILENAME_FOUND:			; 找到 KERNEL.BIN 后便来到这里继续
	mov	ax, RootDirSectors
	and	di, 0FFF0h		; di -> 当前条目的开始
	add	di, 01Ah		; di -> 首 Sector
	mov	cx, word [es:di]
	push	cx			; 保存此 Sector 在 FAT 中的序号
	add	cx, ax
	add	cx, DeltaSectorNo	; cl <- LOADER.BIN 的起始扇区号(0-based)
	
	cmp byte [NumFile],0
	jnz  loop3	
	
	mov	ax, BaseOfKernel
	mov	es, ax			; es <- BaseOfKernel
	mov	bx, OffsetOfKernel	; bx <- OffsetOfKernel
	mov	ax, cx			; ax <- Sector 号
    jmp LABEL_GOON_LOADING_FILE
	
loop3:
    mov ax,BaseOfProcess
	mov es,ax
	mov bx,OffsetOfProcess
	mov ax,cx
	
LABEL_GOON_LOADING_FILE:
	mov	cl, 1
	call	ReadSector
	pop	ax			; 取出此 Sector 在 FAT 中的序号
	call	GetFATEntry
	cmp	ax, 0FF8h
	jae	LABEL_FILE_LOADED
	push	ax			; 保存 Sector 在 FAT 中的序号
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
    inc byte [NumFile]
	cmp byte [NumFile],2
	jnz ITERATE_KERNEL_PROCESS
	

	mov	dh, 2			    ; "Success  "
	call	DispStr			; 显示字符串

	jmp	BaseOfKernel:OffsetOfKernel

;============================================================================
;变量
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数
wSectorNo		dw	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数
dwKernelSize		dd	0		; KERNEL.BIN 文件大小

;============================================================================
;字符串
;----------------------------------------------------------------------------
StartFileName		db	"KERNEL  BIN" ; KERNEL.BIN 之文件名
          	        db	"PROCESS BIN" ; PROCESS.BIN文件名
NumFile             db   0

; 为简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
LoadMessage:		db	"Kernel   "
				    db	"Process  "
					db  "Success  "
          		    db	"Sth.wrong"
;============================================================================

;----------------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
; 作用:
;	显示一个字符串, 函数开始时 dh 中应该是字符串序号(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, LoadMessage
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, MessageLength	; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	int	10h			; int 10h
	ret
;----------------------------------------------------------------------------
; 函数名: ReadSector
;----------------------------------------------------------------------------
; 作用:
;	从序号(Directory Entry 中的 Sector 号)为 ax 的的 Sector 开始, 将 cl 个 Sector 读入 es:bx 中
ReadSector:
	; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; 保存 bx
	mov	bl, [BPB_SecPerTrk]	; bl: 除数
	div	bl			; y 在 al 中, z 在 ah 中
	inc	ah			; z ++
	mov	cl, ah			; cl <- 起始扇区号
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov	ch, al			; ch <- 柱面号
	and	dh, 1			; dh & 1 = 磁头号
	pop	bx			; 恢复 bx
	; 至此, "柱面号, 起始扇区, 磁头号" 全部得到 ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
.GoOnReading:
	mov	ah, 2			; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret

;----------------------------------------------------------------------------
; 函数名: GetFATEntry
;----------------------------------------------------------------------------
; 作用:
;	找到序号为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中
;	需要注意的是, 中间需要读 FAT 的扇区到 es:bx 处, 所以函数一开始保存了 es 和 bx
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, 06000h
	sub	ax, 100h	; ┣ 在 BaseOfKernel 后面留出 4K 空间用于存放 FAT
	mov	es, ax			; ┛
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;偶数
	xor	dx, dx			; 现在 ax 中是 FATEntry 在 FAT 中的偏移量. 下面来计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	mov	bx, [BPB_BytsPerSec]
	div	bx			; dx:ax / BPB_BytsPerSec  ==>	ax <- 商   (FATEntry 所在的扇区相对于 FAT 来说的扇区号)
					;				dx <- 余数 (FATEntry 在扇区内的偏移)。
	push	dx
	mov	bx, 0			; bx <- 0	于是, es:bx = (BaseOfKernel - 100):00 = (BaseOfKernel - 100) * 10h
	add	ax, SectorNoOfFAT1	; 此句执行之后的 ax 就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector		; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界发生错误, 因为一个 FATEntry 可能跨越两个扇区
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------

Calculate:
	mov al,byte [NumFile]
	mov bl,11
	mul bl
	add ax, StartFileName
	mov	si, ax	; ds:si -> "KERNEL  BIN"
	ret
