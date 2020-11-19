; Hola joypad
; David Pello 2010
; ladecadence.net
; Para el tutorial en: 
; http://wiki.ladecadence.net/doku.php?id=tutorial_de_ensamblador
 
INCLUDE "gbhw.inc"          ; importamos el archivo de definiciones
 
; definimos unas constantes para trabajar con nuestro sprite
_SPR0_Y     EQU     _OAMRAM ; la Y del sprite 0, es el inicio de la mem de sprites
_SPR0_X     EQU     _OAMRAM+1
_SPR0_NUM   EQU     _OAMRAM+2
_SPR0_ATT   EQU     _OAMRAM+3
 
; variable donde guardar el estado del pad
_PAD        EQU     _RAM ; al inicio de la ram interna
 
; El programa comienza aqui:
SECTION "start",ROM0[$0100]
    nop
    jp      inicio
 
; Cabecera de la ROM (Macro definido en gbhw.inc)
; define una rom sin mapper, de 32K y sin RAM, lo más básico
; (como por ejemplo la del tetris)
    ROM_HEADER  ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE
 
; aqui empieza nuestro programa
inicio:
    nop
    di                      ; deshabilita las interrupciones
    ld      sp, $ffff       ; apuntamos la pila al tope de la ram
 
inicializacion:
    ld      a, %11100100    ; Colores de paleta desde el mas oscuro al
                            ; más claro, 11 10 01 00
    ld      [rBGP], a       ; escribimos esto en el registro de paleta de fondo
    ld      [rOBP0], a      ; y en la paleta 0 de sprites
 
    ; creamos otra paleta para la paleta 2 de sprites, inversa a la normal
    ld      a, %00011011
    ld      [rOBP1], a
 
 
    ld      a, 0            ; escribimos 0 en los registros de scroll X e Y
    ld      [rSCX], a       ; con lo que posicionamos la pantalla visible
    ld      [rSCY], a       ; al inicio (arriba a la izq) del fondo.
 
    call    apaga_LCD       ; llamamos a la rutina que apaga el LCD
 
    ; cargamos los tiles en la memoria de tiles
 
    ld      hl, Tiles       ; cargamos en HL la dirección de nuestro tile
    ld      de, _VRAM       ; en DE dirección de la memoria de video
    ld      b, 32           ; b = 32, numero de bytes a copiar (2 tiles)
 
.bucle_carga:
    ld      a,[hl]          ; cargamos en A el dato apuntado por HL
    ld      [de], a         ; y lo metemos en la dirección apuntada en DE
    dec     b               ; decrementamos b, b=b-1
    jr      z, .fin_bucle_carga ; si b = 0, terminamos, no queda nada por copiar
    inc     hl              ; incrementamos la dirección a leer de
    inc     de              ; incrementamos la dirección a escribir en
    jr      .bucle_carga    ; seguimos
.fin_bucle_carga:
 
    ; ahora limpiamos la pantalla (llenamos todo el mapa de fondo), con el tile 0
 
    ld      hl, _SCRN0
    ld      de, 32*32       ; numero de tiles en el mapa de fondo
.bucle_limpieza_fondo:
    ld      a, 0            ; el tile 0 es nuestro tile vacio
    ld      [hl], a
    dec     de
    ; ahora tengo que comprobar si de es cero, para ver si tengo que 
    ; terminar de copiar. dec de no modifica ningún flag, asi que no puedo
    ; comprobar el flag zero directamente, pero para que de sea cero, d y e 
    ; tienen que ser cero los dos, asi que puedo hacer un or entre ellos, 
    ; y si el resultado es cero, ambos son cero.
    ld      a, d            ; cargamos d en a
    or      e               ; y hacemos un or con e
    jp      z, .fin_bucle_limpieza_fondo    ; si d OR e es cero, de es cero. 
                                            ; Terminamos.
    inc     hl              ; incrementamos la dirección a escribir en
    jp      .bucle_limpieza_fondo
.fin_bucle_limpieza_fondo
 
    ; bien, tenemos todo el mapa de tiles lleno con el tile 0
    ; ahora limpiamos la memoria de sprites
 
    ld      hl, _OAMRAM     ; memoria de atributos de sprites
    ld      de, 40*4        ; 40 sprites x 4 bytes cada uno
.bucle_limpieza_sprites
    ld      a, 0            ; lo vamos a poner todo a cero, asi los sprites
    ld      [hl], a         ; sin uso, quedarán fuera de pantalla
    dec     de
    ; lo mismo que en bucle anterior
    ld      a, d            ; cargamos d en a
    or      e               ; y hacemos un or con e
    jp      z, .fin_bucle_limpieza_sprites  ; si d OR e es cero, de es cero.
    inc     hl              ; incrementamos la dirección a escribir en
    jp      .bucle_limpieza_sprites
.fin_bucle_limpieza_sprites
 
    ; ahora vamos a crear el sprite.
 
    ld      a, 74
    ld      [_SPR0_Y], a    ; posición Y del sprite     
    ld      a, 90
    ld      [_SPR0_X], a    ; posición X del sprite
    ld      a, 1
    ld      [_SPR0_NUM], a  ; número de tile en la tabla de tiles que usaremos
    ld      a, 0
    ld      [_SPR0_ATT], a  ; atributos especiales, de momento nada.
 
    ; configuramos y activamos el display
    ld      a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ld      [rLCDC], a
 
; bucle principal
movimiento:
    ; leemos el pad
    call    lee_pad
    ; lo primero, esperamos por el VBlank, ya que no podemos modificar
    ; la VRAM fuera de él, o pasarán cosas raras
