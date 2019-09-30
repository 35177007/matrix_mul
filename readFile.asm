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

; 用户输入文件名
	mWrite "enter an input filename!"
	mov edx,OFFSET filename
	mov ecx,SIZEOF filename
	call ReadString

; 打开文件进行输入
	mov edx,OFFSET filename
	call OpenInputFile
	mov fileHandle,eax
; 错误检查
	cmp eax,INVALID_HANDLE_VALUE ; 错误打开文件?
	jne file_ok ; 否 跳过
	mWrite <"Cannot open file",0dh,0ah>
	jmp quit  ; 退出
file_ok:
; 将文件读入缓冲区
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	jnc check_buffer_size  ; 错误读取?
	mWrite "Error reading file" ; 是,显示错误消息
	call WriteWindowsMsg
	jmp close_file

check_buffer_size:
	cmp eax,BUFFER_SIZE  ; 缓冲区足够大
	jb  buf_size_ok      ; 是
	mWrite <"Error:Buffer too small",0dh,0ah>
	jmp quit

buf_size_ok:
	mov buffer[eax],0  ; 插入空结束符
	mWrite "File size:"
	call WriteDec  ; 显示文件大小
	call Crlf
; 显示缓存区
	mWrite <"Buffer:",0dh,0ah,0dh,0ah>
	mov edx,OFFSET buffer  ; 显示缓冲区
	cal WriteString
	call crlf

close_file:
	mov eax,fileHandle
	call CloseFile

quit:
	exit
main ENDP
END main


