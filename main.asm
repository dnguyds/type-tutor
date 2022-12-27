INCLUDE Irvine32.inc
INCLUDE macros.inc

BUFFER_SIZE = 2000
SCORE_BUFFER_SIZE = 100
ENTER_KEY = 13
BACKSPACE = 8
SPACE = 32
TAB = 9
PERCENTAGE = 10000
MINUTE = 60000			; in milliseconds
HALFSECOND = 500
TENSECONDS = 10000
MAXTIME = 4294967295
START_OF_PROMPT_X = 0
START_OF_PROMPT_Y = 2
TIMER_X = 0
TIMER_Y = 1
AVERAGE_CHAR_PER_WORD = 5
LETTERS_IN_ALPHABET = 26

.data
	MainMenu	BYTE '1'
				DWORD	Practice_Proc
	MainMenuSize = ($ - MainMenu)
				BYTE '2'
				DWORD	Training_Proc
				BYTE '3'
				DWORD	Timed_Proc
				BYTE '4'
				DWORD	Exit_Proc
	NumberOfMainMenuEntries = ($ - MainMenu) / MainMenuSize

	mainMenuPrompt  BYTE "What would you like to do today?", 13, 10,
					 "1. Practice a letter", 13, 10,
					 "2. Train your typing skills", 13, 10,
					 "3. Take a timed test", 13, 10,
					 "4. Exit program", 13, 10,
					 "> ", 0

	CharMenu	BYTE 'A'
				DWORD	A_Proc
	CharMenuSize = ($ - CharMenu)
				BYTE 'B'
				DWORD	B_Proc
				BYTE 'C'
				DWORD	C_Proc
				BYTE 'D'
				DWORD	D_Proc
				BYTE 'E'
				DWORD	E_Proc
				BYTE 'F'
				DWORD	F_Proc
				BYTE 'G'
				DWORD	G_Proc
				BYTE 'H'
				DWORD	H_Proc
				BYTE 'I'
				DWORD	I_Proc
				BYTE 'J'
				DWORD	J_Proc
				BYTE 'K'
				DWORD	K_Proc
				BYTE 'L'
				DWORD	L_Proc
				BYTE 'M'
				DWORD	M_Proc
				BYTE 'N'
				DWORD	N_Proc
				BYTE 'O'
				DWORD	O_Proc
				BYTE 'P'
				DWORD	P_Proc
				BYTE 'Q'
				DWORD	Q_Proc
				BYTE 'R'
				DWORD	R_Proc
				BYTE 'S'
				DWORD	S_Proc
				BYTE 'T'
				DWORD	T_Proc
				BYTE 'U'
				DWORD	U_Proc
				BYTE 'V'
				DWORD	V_Proc
				BYTE 'W'
				DWORD	W_Proc
				BYTE 'X'
				DWORD	X_Proc
				BYTE 'Y'
				DWORD	Y_Proc
				BYTE 'Z'
				DWORD	Z_Proc
	NumberOfCharMenuEntries = ($ - CharMenu) / CharMenuSize

	titleStr						BYTE	"Type Tutor", 0
	buffer							BYTE	BUFFER_SIZE DUP(?)
	directoryName					BYTE	"C:\Users\miyus\source\repos\MASM\"
	filename						BYTE	80 DUP (?)
	fileHandle						HANDLE	?
	bufferSize						DWORD	?
	consoleInfo						CONSOLE_SCREEN_BUFFER_INFO <>
	outHandle						HANDLE	?
	bufferEndX						BYTE	?
	bufferEndY						BYTE	?
	currentBufferX					BYTE	?
	currentBufferY					BYTE	?
	screenSizeX						BYTE	?
	screenSizeY						BYTE	?
	wrongStreak						BYTE	0
	correctInputs					DWORD	?
	totalInputs						DWORD	?
	accuracy						BYTE	6 DUP(?), 0
	startTime						DWORD	?
	timer							DWORD	?
	elapsedMS						DWORD	?
	atBeforeMaxScreenX				DWORD	FALSE
	atMaxScreenX					DWORD	FALSE
	beforeMaxScreenX_xPos			BYTE	?
	backspaceAtBeforeMaxScreenX		DWORD	FALSE
	playAgainPrompt					BYTE	"Would you like to continue typing?", 13, 10,
											"1. Yes", 13, 10,
											"2. No", 13, 10,
											"> ", 0
	scoreFilename					BYTE	"C:\Users\miyus\source\repos\MASM\scores.txt", 0
	scoreFileHandle					HANDLE	?
	scoreBuffer1					BYTE	"Accuracy: ", 0
	scoreBuffer2					BYTE	"WPM: ", 0
	wordsPerMinute					BYTE	4 DUP (?), 0
	scoreOutput						BYTE	SCORE_BUFFER_SIZE DUP(?), 13, 10
	scoreOutputIndex				DWORD	?
	timesUpPrompt					BYTE	"Time's up!", 0
	playedOnce						DWORD	FALSE

