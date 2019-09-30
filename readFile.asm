.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO,dwExitCode:DWORD

INCLUDE Irvine32.inc
INCLUDE macros.inc
BUFFER_SIZE = 5000

.data
buffer BYTE BUFFER_SIZE DUP(?)
filename BYTE 80 DUP(?)
fileHandle HANDLE ?

.code
main PROC

; �û������ļ���
	mWrite "enter an input filename!"
	mov edx,OFFSET filename
	mov ecx,SIZEOF filename
	call ReadString

; ���ļ���������
	mov edx,OFFSET filename
	call OpenInputFile
	mov fileHandle,eax
; ������
	cmp eax,INVALID_HANDLE_VALUE ; ������ļ�?
	jne file_ok ; �� ����
	mWrite <"Cannot open file",0dh,0ah>
	jmp quit  ; �˳�
file_ok:
; ���ļ����뻺����
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	jnc check_buffer_size  ; �����ȡ?
	mWrite "Error reading file" ; ��,��ʾ������Ϣ
	call WriteWindowsMsg
	jmp close_file

check_buffer_size:
	cmp eax,BUFFER_SIZE  ; �������㹻��
	jb  buf_size_ok      ; ��
	mWrite <"Error:Buffer too small",0dh,0ah>
	jmp quit

buf_size_ok:
	mov buffer[eax],0  ; ����ս�����
	mWrite "File size:"
	call WriteDec  ; ��ʾ�ļ���С
	call Crlf
; ��ʾ������
	mWrite <"Buffer:",0dh,0ah,0dh,0ah>
	mov edx,OFFSET buffer  ; ��ʾ������
	cal WriteString
	call crlf

close_file:
	mov eax,fileHandle
	call CloseFile

quit:
	exit
main ENDP
END main