.wait:
    ld      a, [rLY]
    cp      145
    jr      nz, .wait
 
    ; Ahora movemos el sprite dependiendo de los botones
    ld      a, [_PAD]       ; cargamos el estado del pad
    and     %00010000       ; derecha
    call    nz, mueve_derecha   ; si el resultado no es cero, habia un 1 ahi
                                ; entonces llamamos a la subrutina
 
    ld      a, [_PAD]
    and     %00100000       ; izquierda
    call    nz, mueve_izquierda
 
    ld      a, [_PAD]
    and     %01000000       ; arriba
    call    nz, mueve_arriba
 
    ld      a, [_PAD]
    and     %10000000       ; abajo
    call    nz, mueve_abajo
 
    ld      a, [_PAD]
    and     %00000001       ; Boton A
    call    nz, cambia_paleta
 
    ; un pequeño retardo
    call retardo
    ; volvemos a empezar
    jr      movimiento
 
 
; Rutinas de movimiento
mueve_derecha:
    ld      a,  [_SPR0_X]   ; obtenemos la posición actual
    cp      160             ; estamos en la esquina?
    ret     z               ; si estamos en la esquina, volvemos
 
    inc     a               ; avanzamos
    ld      [_SPR0_X], a    ; guardamos la posicion
 
    ret                     ; volvemos
 
mueve_izquierda:
    ld      a,  [_SPR0_X]   ; obtenemos la posición actual
    cp      8               ; estamos en la esquina?
    ret     z               ; si estamos en la esquina, volvemos
 
    dec     a               ; retrocedemos
    ld      [_SPR0_X], a    ; guardamos la posicion
 
    ret
 
mueve_arriba:
    ld      a,  [_SPR0_Y]   ; obtenemos la posición actual
    cp      16              ; estamos en la esquina?
    ret     z               ; si estamos en la esquina, volvemos
 
    dec     a               ; retrocedemos
    ld      [_SPR0_Y], a    ; guardamos la posicion
 
    ret
 
mueve_abajo:
    ld      a,  [_SPR0_Y]   ; obtenemos la posición actual
    cp      152             ; estamos en la esquina?
    ret     z               ; si estamos en la esquina, volvemos
 
    inc     a               ; avanzamos
    ld      [_SPR0_Y], a    ; guardamos la posicion
 
    ret
 
cambia_paleta:
    ld      a, [_SPR0_ATT]
    and     %00010000       ; en el bit 4, está el numero de paleta
    jr      z, .paleta0     ; si es cero, estaba seleccionada la paleta 0   
 
    ; si no, estaba seleccionada la paleta 1
    ld      a, [_SPR0_ATT]
    res     4, a            ; ponemos a cero el bit 4, seleccionando la paleta 0
    ld      [_SPR0_ATT], a  ; guardamos los atributos
 
    call    retardo         ; el cambio es muy rapido, vamos a esperar un poco
    ret                     ; volvemos
.paleta0:
    ld      a, [_SPR0_ATT]
    set     4, a            ; ponemos a uno el bit 4, seleccionando la paleta 1
    ld      [_SPR0_ATT], a  ; guardamos los atributos
 
    call    retardo
    ret                     ; volvemos
 
; Rutina de lectura del pad
lee_pad:
    ; vamos a leer la cruzeta:
    ld      a, %00100000    ; bit 4 a 0, bit 5 a 1 (cruzeta activada, botones no)
    ld      [rP1], a
 
    ; ahora leemos el estado de la cruzeta, para evitar el bouncing
    ; hacemos varias lecturas
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]
 
    and     $0F             ; solo nos importan los 4 bits de abajo.
    swap    a               ; intercambiamos parte baja y alta.
    ld      b, a            ; guardamos el estado de la cruzeta en b
 
    ; vamos a por los botones
    ld      a, %00010000    ; bit 4 a 1, bit 5 a 0 (botones activados, cruzeta no)
    ld      [rP1], a
 
    ; leemos varias veces para evitar el bouncing
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]
 
    ; tenemos en A, el estado de los botones
    and     $0F             ; solo nos importan los 4 bits de abajo.
    or      b               ; hacemos un or con b, para "meter" en la parte
                            ; superior de A, el estado de la cruzeta.
 
    ; ahora tenemos en A, el estado de todo, hacemos el complemento y
    ; lo guardamos en la variable
    cpl
    ld      [_PAD], a
    ; volvemos
    ret
 
; Rutina de apagado del LCD
apaga_LCD:
    ld      a,[rLCDC]
    rlca                    ; Pone el bit alto de LCDC en el flag de acarreo
    ret     nc              ; La pantalla ya está apagada, volver.
 
    ; esperamos al VBlank, ya que no podemos apagar la pantalla
    ; en otro momento
 
.espera_VBlank
    ld      a, [rLY]
    cp      145
    jr      nz, .espera_VBlank
 
    ; estamos en VBlank, apagamos el LCD
    ld      a,[rLCDC]       ; en A, el contenido del LCDC
    res     7,a             ; ponemos a cero el bit 7 (activado del LCD)
    ld      [rLCDC],a       ; escribimos en el registro LCDC el contenido de A
 
    ret                     ; volvemos
 
; rutina de retardo
retardo:
    ld      de, 2000        ; numero de veces a ejecutar el bucle
.delay:
    dec     de              ; decrementamos
    ld      a, d            ; vemos si es cero
    or      e
    jr      z, .fin_delay
    nop
    jr      .delay
.fin_delay:
    ret
 
; Datos de nuestros tiles
Tiles:
    DB  $AA, $00, $44, $00, $AA, $00, $11, $00
    DB  $AA, $00, $44, $00, $AA, $00, $11, $00
    DB  $3E, $3E, $41, $7F, $41, $6B, $41, $7F
    DB  $41, $63, $41, $7F, $3E, $3E, $00, $00
EndTiles: