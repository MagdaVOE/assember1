segment code

..start:				;punkt wejsciowy programu (dla linkera VAL)
	mov ax,data			;inicjalizacja rejestrow - to jest standard
	mov ds,ax			;data segment
	mov es,ax			;dodatkowa inicjalizacja dla ekstra segment
	mov ax,stack		;ustawienie stosu
	mov ss,ax			;stack segment
	mov sp,stacktop		;stack pointer -> wierzcholek stosu

;kod uzytkownika
;******************************************************************************
;komunikat 0
	mov dx,komunikat0
	call print
	call nowalinia
;komunikat 1
	mov dx,komunikat1
	call print
;pobieranie pierwszej liczby
	mov dx,liczba
	call pobierz
	call nowalinia
;konwersja liczby
	mov ax,liczba
	call napisliczba
	mov [liczba],bx
	mov [y],bx
;kwadrat liczby
	mov ax,[y]			;pobranie wartosci zmiennych
	mul ax					;w ax kwadrat
	mov [wynik],ax			;kwadrat w zmiennej "wynik"
;wyswietlenie wyniku 
	mov dx,komunikat2
	call print
	mov ax,[wynik]			;wartosc zmiennej "wynik"
	mov bx, liczbaS			;adres bufora do zapisania
	call liczbanapis		;funkcja konwertujaca int->string
	mov dx,liczbaS			;adres wyswietlanego napisu do DX
	call print				;funkcja drukujaca
	call nowalinia
;szescian liczby
	mov ax,[y]			;pobranie wartosci zmiennych
	mov bx,ax
	mov cx,2				;w cx licznik petli (na wypadek np. 17 potegi)
potegowanie:
	mul bx					;w ax kwadrat, szescian, 4, 5 itd.
	loop potegowanie				
	mov [wynik],ax			;szescian w zmiennej "wynik"
;wyswietlenie wyniku 
	mov dx,komunikat3
	call print
	mov ax,[wynik]			;wartosc zmiennej "wynik"
	mov bx, liczbaS			;adres bufora do zapisania
	call liczbanapis		;funkcja konwertujaca int->string
	mov dx,liczbaS			;adres wyswietlanego napisu do DX
	call print				;funkcja drukujaca
	call nowalinia
;reszta mod 3
	xor ax,ax
	xor dx,dx
	mov ax,[y]				;pobranie wartosci zmiennych
	mov bx,3				;w bx dzielnik
	idiv bx					;w ax wynik dzielenia calkowitego w dx reszta z dzielenia
	mov [wynik],dx			;reszta w zmiennej "wynik"
;wyswietlenie wyniku 
;pierwsza czesc
	mov dx,komunikat4
	call print
	mov ax,[y]				;wartosc liczby
	mov bx, liczbaS			;adres bufora do zapisania
	call liczbanapis		;funkcja konwertujaca int->string
	mov dx,liczbaS			;adres wyswietlanego napisu do DX
	call print				;funkcja drukujaca
;druga czesc
	mov dx,komunikat5
	call print
	mov ax,[wynik]			;wartosc zmiennej "wynik" -> reszta
	mov bx, liczbaS			;adres bufora do zapisania
	call liczbanapis		;funkcja konwertujaca int->string
	mov dx,liczbaS			;adres wyswietlanego napisu do DX
	call print				;funkcja drukujaca
	call nowalinia

;koniec kodu uzytkownika
;******************************************************************************

;funkcja 4Ch przerwania 21h -> koniec programu
koniec:
	mov ax,0x4c00			;wyjscie z programu
	int 0x21

;procedura wyswietlajaca napis -> adres bufora w DX
print:
	mov ah,9				;funkcja wyswiatlajaca napis
	int 0x21				;przerwanie DOS 0x21
	ret
	
;procedura pobierajaca napis od uzytkownika -> adres bufora w DX (bufor musi miec struktre ROZMIAR, LICZNIK, NAPIS[ROZMIAR])
pobierz:
	mov ah,0xA
	int 0x21
	ret
	
