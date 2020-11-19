; Hola ventana
; David Pello 2010
; ladecadence.net
; Para el tutorial en: 
; http://wiki.ladecadence.net/doku.php?id=tutorial_de_ensamblador
 
INCLUDE "gbhw.inc"			; importamos el archivo de definiciones
 
; definimos unas constantes para trabajar con nuestros sprites
_SPR0_Y		EQU		_OAMRAM	; la Y del sprite 0, es el inicio de la mem de sprites
_SPR0_X		EQU		_OAMRAM+1
_SPR0_NUM	EQU		_OAMRAM+2
_SPR0_ATT	EQU		_OAMRAM+3
 
_SPR1_Y     	EQU     	_OAMRAM+4
_SPR1_X     	EQU     	_OAMRAM+5
_SPR1_NUM   	EQU     	_OAMRAM+6
_SPR1_ATT   	EQU     	_OAMRAM+7
 
_SPR2_Y     	EQU     	_OAMRAM+8
_SPR2_X     	EQU     	_OAMRAM+9
_SPR2_NUM   	EQU     	_OAMRAM+10
_SPR2_ATT   	EQU     	_OAMRAM+11
 
_SPR3_Y     	EQU     	_OAMRAM+12
_SPR3_X     	EQU     	_OAMRAM+13
_SPR3_NUM   	EQU     	_OAMRAM+14
_SPR3_ATT   	EQU     	_OAMRAM+15
 
; VARIABLES
; variable donde guardar el estado del pad
_PAD			EQU		_RAM 	; al inicio de la ram interna
; variables de control de los sprites
_POS_MAR_2		EQU		_RAM+1	; posición donde colocar los segundos sprites
_SPR_MAR_SUM		EQU		_RAM+2	; numero a sumar a los sprites para alternarlos
 
; El programa comienza aqui:
SECTION "start",ROM0[$0100]
    nop
    jp  	inicio
 
; Cabecera de la ROM (Macro definido en gbhw.inc)
; define una rom sin mapper, de 32K y sin RAM, lo más básico
; (como por ejemplo la del tetris)
	ROM_HEADER  ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE
 
; aqui empieza nuestro programa
inicio:
	nop
	di					; deshabilita las interrupciones
	ld		sp, $ffff		; apuntamos la pila al tope de la ram
 
inicializacion:
 
	; iniciamos las variables
	ld		hl, _POS_MAR_2		; sprites mirando a la dcha.
	ld		[hl], -8
 
	ld		hl, _SPR_MAR_SUM	; empezamos con el 0
	ld		[hl], 0
 
	; paletas
	ld		a, %11100100		; Colores de paleta desde el mas oscuro al
						; más claro, 11 10 01 00
	ld		[rBGP], a		; escribimos esto en el registro de paleta de fondo
	ld		[rOBP0], a		; y en la paleta 0 de sprites
 
	; creamos otra paleta para la paleta 2 de sprites, para mario
	ld		a, %11010000
	ld		[rOBP1], a
 
	; scroll
	ld		a, 0			; escribimos 0 en los registros de scroll X e Y
	ld		[rSCX], a		; con lo que posicionamos la pantalla visible
	ld		[rSCY], a		; al inicio (arriba a la izq) del fondo.
 
	; video
	call		apaga_LCD		; llamamos a la rutina que apaga el LCD
 
	; cargamos los tiles en la memoria de tiles
 
	ld		hl, Tiles		; cargamos en HL la dirección de nuestro tile
	ld		de, _VRAM		; en DE dirección de la memoria de video
	ld		bc, FinTiles-Tiles	; número de bytes a copiar
 
	call		CopiaMemoria
 
	; cargamos el mapa
	ld		hl, Mapa
	ld		de, _SCRN0		; mapa 0
	ld		bc, 32*32
	call		CopiaMemoria
 
	; cargamos el mapa para la ventana
	ld		hl, Ventana
	ld		de, _SCRN1		; mapa 1
	ld		bc, 32*32
	call		CopiaMemoria
 
	; bien, tenemos todo el mapa de tiles cargado
	; ahora limpiamos la memoria de sprites
	ld		de, _OAMRAM		; memoria de atributos de sprites
	ld		bc, 40*4		; 40 sprites x 4 bytes cada uno
    	ld      	l, 0            	; lo vamos a poner todo a cero, asi los sprites
	call		RellenaMemoria		; no usados quedan fuera de pantalla
 
	; ahora vamos a crear los sprites.
	ld		a, 136
	ld		[_SPR0_Y], a		; posición Y del sprite		
	ld		a, 80
	ld		[_SPR0_X], a		; posición X del sprite
	ld		a, 0
	ld		[_SPR0_NUM], a		; número de tile en la tabla de tiles que usaremos
	ld		a, 16 | 32
	ld 		[_SPR0_ATT], a		; atributos especiales, paleta 1
 
    	ld      	a, 136+8
    	ld      	[_SPR1_Y], a    	; posición Y del sprite     
    	ld      	a, 80
    	ld      	[_SPR1_X], a    	; posición X del sprite
    	ld      	a, 1
    	ld      	[_SPR1_NUM], a  	; número de tile en la tabla de tiles que usaremos
   	ld     	 	a, 16 | 32
    	ld      	[_SPR1_ATT], a  	; atributos especiales, paleta 1
 
    	ld      	a, 136
    	ld      	[_SPR2_Y], a    	; posición Y del sprite     
	ld		a, [_POS_MAR_2]
	add		80
    	ld      	[_SPR2_X], a    	; posición X del sprite
    	ld      	a, 2
    	ld      	[_SPR2_NUM], a  	; número de tile en la tabla de tiles que usaremos
    	ld      	a, 16 | 32
    	ld      	[_SPR2_ATT], a  	; atributos especiales, paleta 1
 
    	ld      	a, 136+8
    	ld      	[_SPR3_Y], a    	; posición Y del sprite     
    	ld      	a, [_POS_MAR_2]
	add		a, 80
    	ld      	[_SPR3_X], a    	; posición X del sprite
    	ld     	 	a, 3
    	ld      	[_SPR3_NUM], a  	; número de tile en la tabla de tiles que usaremos
    	ld      	a, 16 | 32
    	ld      	[_SPR3_ATT], a  	; atributos especiales, paleta 1
 
 
	; configuramos y activamos el display
	ld  		a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00
	ld  		[rLCDC], a
 
