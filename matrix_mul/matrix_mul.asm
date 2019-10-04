INCLUDE Irvine32.inc
INCLUDE macros.inc
.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO,dwExitCode:DWORD
CreateOutputFile PROTO
CloseFile PROTO
ReadFromFile PROTO	
OpenInputFile PROTO
ReadString PROTO
WriteString PROTO
WriteDec PROTO
WriteChar PROTO
PDWORD TYPEDEF PTR DWORD ; 双字指针
BUFFER_SIZE=150

.data

aRow DWORD ?  ; A的行数
aCol DWORD ?  ; A的列数
bRow DWORD ?  ; B的行数
bCol DWORD ?  ; B的列数

tmpRow DWORD ?  ; 暂存的行数 
tmpCol DWORD ?  ; 暂存的列数

; 矩阵按行存储
mA DWORD 20 DUP(?)
mB DWORD 20 DUP(?)
mC DWORD 20 DUP(?)  ; A*B=C

pA PDWORD OFFSET mA  ; DWORD指针
pB PDWORD OFFSET mB
pC PDWORD OFFSET mC
tP PDWORD ?  ; 临时指针
rpA PDWORD ? ; 暂存pA
rpB PDWORD ? ; 暂存pB
tmp DWORD ?  ; 暂存循环次数
count DWORD ? ; 暂存该数字的位数
offsetB DWORD ?  ; pB向下一列移动的偏移量

File1 BYTE 50 DUP(?)  ; A矩阵文件路径
File2 BYTE 50 DUP(?)  ; B矩阵文件路径
File3 BYTE 50 DUP(?)  ; C矩阵文件输出路径

infoA BYTE 'input filename of A:  ',0
infoB BYTE 'input filename of B:  ',0
infoC BYTE 'input filename of C:  ',0
shapeA BYTE 'The shape of A is:  ',0
shapeB BYTE 'The shape of B is:  ',0
errorInfo BYTE '不满足乘法条件',0
resultInfo BYTE 'The result is :',0
array BYTE 5 DUP(0)   ; 数组,取数位时用

buffer BYTE BUFFER_SIZE DUP(?)  ; 文件缓冲区
fileHandle HANDLE ?  ; 句柄
.code
main PROC

; 用户输入
	; 输入A文件名
	mov edx,OFFSET infoA
	call WriteString

	mov edx,OFFSET File1
	mov ecx,SIZEOF File1
	call ReadString

	; 输入B文件名
	mov edx,OFFSET infoB
	call WriteString

	mov edx,OFFSET File2
	mov ecx,SIZEOF File2
	call ReadString

	; 输入C文件名
	mov edx,OFFSET infoC
	call WriteString

	mov edx,OFFSET File3
	mov ecx,SIZEOF File3
	call ReadString

	; 读入A矩阵
	
	mov edx, OFFSET File1
	call readMatrix
	mov tP,OFFSET mA
	call loadMatrix
	mov eax,tmpRow
	mov aRow,eax
	mov eax,tmpCol
	mov aCol,eax

	
	; 读入B矩阵
	
	mov edx, OFFSET File2
	call readMatrix
	mov tP,OFFSET mB
	call loadMatrix
	mov eax,tmpRow
	mov bRow,eax
	mov eax,tmpCol
	mov bCol,eax

	; 不满足乘法行列条件
	mov eax,aCol
	mov ebx,bRow
	.IF eax != ebx
		mov edx,OFFSET errorInfo
		call WriteString
		INVOKE ExitProcess,0
	.ENDIF

	; 计算pB下移的偏移量
	mov eax,bCol
	mov ebx,TYPE mB
	mul ebx
	mov offsetB,eax

	; 矩阵乘法
	call calRows

	; 在屏幕输出
	
	;call printMatrix

	;INVOKE ExitProcess,0

	call dumpMatrix

	; 结果输出到屏幕
	mov edx,OFFSET resultInfo
	call WriteString
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar
	mov edx,OFFSET buffer
	call WriteString

	; 写入文件
	mov edx,OFFSET File3
	call writeMatrix
main ENDP


readMatrix PROC
	; 打开文件读入,应确保栈顶为文件名的偏移量
	call OpenInputFile
	mov fileHandle,eax

	; 文件读入缓冲区
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	
	; 在文件结尾插入空白符
	mov buffer[eax],0

	; 关闭文件
	mov	eax,fileHandle
	call	CloseFile

	ret
readMatrix ENDP

