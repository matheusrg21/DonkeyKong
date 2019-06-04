                    .text

                    .include "./macros.s"

                    # Display ------------------- #
                    .eqv DISPLAY_0 0xFF000000
                    .eqv DISPLAY_1 0xFF100000
                    .eqv FRAME_SEL 0xFF200604
                    .eqv DISPLAY_W 320
                    .eqv DISPLAY_H 240

                    # Keyboard  ----------------- #
                    .eqv KEYBOARD  0xFF200000     # Keyboard MMIO address
                    # .eqv KEY_LEFT  TODO     # A -> Left walk
                    # .eqv KEY_RIGHT TODO     # D -> Right walk
                    # .eqv KEY_UP    TODO     # W ->
                    # .eqv KEY_DOWN  TODO     # S ->

                    .data

                    .include "img/fundo1_320x240.s"
                    .include "img/jump_man_parado_direita_16x16.s"

                    .text

main:               la a0, fundo                  # Load background image addr
                    li a1, 0                      # Set 'x' position to start painting
                    li a2, 0                      # Set 'y' position to start painting
                    li a3, 0                      # Select which frame to paint into
                    call paint

                    la a0, jmpd                   # Load mario image addr
                    li a1, 0                      # Set 'x' position to start painting
                    li a2, 217                    # Set 'y' position to start painting
                    li a3, 0                      # Select which frame to paint into
                    call paint

                    # Polling do teclado e echo na tela
                    li s0, 0                      # zera o contador
CONTA:              addi s0, s0, 1                # incrementa o contador
                    call key                      # le o teclado sem wait
                    j CONTA                       # volta ao loop

# Fn find_key() -> u8? -------------------------- #
#                                                 #
# Read a 'fresh' key from the keyboard            #
key:                li t1, KEYBOARD               # carrega o endereço de controle do KDMMIO
                    lw t0, 0(t1)                  # Le bit de Controle Teclado
                    bne t0, zero, _key_found      # Se não há tecla pressionada então vai para FIM
                    li a0, 0
                    ret

_key_found:         lw a0, 4(t1)                  # le o valor da tecla tecla
                    ret
# End find_key ---------------------------------- #

# Fn paint(img: u32, x: u32, y: u32, fr: u32) --- #
paint:              lw t1, 0(a0)                  # Load image width
                    lw t2, 4(a0)                  # Load image height
                    addi a0, a0, 8                # Get pointer to the image
                    POSITION t0, a1, a2           # Start offset on the display
                    DISPLAY t0, t0, a3            # Get pointer to the display

                    mv t3, t1                     # Backup image width
_paint_loop:        lb t5, 0(a0)                  # Load pixel from image
                    addi a0, a0, 1                # Update image pointer
                    sb t5, 0(t0)                  # Paint loaded pixel on the display
                    addi t0, t0, 1                # Update display pointer
                    addi t1, t1, -1               # One less pixel to paint
                    bnez t1 _paint_loop           # Are we done with this line?

                    addi t2, t2, -1               # One less line to paint
                    mv t1, t3                     # Let's start the next one
                    addi t0, t0, DISPLAY_W        # Move display pointer to the next line
                    sub t0, t0, t3                # But we needed it to point to the START of the next line!

                    bnez t2, _paint_loop          # Are we done with this image?
                    ret                           # Yes we are!

# End paint ------------------------------------- #