; bucle principal
movimiento:
	; leemos el pad
	call	lee_pad
	; lo primero, esperamos por el VBlank, ya que no podemos modificar
	; la VRAM fuera de él, o pasarán cosas raras
.wait:
    	ld      	a, [rLY]
    	cp      	145
    	jr      	nz, .wait
 
	; Ahora movemos el sprite dependiendo de los botones
	ld 		a, [_PAD]		; cargamos el estado del pad
	and		%00010000		; derecha
	call		nz, mueve_derecha	; si el resultado no es cero, habia un 1 ahi
						; entonces llamamos a la subrutina
 
	ld		a, [_PAD]
	and    		%00100000		; izquierda
	call		nz, mueve_izquierda
 
	ld		a, [_PAD]
	and		%01000000		; arriba
	;call		nz, mueve_arriba
 
	ld		a, [_PAD]
	and		%10000000		; abajo
	;call		nz, mueve_abajo
 
	ld		a, [_PAD]
	and		%00001000		; Boton START
	call		nz, muestra_ventana
 
	ld		a, [_PAD]
	and		%11111111
	call		z, sin_pulsaciones
 
	; un pequeño retardo
	ld		bc, 2000
	call 		retardo
	; volvemos a empezar
	jr 		movimiento
 
 
; Rutinas de movimiento
mueve_derecha:
	ld		a,  [_SPR0_X]		; obtenemos la posición actual
	cp		120			; estamos en la esquina?
	jp		nz, .ad			; si no estamos en la esquina, avanzamos
 
	ld		a, [rSCX]		; si estamos al borde, movemos el scroll
	inc		a
	ld		[rSCX], a
 
	; modificamos los sprites
	call		num_spr_mario
	call		camina_mario
 
	ret
.ad:
	; los segundos sprites deben estar detras de los primeros
	push	af
	ld		a, -8
	ld		[_POS_MAR_2], a
	pop		af
	; movimiento
	inc		a			; avanzamos
	ld		[_SPR0_X], a		; guardamos la posicion
	ld		[_SPR1_X], a
 
	ld		hl, _POS_MAR_2		; desplazamiento a los primeros
	add		a, [hl]			; sumamos
	ld		[_SPR2_X], a		; guardamos
	ld		[_SPR3_X], a
	; derecha, por lo tanto, los sprites deben estar reflejados horizontalmente
	ld		a, [_SPR0_ATT]
	set		5, a
	ld		[_SPR0_ATT], a
	ld      	[_SPR1_ATT], a
	ld      	[_SPR2_ATT], a
	ld      	[_SPR3_ATT], a
 
	; modificamos los prites
	call		num_spr_mario
	call		camina_mario
 
	ret					; volvemos
 