;procedura wyswietlajaca ENTER (CR LF)
nowalinia:
	mov dx,0xA
	mov ah,2				;jeden znak na konsole
	int 0x21
	mov dx,0xD
	mov ah,2				;jeden znak na konsole
	int 0x21
	ret
;procedura zamieniajaca liczbe w AX na napis w BX adres bufora do zapamietania
liczbanapis:
	cld						;ustawienie kierunku
	xor cx,cx				;zerowanie licznika
	test ax,ax
	js ujemna				;jesli ustawiona flaga znaku, to liczba jest ujemna
	jmp dodatnia
ujemna:						;jesli liczba jest ujemna, ustawiam flage, zeby dopisac znak '-'
	neg ax
	mov word [znak],1		;ustawiam flage, zeby wiedziec, ze liczba jest ujemna, zatem trzeba bedzie dopisac '-' na koncu
dodatnia:
	mov di,10				;dzielnik
again5:
	xor dx,dx
	div di
	push dx					;reszta z dzielenia na stos
	inc cx
	or ax,ax				;czy wyszlo juz zerowanie
	jnz again5
	cmp word [znak],1
	jne again7
	push '-'-'0'			;odejmuje '0', bo zamiana na napis doda to '0', wiec wyjdzie znowu '-'
	inc cx
again7:	
	mov di, bx
again6:						;sciaganie ze stosu do bufora napisu z zamiana na znak +'0'
	pop ax
	add al,'0'
	stosb					;wstaw znak do stringa
	loop again6				;powtorz cx razy (liczba elementow na stosie -> dlugosc napisu)
	mov al,'$'				;wstaw znak konca do stringa
	stosb
	ret

;procedura konwertujaca napis w buforze na liczbe calkowita ze znakiem. Adres bufora w AX, wynik w BX
napisliczba:
	std
	add ax,2
	mov si,ax				;poczatek napisu
	xor cx,cx
	dec ax
	mov bx,ax
	mov cl,byte [bx]		;do CL dlugosc napisu
	add si,cx
	dec si					;trafiam w koniec napisu, zeby liczyc go od najmniej znaczacej cyfry

	mov ax,1
	mov [potega],ax			;zaczynamy od potegi 1, potem 10, 100
	xor bx,bx				;w BX bedzie wynik
	xor dx,dx
	mov ax,1
again8:
	lodsb					;znak do AL (SI--)
	xor ah,ah
	xor dx,dx
	mov dl,al				;znak do DL
	cmp dl,'-'				;jesli znakiem jest '-' zmieniamy znak i konczymy (to ostatni znak od prawej)
	je minus2
	sub dl,'0'				;znak na liczbe '1'-'0'=1
	mov ax,[potega]
	mul dx
	add bx,ax
	mov ax,[potega]
	mov dx,[x]
	mul dx
	mov [potega],ax
	xor ax,ax
	dec cx					;o jeden znak mniej
	jnz again8				;az do zera	
	jmp plus2
minus2:
	neg bx					;jesli ostatni znak jest '-' negujemy liczbe
plus2:
	ret

segment data				;segment danych

	komunikat0	db 13,10,'Obliczanie x^2, x^3, x mod 3 podanej liczby w zakresie od -32768 do +32767',\
					13,10,'Uwaga na reszte z ujemnych wartosci$'
	komunikat1	db 13,10,'Podaj liczbe: $'
	komunikat2	db 13,10,'Kwadrat wynosi: $'
	komunikat3	db 13,10,'Szescian wynosi: $'
	komunikat4	db 13,10,'Reszta z dzielenia $'
	komunikat5	db ' przez 3 wynosi: $'
	
	liczba		db 20
				db 0
				times 20 db '$'	;bufor na 1. liczbe (napis)
	liczbaS		times 20 db '0'	;bufor na wyniki (napis)
	y			dw	0
	x			dw	10
	potega		dw	0x0001
	wynik		dw	0x0000
	znak		dw	0x0000

segment stack stack				;segment stosu
	resb 64
stacktop: