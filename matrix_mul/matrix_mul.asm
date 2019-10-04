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
PDWORD TYPEDEF PTR DWORD ; ˫��ָ��
BUFFER_SIZE=150

.data

aRow DWORD ?  ; A������
aCol DWORD ?  ; A������
bRow DWORD ?  ; B������
bCol DWORD ?  ; B������

tmpRow DWORD ?  ; �ݴ������ 
tmpCol DWORD ?  ; �ݴ������

; �����д洢
mA DWORD 20 DUP(?)
mB DWORD 20 DUP(?)
mC DWORD 20 DUP(?)  ; A*B=C

pA PDWORD OFFSET mA  ; DWORDָ��
pB PDWORD OFFSET mB
pC PDWORD OFFSET mC
tP PDWORD ?  ; ��ʱָ��
rpA PDWORD ? ; �ݴ�pA
rpB PDWORD ? ; �ݴ�pB
tmp DWORD ?  ; �ݴ�ѭ������
count DWORD ? ; �ݴ�����ֵ�λ��
offsetB DWORD ?  ; pB����һ���ƶ���ƫ����

File1 BYTE 50 DUP(?)  ; A�����ļ�·��
File2 BYTE 50 DUP(?)  ; B�����ļ�·��
File3 BYTE 50 DUP(?)  ; C�����ļ����·��

infoA BYTE 'input filename of A:  ',0
infoB BYTE 'input filename of B:  ',0
infoC BYTE 'input filename of C:  ',0
shapeA BYTE 'The shape of A is:  ',0
shapeB BYTE 'The shape of B is:  ',0
errorInfo BYTE '������˷�����',0
resultInfo BYTE 'The result is :',0
array BYTE 5 DUP(0)   ; ����,ȡ��λʱ��

buffer BYTE BUFFER_SIZE DUP(?)  ; �ļ�������
fileHandle HANDLE ?  ; ���
.code
main PROC

; �û�����
	; ����A�ļ���
	mov edx,OFFSET infoA
	call WriteString

	mov edx,OFFSET File1
	mov ecx,SIZEOF File1
	call ReadString

	; ����B�ļ���
	mov edx,OFFSET infoB
	call WriteString

	mov edx,OFFSET File2
	mov ecx,SIZEOF File2
	call ReadString

	; ����C�ļ���
	mov edx,OFFSET infoC
	call WriteString

	mov edx,OFFSET File3
	mov ecx,SIZEOF File3
	call ReadString

	; ����A����
	
	mov edx, OFFSET File1
	call readMatrix
	mov tP,OFFSET mA
	call loadMatrix
	mov eax,tmpRow
	mov aRow,eax
	mov eax,tmpCol
	mov aCol,eax

	
	; ����B����
	
	mov edx, OFFSET File2
	call readMatrix
	mov tP,OFFSET mB
	call loadMatrix
	mov eax,tmpRow
	mov bRow,eax
	mov eax,tmpCol
	mov bCol,eax

	; ������˷���������
	mov eax,aCol
	mov ebx,bRow
	.IF eax != ebx
		mov edx,OFFSET errorInfo
		call WriteString
		INVOKE ExitProcess,0
	.ENDIF

	; ����pB���Ƶ�ƫ����
	mov eax,bCol
	mov ebx,TYPE mB
	mul ebx
	mov offsetB,eax

	; ����˷�
	call calRows

	; ����Ļ���
	
	;call printMatrix

	;INVOKE ExitProcess,0

	call dumpMatrix

	; ����������Ļ
	mov edx,OFFSET resultInfo
	call WriteString
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar
	mov edx,OFFSET buffer
	call WriteString

	; д���ļ�
	mov edx,OFFSET File3
	call writeMatrix
main ENDP


readMatrix PROC
	; ���ļ�����,Ӧȷ��ջ��Ϊ�ļ�����ƫ����
	call OpenInputFile
	mov fileHandle,eax

	; �ļ����뻺����
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	
	; ���ļ���β����հ׷�
	mov buffer[eax],0

	; �ر��ļ�
	mov	eax,fileHandle
	call	CloseFile

	ret
readMatrix ENDP

loadMatrix PROC USES esi  ; !!!! ����esi ����ret�Ҳ�����ȷ��ַ!!!!!

	; �ӻ��������ַ���,תΪDWORD,Ӧȷ��ջ��Ϊ ��������ͷ��ƫ����
	; esi ��ַ�Ĵ���
	; eax �˷�
	; edx �ݴ��
	; ecx �ݴ汻����
	mov tmpRow,0
	mov tmpCol,0
	mov esi,0
	mov eax,0
	mov ebx,0
	mov edx,0

	.WHILE buffer[esi] != 0
		
		.IF buffer[esi] == 20h ; �ǿո�
			.IF tmpRow<1  
				inc tmpCol    ; ������һ
			.ENDIF

			mov edi,tP
			mov [edi],ebx ; д�뵽����
			add tP,TYPE DWORD        ; ָ�����
			inc esi
			mov ebx,0

		.ELSEIF buffer[esi] == 0dh; �ǻ��з� һ���س����а��������ַ�:0dh 0ah
			inc tmpRow  ; ������һ

			mov edi,tP
			mov [edi],ebx ; д�뵽����
			mov ebx,0
			add tP,TYPE DWORD        ; ָ�����
			add esi,2
			
		.ELSE ; ������
			; ASCII�� ���� 30h ������ ��Ӧ������ֵ DIV ָ��
			movzx eax,buffer[esi] ;������ַ�����edi
			mov ecx,30h ; EAX/ECX --> ��EAX ����EDX
			div ecx  
			
			mov edi,edx

			mov eax,10 ; EBX���ݴ�ĺͳ���10 --> EAX
			mul ebx
			mov ebx,eax ; ���EBX

			add ebx,edi
			inc esi

		.ENDIF
		
	.ENDW
	inc tmpCol
	ret