.code
main PROC

	INVOKE SetConsoleTitle, ADDR titleStr	; set the title of the console window
	mWrite <"Welcome to the Type Tutor!">

main_menu_select:
	; Display the main menu and execute the user-chosen procedure.
	call Crlf
	call Crlf
	mov edx, OFFSET mainMenuPrompt
	mov esi, OFFSET MainMenu
	mov edi, NumberOfMainMenuEntries
	mov ebx, MainMenuSize
	call DisplayMainMenu

; Read and store from user-chosen.
	call ReadAndStoreFile
	call Clrscr

; Display the countdown until the game starts.
	mov ecx, 3							; number to start counting down from
	call DisplayCountdown

; Display the file.
	mov eax, black + (white * 16)		; black on white
	call SetTextColor
	mWriteString buffer					; display the buffer

; Store the position of the cursor at the end of buffer display.
	invoke GetStdHandle, STD_OUTPUT_HANDLE								; get console screen handle
	mov outHandle,eax													; store console screen handle
	invoke GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo		; get console info
	mov ax, consoleInfo.dwCursorPosition.X
	mov bufferEndX, al
	mov ax, consoleInfo.dwCursorPosition.Y
	mov bufferEndY, al

; Store the console screen size.
	mov ax, consoleInfo.dwSize.X
	mov screenSizeX, al
	dec al
	mov beforeMaxScreenX_xPos, al
	mov ax, consoleInfo.dwSize.Y
	mov screenSizeY, al

; Set up the game.
	mov esi,0							; ESI = index of buffer
	mGotoxy START_OF_PROMPT_X, START_OF_PROMPT_Y

	INVOKE GetTickCount					; get starting tick count
	mov startTime,eax					; save it

