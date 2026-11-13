class_name DodgeStyle
extends Resource
## Estilo de esquive (data/dodges/*.tres). Cada personaje apunta al suyo en
## CharacterData.dodge_style: la animación y también cómo se mueve (un destello es corto
## y rapidísimo; un salto, más lento y alto). Al crear el jugador, sus valores se copian
## en la ficha del personaje (las mejoras pasivas los modifican después).

@export var id := &"deslizar"
@export var display_name := "Deslizamiento"
@export var anim := "slide"                  ## animación en scripts/anim/anim_humano.gd
@export var speed := 11.5                    ## m/s al empezar (frena hasta la de andar)
@export var duration := 0.32                 ## s de impulso
@export var iframes := 0.36                  ## s de invulnerabilidad desde que empieza
@export var cooldown := 1.2                  ## s desde que empieza hasta poder repetir
@export var snow_spray := true               ## levanta nieve mientras dura la animación
@export var afterimages := false             ## deja una estela de imágenes fantasma
@export var frames := false                  ## entra en un cuadro y sale por otro (Pickman, hito 20.17)
@export var dust := false                    ## se deshace en sales y se recompone al salir (Ward, hito 20.18)
## Por un ángulo imposible (Gilman, hito 20.19): durante el impulso atraviesa el decorado (no los
## límites de la arena) y el modelo se pliega de lado; al acabar, se recoloca fuera de lo que tenga encima.
@export var phase := false
## Se asoma al más allá (Tillinghast, hito 20.20): revela a los de `reveal` m de donde sale.
@export var reveal := 0.0
## Cambia de cuerpo (Derby y Asenath, hito 20.21; CharacterData.alt_model), escondido en el destello.
@export var swap := false
## Se duerme y despierta en otro sitio (Kuranes, hito 20.22): deja donde estaba un sueño de este
## radio que frena a los enemigos DODGE_DREAM_T s. 0: nada.
@export var dream := 0.0
## Tramo de la animación (0..1) en que el modelo no se ve (el destello "desaparece").
@export var hidden_from := -1.0
@export var hidden_to := -1.0