loadMatrix ENDP


; ����A�����һ�зֱ��B�����ÿһ�� (����ѭ��)
calOneRow PROC USES ecx

	mov ecx,bCol ; �������ѭ����
	mov eax,pA
	mov rpA,eax  ; �ݴ�pA

L1:				 ; ���ѭ��
	mov eax,pB
	mov rpB,eax  ; �ݴ�pB

	mov ebx,0    ; �ۼӺ�
	mov tmp,ecx
	mov ecx,aCol ; �����ڲ�ѭ����
	
	L2:          ; �ڲ�ѭ��
		mov esi,pA
		mov eax,[esi] ; pA ��ָ���� --> EAX

		mov esi,pB
		mov edx,[esi]
		mul edx   ; pB ��ָ����*EAX --> EAX
		add ebx,eax ; ���ֺ� --> EBX

		add pA,TYPE mA  ; pA�����ƶ�

		mov eax,offsetB
		add pB,eax  ; pB�����ƶ�

		loop L2

	mov edi,pC
	mov [edi],ebx   ; д��C����
	add pC,TYPE mC  ; pC����

	mov eax,rpA  ; �ָ�pA
	mov pA,eax
	
	mov eax,rpB
	add eax,TYPE mB
	mov pB,eax   ; pBָ����һ��

	mov ecx,tmp  ; �ָ����ѭ��ֵ
	loop L1
	
	mov eax,OFFSET mB
	mov pB,eax   ; pB����ָ�� B����

	ret
calOneRow ENDP

; �Ծ���A��ÿһ�е���calOneRow , �ó����ս��
calRows PROC
	mov ecx,aRow
	
L1:
	push ecx       ;  !!!��Ҫ
	call calOneRow
	mov eax,pA

	mov eax,aCol
	mov edx,TYPE mA
	mul edx
	add pA,eax

	pop ecx    ; !!! ��Ҫ
	loop L1
	
	ret
calRows ENDP


writeMatrix PROC
; �ӻ�����������ļ�, ��edx�������ļ�·��
	call CreateOutputFile
	
	mov edx,OFFSET buffer
	mov ecx,tmp ; �˴����ļ�����
	call WriteToFile
	call CloseFile 
	ret
writeMatrix ENDP

dumpMatrix PROC USES esi
; DWORD ����ת���ַ�����д�뻺����
	mov ebx,bCol
	mov eax,aRow
	mul ebx
	mov ecx,eax  ; C������Ԫ����
	mov tmpCol,0
	mov pC,OFFSET mC
	mov esi,0

L1:
	
	mov edx,pC
	mov eax,[edx]
	
	inc tmpCol

	mov ebx,10    ; ebxΪ����
	mov edx,0
	mov edi,0     ; ����,��¼ѹջ����
    jmp TESTING
FORLOOP:
    xor edx,edx   ; ������(����edx),32λ������ʱ���������edx��ʹ��ǰҪ����
    div ebx       ; eax = eax/10 ����eax�У�������edx
    add dl, 30h   ; ������ת�����ַ�
	push dx
    inc edi

TESTING:
    cmp eax,0    ; ������ �����eax
    jne FORLOOP  ; ��������ת


	.WHILE edi > 0  ; ��γ�ջ
		pop dx
		mov buffer[esi],dl
		inc esi
		dec edi
	.ENDW

	mov buffer[esi],20h ; д�ո�
	inc esi

	mov edx,bCol

	.IF tmpCol == edx
		; д��س����з�
		mov buffer[esi],0dh
		inc esi
		mov buffer[esi],0ah
		inc esi
		mov tmpCol,0
	.ENDIF


	add pC,TYPE mC     ; ָ�����,ָ����һ�� DWORD��
	loop L1
	mov buffer[esi],0  ; д�������
	mov tmp,esi
	ret
dumpMatrix ENDP

END main


printMatrix PROC

	mov edi,0
	mov ecx,aRow ; ���ѭ����
L0:
	mov tmp,ecx  ; �������ѭ����
	mov ecx,bCol ; �ڲ�ѭ����
	
	L2:
		
		mov eax,mC[edi]
		call WriteDec   ; ��ӡʮ������
		mov al,32
		call WriteChar  ; ��ӡ�ո�

		add edi,TYPE mC
		loop L2

	; д��س����з�
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar

	mov ecx,tmp
	loop L0
	ret
printMatrix ENDP