game_in_progress:
	read_input:
		INVOKE GetTickCount				; get new tick count
		sub eax,startTime				; get elapsed milliseconds
		mov elapsedMS, eax				; store elapsed milliseconds
		cmp eax,timer					; is the timer up?
		ja end_of_game					; yes: go to end_of_game

	; Decrement the timer display.
		mov eax, black + (white * 16)	; black on white
		call SetTextColor

		; Store current buffer position.
		invoke GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo
		mov ax, consoleInfo.dwCursorPosition.X
		mov currentBufferX, al

		; Account for crlf in buffer.
		mov dl, beforeMaxScreenX_xPos
		cmp al, dl									; AL = max screen size X - 1?
		jne determine_y_pos_in_buffer				; no: go to determine_y_pos_in_buffer
		cmp backspaceAtBeforeMaxScreenX, TRUE		; was there a backspace?
		je determine_y_pos_in_buffer				; yes: go to determine_y_pos_in_buffer (don't allow crlf)
		mov atBeforeMaxScreenX, TRUE				; no: atBeforeMaxScreenX = TRUE
		cmp atMaxScreenX, TRUE						; second input read?
		jne determine_y_pos_in_buffer				; no: go to determine_y_pos_in_buffer
		mov currentBufferX, 0						; yes: crlf
		mov atBeforeMaxScreenX, FALSE
		mov atMaxScreenX, FALSE
		mov ax, consoleInfo.dwCursorPosition.Y
		inc al
		mov currentBufferY, al
		jmp calculate_elapsed_time

		determine_y_pos_in_buffer:
			mov ax, consoleInfo.dwCursorPosition.Y
			mov currentBufferY, al

		calculate_elapsed_time:
		mov eax, timer
		mov ebx, elapsedMS
		sub eax, ebx					; EAX = timer - elapsedMS
		mov edx, 0
		mov ebx, 1000
		div ebx							; EAX = (timer - elapsedMS) / 1000
		mGotoxy TIMER_X, TIMER_Y
		call WriteDec

		; Account for decrease in timer digits.
		cmp eax, 9						; EAX == 9?
		jne check_if_timer_is_99
		mWrite SPACE

		check_if_timer_is_99:
			cmp eax, 99						; EAX == 99?
			jne enter_char
			mWrite SPACE

		enter_char:
		; Go back to current position in buffer.
			mGotoxy currentBufferX, currentBufferY
			mov eax, 1					; create 1 ms delay
			call Delay
			call ReadKey
			jz read_input

		input_at_max_screen_width:
		cmp atBeforeMaxScreenX, TRUE		; current pos == max screen X?
		jne check_for_backspace
		mov atMaxScreenX, TRUE

	check_for_backspace:
		cmp al, BACKSPACE				; user pressed backspace?
		jne check_char					; no: go to check_char
		mWrite <BACKSPACE>				; yes: backspace
		sub esi, TYPE buffer			; go back in buffer to match backspace

		; Account for backspaces over the position before max screen X.
		mov ax, consoleInfo.dwCursorPosition.X
		mov dl, beforeMaxScreenX_xPos
		cmp al, dl									; AL == max screen size X - 1?
		jne check_if_backspace_to_prev_line			; no: go to check_if_backspace_to_prev_line
		mov backspaceAtBeforeMaxScreenX, TRUE		; yes: backspaceAtBeforeMaxScreenX = TRUE
		mov atBeforeMaxScreenX, FALSE

		check_if_backspace_to_prev_line:
			cmp currentBufferX, 0				; backspace at X==0?
			jne game_in_progress				; no: normal backspace
			mov dl, beforeMaxScreenX_xPos		; yes: undo crlf
			mov currentBufferX, dl
			mov dx, consoleInfo.dwCursorPosition.Y
			dec dl
			mov currentBufferY, dl
			mGotoxy currentBufferX, currentBufferY
			jmp game_in_progress

	check_char:
		cmp backspaceAtBeforeMaxScreenX, TRUE
		jne see_if_correct
		mov backspaceAtBeforeMaxScreenX, FALSE
		mov atBeforeMaxScreenX, FALSE
		mov atMaxScreenX, FALSE

	see_if_correct:
	; ZF = 1 if characters match, otherwise ZF = 0
		mov bl, buffer[esi]
		cmp al, bl						; input char == buffer char ?
		jz char_is_correct				; yes: go to char_is_correct

	char_is_incorrect:
		push eax						; save input char
		mov eax, white + (red * 16)		; no: white on red
		call SetTextColor
		pop eax
		call WriteChar					; echo the incorrect char
		mov eax, 100					; create a 100 ms delay
		call Delay
		mWrite <BACKSPACE>
		mov eax, black + (red * 16)
	; Increase the wrong streak.
		mov bl, wrongStreak
		inc bl
		mov wrongStreak, bl
		jmp write_char

	char_is_correct:
		mov eax, black + (green * 16)	; black on green
	; Reset the wrong streak.
		mov bl, 0
		mov wrongStreak, bl
	; Increase the correct input counter.
		mov ebx, correctInputs
		inc ebx
		mov correctInputs, ebx

	write_char:
		call SetTextColor
		mov al, BYTE PTR buffer[esi]
		call WriteChar
	; Increase the total input counter.
		mov ebx, totalInputs
		inc ebx
		mov totalInputs, ebx
	; If two chars in a row are incorrect, prevent user from progressing
	; until they enter the correct char.
		mov bl, wrongStreak
		cmp bl, 2						; wrongStreak >= 2?
		jb read_next_char				; no: go to read_next_char
		mWrite <BACKSPACE>				; yes: stay on that char
		jmp game_in_progress

	read_next_char:
		add esi, TYPE buffer			; move index to next char in buffer
	
	; Loop until end of buffer is reached.
		cmp esi, bufferSize
		je end_of_game
jne game_in_progress

end_of_game:
	mGotoxy bufferEndX, bufferEndY
	call Crlf
	call Crlf
	mov eax, black + (white * 16)		; black on white
	call SetTextColor
	INVOKE GetTickCount					; get new tick count
	sub eax,startTime					; get elapsed milliseconds
	cmp eax,timer						; is the timer up?
	jbe display_results					; no: go to display_results
	mWriteString timesUpPrompt
	call Crlf

display_results:

; Check if totalInputs = 0
	cmp totalInputs, 0					; check if accuracy == 0
	jne check_for_100
	mov accuracy, "0"
	mov accuracy+1, "%"
	jmp write_accuracy

check_for_100:
	mov eax, correctInputs
	mov ebx, PERCENTAGE
	mul ebx								; correctInputs * 100
	div totalInputs						; correctInputs * 100 / totalInputs
	mWriteString scoreBuffer1

	cmp eax, ebx						; correctInputs == totalInputs?
	jne	calculate_accuracy				; no: go to calculate_accuracy
	mov accuracy, "1"					; yes: move "100%" into accuracy
	mov accuracy+1, "0"
	mov accuracy+2, "0"
	mov accuracy+3, "%"
	jmp write_accuracy

calculate_accuracy:
	mov ecx, 4							; loop counter
	mov ebx, 10							; divisor to move to next digit
	mov edi, 4							; array index
	store_accuracy:						; store accuracy in byte array
		mov edx, 0						; clear EDX
		div ebx							; EDX:EAX / EBX to get rightmost digit of accuracy
		add edx, '0'					; get char value for number
		mov accuracy[edi], dl			; move remainder into accuracy array, right to left
		dec edi							; move left in accuracy array
		cmp ecx, 3						; loop counter == 1?
		jne end_of_store_accuracy_loop	; no: continue loop
		mov accuracy[edi], "."			; yes: move a "." into accuracy
		dec edi
		end_of_store_accuracy_loop:
	loop store_accuracy
	mov accuracy+5, "%"

write_accuracy:
	mWriteString accuracy

calculate_wpm:
	call Crlf
	mWriteString scoreBuffer2

	; totalInputs / average_char_per_word
	mov eax, totalInputs
	mov edx, 0
	mov ebx, AVERAGE_CHAR_PER_WORD
	div ebx

	; totalInputs / average_char_per_word * milliseconds_in_min
	mov edx, 0
	mov ebx, MINUTE
	mul ebx

	; totalInputs / average_char_per_word * milliseconds_in_min / elapsedMS
	mov ebx, elapsedMS
	div ebx

	call WriteDec

	mov ebx, 10							; num to divide by
	mov edi, 4
	mov ecx, 4
	store_wpm:							; store wpm in byte array
		cmp eax, 0						; eax == 0?
		je end_of_store_wpm_loop		; yes: exit loop
		mov edx, 0						; clear EDX
		div ebx							; EDX:EAX / EBX to get rightmost digit of wpm
		add edx, '0'					; get char value for number
		mov wordsPerMinute[edi], dl		; move remainder into accuracy array, right to left
		dec edi							; move left in wpm array
		end_of_store_wpm_loop:
	loop store_wpm

; Add all score elements to scoreBuffer.
	mov esi, OFFSET scoreBuffer1		; source buffer address
	mov edi, OFFSET scoreOutput			; destination buffer address
	mov ebx, scoreOutputIndex			; destination buffer index
	call MoveIntoBuffer
	mov scoreOutputIndex, ebx

	mov ebx, scoreOutputIndex
	mov esi, OFFSET accuracy			; source buffer address
	call MoveIntoBuffer
	mov scoreOutputIndex, ebx
	
	mov ebx, scoreOutputIndex
	mov al, TAB
	mov [esi+ebx], al					; put a tab into scoreOutput
	inc scoreOutputIndex

	mov ebx, scoreOutputIndex
	mov esi, OFFSET scoreBuffer2
	call MoveIntoBuffer
	mov scoreOutputIndex, ebx

; Store wpm into buffer.
	mov ecx, LENGTHOF wordsPerMinute
	mov esi, OFFSET wordsPerMinute
	move_wpm_into_buffer:
		mov al, [esi]
		cmp al, 0						; AL = 0?
		je end_of_move_wpm_into_buffer
		mov [edi+ebx], al
		inc ebx
		end_of_move_wpm_into_buffer:
		inc esi
	loop move_wpm_into_buffer
	mov scoreOutputIndex, ebx

; Open score file and store file handle.
	INVOKE CreateFile, ADDR scoreFilename, GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
	mov scoreFilehandle, eax

; Check for errors.
	cmp eax,INVALID_HANDLE_VALUE		; error opening file?
	jne file_ok							; no: skip
	mWrite <"Cannot open score file", 13, 10>
	jmp end_of_program						; and skip file writing change to play_again

file_ok:
	; Append input to end of file.
	INVOKE SetFilePointer,
		scoreFilehandle,				; file handle
		0,								; distance low
		0,								; distance high
		FILE_END						; move method

	mov eax, scoreFilehandle
	mov edx, OFFSET scoreOutput
	mov ecx, LENGTHOF scoreOutput
	INVOKE WriteToFile

; Close the file.
	INVOKE CloseHandle, scoreFilehandle

; Set text colors back to normal.
	call Crlf
	mov eax, green + (black * 16)		; green on black
	call SetTextColor

play_again:
	call Crlf
	cmp playedOnce, TRUE				; already played once?
	je end_of_program
	mov playedOnce, TRUE
	mWriteString playAgainPrompt		; display playAgainPrompt
	call ReadChar						; read char into AL
	call WriteChar						; echo char onto screen
	cmp al, '1'							; input == '1'?
	jne is_two							; no: check if input == '2'
	mov edi, OFFSET buffer				; yes: clear buffer and go back to main menu
	mov ecx, BUFFER_SIZE
	call ClearArray
	mov edi, OFFSET wordsPerMinute
	mov ecx, LENGTHOF wordsPerMinute
	call ClearArray
	jmp main_menu_select
	
	is_two:
		cmp al, '2'							; input == 2?
		je end_of_program					; yes: go to end of game
	mWrite <13, 10, "Invalid input.", 13, 10, 13, 10>	; no: show menu again
	jmp play_again

end_of_program:
	call Crlf
	mWrite "Good job today!"

	exit
main ENDP

;-----------------------------------------------
MoveIntoBuffer PROC
; Transfers items from one buffer into another,
; while the element is not zero.
; Receives: ESI = offset of source buffer,
;			EDI = offset of destination buffer,
;			EBX = index of destination buffer
; Returns: EBX = new index of destination buffer
;-----------------------------------------------
; Store all registers used.
	push esi
	push edi

L1:
	mov al, [esi]
	cmp al, 0			; AL = 0?
	je L2
	mov [edi+ebx], al
	inc esi
	inc ebx
	jmp L1

L2:
; Restore all registers used.
	pop edi
	pop esi
	
	ret
MoveIntoBuffer ENDP

;-----------------------------------------------
ClearArray PROC
; Clear a byte array, filling it with 0s.
; Receives: EDI = address of the buffer,
;			ECX = size of buffer
;-----------------------------------------------
L1:
	mov BYTE PTR [edi], 0
	inc edi
loop L1
	ret
ClearArray ENDP

;-----------------------------------------------
DisplayMainMenu PROC
; Displays the main menu and calls the
; user-picked procedure.
; Receives: EDX = address of menu prompt,
;			ESI = address of the menu,
;			EDI = number of menu entries,
;			EBX = size of table row
; Returns: nothing
;-----------------------------------------------
; Save all registers used.
	push edx
	push esi
	push edi
	push ebx
	push eax

display_menu:
	mov eax, 0					; clear EAX
	call WriteString			; display prompt
	call ReadChar				; read char into AL
	call WriteChar				; echo char onto screen
	sub al, '1'					; get value of char
	and eax, 00000011b			; clear everything outside of AL
	cmp eax, edi				; choice <= number of menu entries?
	jb call_menu_proc			; yes: call corresponding proc
	mWrite <13, 10, "Invalid input.", 13, 10, 13, 10>	; no: show menu again
	jmp display_menu

call_menu_proc:
	call Crlf
	mul bl						; AX = AL x BL
	add esi, eax
	call NEAR PTR [esi+1]		; call the corresponding procedure

; Restore all registers used.
	pop eax
	pop ebx
	pop edi
	pop esi
	pop edx

	ret
DisplayMainMenu ENDP

;-----------------------------------------------
ReadAndStoreFile PROC USES edx ecx eax
; Opens, reads, and stores a text file using
; procedures from Irvine32.lib.
; Receives: nothing
; Returns: nothing
;-----------------------------------------------
; Open the file for input.
	mov edx,OFFSET filename
	call OpenInputFile
	mov fileHandle,eax

; Check for errors.
	cmp eax,INVALID_HANDLE_VALUE		; error opening file?
	jne file_ok							; no: skip
	mWrite <"Cannot open file", 0dh, 0ah>
	jmp quit							; and quit

file_ok:
; Read the file into a buffer.
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	jnc check_buffer_size				; error reading?
	mWrite "Error reading file."		; yes: show error message
	call WriteWindowsMsg
	jmp close_file

check_buffer_size:
	cmp eax,BUFFER_SIZE					; buffer large enough?
	jb buf_size_ok						; yes
	mWrite <"Error: Buffer too small for the file", 0dh, 0ah>
	jmp quit							; and quit

buf_size_ok:
	mov buffer[eax], 0					; insert null terminator
	mov bufferSize, eax					; store size of buffer

close_file:
	mov eax,fileHandle
	call CloseFile

quit:
	ret
ReadAndStoreFile ENDP

;----------------------------------------------------
DisplayCountdown PROC
; Displays a countdown with three dots between
; each number.
; Receives: ECX = number to start counting down from
; Requires: nothing
;----------------------------------------------------
; Save all registers used.
	push ecx
	push eax

; Display the countdown.
	mov eax,ecx
	write_countdown_num:
		push eax
		mov eax,HALFSECOND
		call Delay
		pop eax
		call WriteDec
		push eax
		push ecx
		mov ecx, 3						; how many dots displayed after countdown
		mov eax,HALFSECOND
		write_countdown_dots:
			call Delay
			mWrite "."
		loop write_countdown_dots
		pop ecx
		pop eax
		dec eax
	loop write_countdown_num
	mWrite <"GO!", 13, 10, 13, 10>

; Restore all registers used.
	pop eax
	pop ecx

	ret
DisplayCountdown ENDP

;-----------------------------------------------
Exit_Proc PROC
; Exits the program.
; Receives: nothing
; Returns: nothing
;-----------------------------------------------
	exit
Exit_Proc ENDP

;-----------------------------------------------
Practice_Proc PROC
; Displays the practice menu and stores the
; user-chosen file into filename.
; Receives: nothing
; Returns: nothing
;-----------------------------------------------
; Save all registers used.
	push eax
	push ebx

	mov timer, (MINUTE * 3)

display_menu:
	mWrite "What letter do you want to practice? Enter letter as lowercase."
	call Crlf
	mWrite "> "
	call ReadChar
	call WriteChar

	push eax
	mov eax, 1000				; create a 1000ms delay
	call Delay
	pop eax

	sub al, 'a'					; get value of char
	cmp al, LETTERS_IN_ALPHABET	; choice is letter in alphabet?
	jbe call_menu_proc			; yes: call corresponding proc

display_invalid_msg:
	mWrite <13, 10, "Invalid input.", 13, 10, 13, 10>
	jmp display_menu

call_menu_proc:
	call Crlf
	mov bl, CharMenuSize			; size of table row
	mul bl							; AX = AL x BL
	mov ebx, OFFSET CharMenu		; EBX = address of charmenu
	add ebx, eax
	call NEAR PTR [ebx+1]			; call the corresponding procedure

; Add file type.
	mov filename+1, "."
	mov filename+2, "t"
	mov filename+3, "x"
	mov filename+4, "t"

; Restore all registers used.
	pop ebx
	pop eax

	ret
Practice_Proc ENDP

A_Proc PROC
	mov filename, "a"
	ret
A_Proc ENDP

B_Proc PROC
	mov filename, "b"
	ret
B_Proc ENDP

C_Proc PROC
	mov filename, "c"
	ret
C_Proc ENDP

D_Proc PROC
	mov filename, "d"
	ret
D_Proc ENDP

E_Proc PROC
	mov filename, "e"
	ret
E_Proc ENDP

F_Proc PROC
	mov filename, "f"
	ret
F_Proc ENDP

G_Proc PROC
	mov filename, "g"
	ret
G_Proc ENDP

H_Proc PROC
	mov filename, "h"
	ret
H_Proc ENDP

I_Proc PROC
	mov filename, "i"
	ret
I_Proc ENDP

J_Proc PROC
	mov filename, "j"
	ret
J_Proc ENDP

K_Proc PROC
	mov filename, "k"
	ret
K_Proc ENDP 
 
L_Proc PROC 
	mov filename, "l"
	ret
L_Proc ENDP 
 
M_Proc PROC 
	mov filename, "m"
	ret
M_Proc ENDP 
 
N_Proc PROC 
	mov filename, "n"
	ret
N_Proc ENDP 
 
O_Proc PROC 
	mov filename, "o"
	ret
O_Proc ENDP 
 
P_Proc PROC 
	mov filename, "p"
	ret
P_Proc ENDP 

Q_Proc PROC
	mov filename, "q"
	ret
Q_Proc ENDP 

R_Proc PROC
	mov filename, "r"
	ret
R_Proc ENDP 

S_Proc PROC
	mov filename, "s"
	ret
S_Proc ENDP 

T_Proc PROC
	mov filename, "t"
	ret
T_Proc ENDP 

U_Proc PROC
	mov filename, "u"
	ret
U_Proc ENDP 

V_Proc PROC
	mov filename, "v"
	ret
V_Proc ENDP  

W_Proc PROC
	mov filename, "w"
	ret
W_Proc ENDP  

X_Proc PROC
	mov filename, "x"
	ret
X_Proc ENDP  

Y_Proc PROC
	mov filename, "y"
	ret
Y_Proc ENDP  

Z_Proc PROC
	mov filename, "z"
	ret
Z_Proc ENDP

;-----------------------------------------------
Training_Proc PROC
; Displays the training menu and stores the
; user-chosen file into filename.
; Receives: nothing
; Returns: nothing
;-----------------------------------------------
; Save all registers used.
	push eax

	mov timer, (MINUTE * 3)

display_prompt:
	mWrite <"Select a difficulty", 13, 10>
	mWrite <"1. Easy", 13, 10>
	mWrite <"2. Medium", 13, 10>
	mWrite <"3. Hard", 13, 10>
	mWrite "> "
	call ReadChar
	call WriteChar

	cmp al, '1'			; is the choice 1?
	jne is_two			; no: go to is_two
	mov filename, "a"
	mov filename+1, "1"
	jmp quit

	is_two:
		cmp al, '2'
		jne is_three
		mov filename, "a"
		mov filename+1, "2"
		jmp quit
	is_three:
		cmp al, '3'
		jne invalid_choice
		mov filename, "a"
		mov filename+1, "3"
		jmp quit

	invalid_choice:
		mWrite <13, 10, "Invalid input.", 13, 10, 13, 10>
		jmp display_prompt

	quit:
		mov filename+2, "."
		mov filename+3, "t"
		mov filename+4, "x"
		mov filename+5, "t"

; Restore all registers used.
	pop eax

		ret
Training_Proc ENDP

;-----------------------------------------------
Timed_Proc PROC
; Displays the timed menu and stores the
; user-chosen file into filename.
; Receives: nothing
; Returns: nothing
;-----------------------------------------------
; Save all registers used.
	push eax

display_prompt:
	mWrite <"Select a time limit", 13, 10>
	mWrite <"1. 1 minute", 13, 10>
	mWrite <"2. 2 minutes", 13, 10>
	mWrite <"3. 3 minutes", 13, 10>
	mWrite "Your choice > "
	call ReadChar
	call WriteChar

	cmp al, '1'			; is the choice 1?
	jne is_two			; no: go to is_two
	mov timer, MINUTE
	mov filename, "b"
	jmp quit

	is_two:
		cmp al, '2'
		jne is_three
		mov timer, (MINUTE * 2)
		mov filename, "b"
		jmp quit
	is_three:
		cmp al, '3'
		jne invalid_choice
		mov timer, (MINUTE * 3)
		mov filename, "b"
		jmp quit

	invalid_choice:
		mWrite <13, 10, "Invalid input.", 13, 10, 13, 10>
		jmp display_prompt

	quit:
		call Randomize
		mov eax, 9
		call RandomRange			; get random 0-9
		add eax, '0'
		mov filename+1, al
		mov filename+2, "."
		mov filename+3, "t"
		mov filename+4, "x"
		mov filename+5, "t"

; Restore all registers used.
	pop eax

		ret
Timed_Proc ENDP

END main