mueve_izquierda:
    	ld      	a,  [_SPR0_X]   	; obtenemos la posición actual
    	cp      	16              	; estamos en la esquina?
    	jp     		nz, .ai         	; si no estamos en la esquina, avanzamos
 
	ld		a, [rSCX]		; si estamos, scroll
	dec		a
	ld		[rSCX], a
 
	; modificamos los sprites
	call		num_spr_mario
	call		camina_mario
 
	ret
 
.ai:
	; los segundos sprites deben estar delante de los primeros
	push		af
    	ld      	a, 8
    	ld      	[_POS_MAR_2], a
	pop		af
	; movimiento
    	dec     	a               	; retrocedemos
    	ld     		[_SPR0_X], a    	; guardamos la posicion
	ld      	[_SPR1_X], a 	
 
    	ld      	hl, _POS_MAR_2    	; desplazamiento a los primeros
    	add     	a, [hl]         	; sumamos
    	ld      	[_SPR2_X], a    	; guardamos
    	ld      	[_SPR3_X], a
 
    ; izquierda, por lo tanto, los sprites deben estar reflejados horizontalmente
    	ld      	a, [_SPR0_ATT]
    	res     	5, a
    	ld      	[_SPR0_ATT], a
    	ld      	[_SPR1_ATT], a
    	ld      	[_SPR2_ATT], a
    	ld      	[_SPR3_ATT], a
 
	; modificamos los sprites
	call		num_spr_mario
	call		camina_mario
 
    	ret                     		; volvemos
 
 
mueve_arriba:
    	ld      	a,  [_SPR0_Y]   	; obtenemos la posición actual
    	cp      	16              	; estamos en la esquina?
    	ret     	z               	; si estamos en la esquina, volvemos
 
    	dec     	a               	; retrocedemos
    	ld      	[_SPR0_Y], a    	; guardamos la posicion
 
    	ret 
 
mueve_abajo:
    	ld      	a,  [_SPR0_Y]   	; obtenemos la posición actual
    	cp      	152             	; estamos en la esquina?
    	ret     	z               	; si estamos en la esquina, volvemos
 
    	inc     	a               	; avanzamos
    	ld      	[_SPR0_Y], a    	; guardamos la posicion
 
    	ret 
 
muestra_ventana:
	ld		a, 8
	ld		[rWX], a
 
	ld		a, 144
	ld		[rWY], a
 
	;activamos la ventana y desactivamos los sprites
	ld		a, [rLCDC]
	or		LCDCF_WINON
	res		1, a
	ld		[rLCDC], a
 
	; animacion
	ld		a, 144
.anim_most_vent:
	push		af
	ld		bc, 1000
	call		retardo
	pop		af
	dec		a
	ld      	[rWY], a
	jr		nz, .anim_most_vent
 
	; esperamos a que pulsen select para salir
.espera_salir:
	call		lee_pad
	and     	%00001000       		; Boton START
	jr		z, .espera_salir;	
 
 
.anim_ocul_vent:
    	push    	af
    	ld      	bc, 1000
    	call    	retardo
    	pop     	af
    	inc     	a
    	ld      	[rWY], a
	cp		144
    	jr     		nz, .anim_ocul_vent
 
	;desactivamos la ventana y activamos los sprites
    	ld      	a, [rLCDC]
    	res		5, a
	or		LCDCF_OBJON
    	ld      	[rLCDC], a
 
	ret						; volvemos
 
 
; si no se pulsa nada, se viene aqui para modificar el sprite por el mario
; estático
sin_pulsaciones:
	ld      	hl, _SPR_MAR_SUM; empezamos con el 0
    	ld      	[hl], 0
 
	ld		a, 0
	ld		[_SPR0_NUM], a
	inc		a
	ld      	[_SPR1_NUM], a
	inc		a
	ld      	[_SPR2_NUM], a
	inc		a
	ld      	[_SPR3_NUM], a
	ret
 
; modifica la variable para cambiar los sprites de mario caminando
num_spr_mario:
	ld		a, [_SPR_MAR_SUM]
	add		4				; sumamos 4
	ld		[_SPR_MAR_SUM], a		; lo guardamos
	cp		12				; menor que 12?
	ret		nz				; volvemos
 
	ld		a, 4				; 12? entonces volvemos al 4
	ld      	[_SPR_MAR_SUM], a
	ret
 