loadMatrix PROC USES esi  ; !!!! 保存esi 否则ret找不到正确地址!!!!!

	; 从缓冲区读字符串,转为DWORD,应确保栈顶为 矩阵数组头的偏移量
	; esi 变址寄存器
	; eax 乘法
	; edx 暂存和
	; ecx 暂存被乘数
	mov tmpRow,0
	mov tmpCol,0
	mov esi,0
	mov eax,0
	mov ebx,0
	mov edx,0

	.WHILE buffer[esi] != 0
		
		.IF buffer[esi] == 20h ; 是空格
			.IF tmpRow<1  
				inc tmpCol    ; 列数加一
			.ENDIF

			mov edi,tP
			mov [edi],ebx ; 写入到数组
			add tP,TYPE DWORD        ; 指针后移
			inc esi
			mov ebx,0

		.ELSEIF buffer[esi] == 0dh; 是换行符 一个回车换行包括两个字符:0dh 0ah
			inc tmpRow  ; 行数加一

			mov edi,tP
			mov [edi],ebx ; 写入到数组
			mov ebx,0
			add tP,TYPE DWORD        ; 指针后移
			add esi,2
			
		.ELSE ; 是数字
			; ASCII码 除以 30h 余数是 对应的数字值 DIV 指令
			movzx eax,buffer[esi] ;读入的字符存入edi
			mov ecx,30h ; EAX/ECX --> 商EAX 余数EDX
			div ecx  
			
			mov edi,edx

			mov eax,10 ; EBX中暂存的和乘以10 --> EAX
			mul ebx
			mov ebx,eax ; 存回EBX

			add ebx,edi
			inc esi

		.ENDIF
		
	.ENDW
	inc tmpCol
	ret
loadMatrix ENDP


; 计算A矩阵的一行分别乘B矩阵的每一列 (二重循环)
calOneRow PROC USES ecx

	mov ecx,bCol ; 设置外层循环数
	mov eax,pA
	mov rpA,eax  ; 暂存pA

L1:				 ; 外层循环
	mov eax,pB
	mov rpB,eax  ; 暂存pB

	mov ebx,0    ; 累加和
	mov tmp,ecx
	mov ecx,aCol ; 设置内层循环数
	
	L2:          ; 内层循环
		mov esi,pA
		mov eax,[esi] ; pA 所指的数 --> EAX

		mov esi,pB
		mov edx,[esi]
		mul edx   ; pB 所指的数*EAX --> EAX
		add ebx,eax ; 部分和 --> EBX

		add pA,TYPE mA  ; pA横向移动

		mov eax,offsetB
		add pB,eax  ; pB纵向移动

		loop L2

	mov edi,pC
	mov [edi],ebx   ; 写到C矩阵
	add pC,TYPE mC  ; pC后移

	mov eax,rpA  ; 恢复pA
	mov pA,eax
	
	mov eax,rpB
	add eax,TYPE mB
	mov pB,eax   ; pB指向下一列

	mov ecx,tmp  ; 恢复外层循环值
	loop L1
	
	mov eax,OFFSET mB
	mov pB,eax   ; pB重新指向 B矩阵

	ret
calOneRow ENDP

; 对矩阵A的每一行调用calOneRow , 得出最终结果
calRows PROC
	mov ecx,aRow
	
L1:
	push ecx       ;  !!!重要
	call calOneRow
	mov eax,pA

	mov eax,aCol
	mov edx,TYPE mA
	mul edx
	add pA,eax

	pop ecx    ; !!! 重要
	loop L1
	
	ret
calRows ENDP


writeMatrix PROC
; 从缓冲区输出到文件, 设edx中已有文件路径
	call CreateOutputFile
	
	mov edx,OFFSET buffer
	mov ecx,tmp ; 此处是文件长度
	call WriteToFile
	call CloseFile 
	ret
writeMatrix ENDP

dumpMatrix PROC USES esi
; DWORD 数组转成字符串并写入缓冲区
	mov ebx,bCol
	mov eax,aRow
	mul ebx
	mov ecx,eax  ; C矩阵总元素数
	mov tmpCol,0
	mov pC,OFFSET mC
	mov esi,0

L1:
	
	mov edx,pC
	mov eax,[edx]
	
	inc tmpCol

	mov ebx,10    ; ebx为除数
	mov edx,0
	mov edi,0     ; 计数,记录压栈次数
    jmp TESTING
FORLOOP:
    xor edx,edx   ; 异或操作(清零edx),32位做除法时余数存放在edx，使用前要清零
    div ebx       ; eax = eax/10 商在eax中，余数是edx
    add dl, 30h   ; 将数字转换成字符
	push dx
    inc edi

TESTING:
    cmp eax,0    ; 被除数 存放在eax
    jne FORLOOP  ; 非零则跳转


	.WHILE edi > 0  ; 逐次出栈
		pop dx
		mov buffer[esi],dl
		inc esi
		dec edi
	.ENDW

	mov buffer[esi],20h ; 写空格
	inc esi

	mov edx,bCol

	.IF tmpCol == edx
		; 写入回车换行符
		mov buffer[esi],0dh
		inc esi
		mov buffer[esi],0ah
		inc esi
		mov tmpCol,0
	.ENDIF


	add pC,TYPE mC     ; 指针后移,指向下一个 DWORD数
	loop L1
	mov buffer[esi],0  ; 写入结束符
	mov tmp,esi
	ret
dumpMatrix ENDP

END main


printMatrix PROC

	mov edi,0
	mov ecx,aRow ; 外层循环数
L0:
	mov tmp,ecx  ; 保存外层循环数
	mov ecx,bCol ; 内层循环数
	
	L2:
		
		mov eax,mC[edi]
		call WriteDec   ; 打印十进制数
		mov al,32
		call WriteChar  ; 打印空格

		add edi,TYPE mC
		loop L2

	; 写入回车换行符
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar

	mov ecx,tmp
	loop L0
	ret
printMatrix ENDP