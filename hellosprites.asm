; Hola sprite
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
 
; creamos un par de variables para ver hacia donde tenemos que mover el sprite
_MOVX       EQU     _RAM    ; inicio de la ram dispobible para datos
_MOVY       EQU     _RAM+1
 
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
.bucle_limpieza:
    ld      a, 0            ; el tile 0 es nuestro tile vacio
    ld      [hl], a
    dec     de
    ; ahora tengo que comprobar si de es cero, para ver si tengo que 
    ; terminar de copiar. dec de no modifica ningñun flag, asi que no puedo
    ; comprobar el flag zero directamente, pero para que de sea cero, d y e 
    ; tienen que ser cero los dos, asi que puedo hacer un or entre ellos, 
    ; y si el resultado es cero, ambos son cero.
    ld      a, d            ; cargamos d en a
    or      e               ; y hacemos un or con e
    jp      z, .fin_bucle_limpieza  ; si d OR e es cero, de es cero. Terminamos.
    inc     hl              ; incrementamos la dirección a escribir en
    jp      .bucle_limpieza
.fin_bucle_limpieza
 
    ; bien, tenemos todo el mapa de tiles lleno con el tile 0, 
    ; ahora vamos a crear el sprite.
 
    ld      a, 30
    ld      [_SPR0_Y], a    ; posición Y del sprite     
    ld      a, 30
    ld      [_SPR0_X], a    ; posición X del sprite
    ld      a, 1
    ld      [_SPR0_NUM], a  ; número de tile en la tabla de tiles que usaremos
    ld      a, 0
    ld      [_SPR0_ATT], a  ; atributos especiales, de momento nada.
 
    ; configuramos y activamos el display
    ld      a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ld      [rLCDC], a
 
    ; preparamos las variables de la animacion
    ld      a, 1
    ld      [_MOVX], a
    ld      [_MOVY], a
 
    ; bucle infinito
animacion:
    ; lo primero, esperamos por el VBlank, ya que no podemos modificar
    ; la VRAM fuera de él, o pasarán cosas raras
.wait:
    ld      a, [rLY]
    cp      145
    jr      nz, .wait
    ; incrementamos las y
    ld      a, [_SPR0_Y]    ; cargamos la posición Y actual del sprite
    ld      hl, _MOVY       ; en hl, la dirección del incremento Y
    add     a, [hl]         ; sumamos
    ld      hl, _SPR0_Y
    ld      [hl], a         ; guardamos
    ; comparamos para ver si hay que cambiar el sentido
    cp      152             ; para que no se salga de la pantalla (max Y)
    jr      z, .dec_y
    cp      16
    jr      z, .inc_y       ; lo mismo, minima coord Y=16
    ; no hay que cambiar
    jr      .end_y
.dec_y:
    ld      a, -1           ; ahora hay que decrementar las Y
    ld      [_MOVY], a
    jr      .end_y
.inc_y:
    ld      a, 1            ; ahora hay que incrementar las Y
    ld      [_MOVY], a
.end_y:
    ; vamos con las X, lo mismo pero cambiando los márgenes
    ld      a, [_SPR0_X]    ; cargamos la posición X actual del sprite
    ld      hl, _MOVX       ; en hl, la dirección del incremento X
    add     a, [hl]         ; sumamos
    ld      hl, _SPR0_X
    ld      [hl], a         ; guardamos
    ; comparamos para ver si hay que cambiar el sentido
    cp      160             ; para que no se salga de la pantalla (max X)
    jr      z, .dec_x
    cp      8               ; lo mismo, minima coord izq = 8
    jr      z, .inc_x
    ; no hay que cambiar
    jr      .end_x
.dec_x:
    ld      a, -1           ; ahora hay que decrementar las X
    ld      [_MOVX], a
    jr      .end_x
.inc_x:
    ld      a, 1            ; ahora hay que incrementar las X
    ld      [_MOVX], a
.end_x:
    ; un pequeño retardo
    call retardo
    ; volvemos a empezar
    jr      animacion
 
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