camina_mario:
	ld		a, [_SPR_MAR_SUM]
	ld      	[_SPR0_NUM], a
	inc     	a
    	ld      	[_SPR1_NUM], a
    	inc    		a
    	ld      	[_SPR2_NUM], a
    	inc     	a
    	ld      	[_SPR3_NUM], a
    	ret
 
 
; Rutina de lectura del pad
lee_pad:
	; vamos a leer la cruzeta:
	ld		a, %00100000	; bit 4 a 0, bit 5 a 1 (cruzeta activada, botones no)
	ld		[rP1], a
 
	; ahora leemos el estado de la cruzeta, para evitar el bouncing
	; hacemos varias lecturas
	ld		a, [rP1]
	ld      	a, [rP1]
	ld      	a, [rP1]
	ld      	a, [rP1]
 
	and		$0F			; solo nos importan los 4 bits de abajo.
	swap		a			; intercambiamos parte baja y alta.
	ld		b, a			; guardamos el estado de la cruzeta en b
 
	; vamos a por los botones
    	ld      	a, %00010000    	; bit 4 a 1, bit 5 a 0 (botones activados, cruzeta no)
    	ld      	[rP1], a
 
	; leemos varias veces para evitar el bouncing
    	ld      	a, [rP1]
    	ld      	a, [rP1]
    	ld      	a, [rP1]
    	ld      	a, [rP1]
 
	; tenemos en A, el estado de los botones
    	and     	$0F             	; solo nos importan los 4 bits de abajo.
	or		b			; hacemos un or con b, para "meter" en la parte
						; superior de A, el estado de la cruzeta.
 
	; ahora tenemos en A, el estado de todo, hacemos el complemento y
	; lo guardamos en la variable
	cpl
	ld 		[_PAD], a
	; volvemos
	ret
 
; Rutina de apagado del LCD
apaga_LCD:
	ld		a,[rLCDC]
	rlca	                	; Pone el bit alto de LCDC en el flag de acarreo
	ret		nc              ; La pantalla ya está apagada, volver.
 
	; esperamos al VBlank, ya que no podemos apagar la pantalla
	; en otro momento
 
.espera_VBlank
	ld		a, [rLY]
	cp		145
	jr		nz, .espera_VBlank
 
	; estamos en VBlank, apagamos el LCD
	ld		a,[rLCDC]		; en A, el contenido del LCDC
	res		7,a			; ponemos a cero el bit 7 (activado del LCD)
	ld		[rLCDC],a		; escribimos en el registro LCDC el contenido de A
 
	ret					; volvemos
 
; rutina de retardo
; parámetros
; bc - numero de iteraciones
retardo:
.delay:
	dec		bc			; decrementamos
	ld		a, b			; vemos si es cero
	or		c
	jr		z, .fin_delay
	nop
	jr		.delay
.fin_delay:
	ret
 
; rutina de copia a memoria
; copia un numero de bytes de una direccion a otra
; espera los parámetros:
; hl - dirección de datos a copiar
; de - dirección de destino
; bc - numero de datos a copiar
; destruye el contenido de A
CopiaMemoria:
	ld		a, [hl]		; cargamos el dato en A
	ld		[de], a		; copiamos el dato al destino
	dec		bc		; uno menos por copiar
	; comprobamos si bc es cero
	ld		a, c
	or		b
	ret		z		; si es cero, volvemos
	; si no, seguimos
	inc		hl
	inc		de
	jr		CopiaMemoria
 
 
; rutina de relleno de memoria
; rellena un numero de bytes de memoria con un dato
; espera los parámetros:
; de - direccion de destino
; bc - número de datos a rellenar
; l - dato a rellenar
RellenaMemoria:
	ld		a, l
	ld		[de], a			; mete el dato en el destino
	dec		bc			; uno menos a rellenar
 
	ld		a, c		
	or		b			; comprobamos si bc es cero
	ret		z			; si es cero volvemos
	inc		de			; si no, seguimos
	jr		RellenaMemoria
 
 
Tiles:
INCLUDE "mario_sprites.z80"
FinTiles:
 
Mapa:
INCLUDE "mapa_mario.z80"
FinMapa:
 
Ventana:
INCLUDE	"ventana.z80"
FinVentana: