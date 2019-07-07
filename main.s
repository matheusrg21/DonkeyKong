                      .text

                      .include "./macros.s"

                      # Display --------------------------- #
                      .eqv DISPLAY_0 0xFF000000
                      .eqv DISPLAY_1 0xFF100000
                      .eqv FRAME_SEL 0xFF200604
                      .eqv DISPLAY_W 320
                      .eqv DISPLAY_H 240

                      # Keyboard  ------------------------- #
                      .eqv KEYBOARD  0xFF200000             # Keyboard MMIO address
                      .eqv KEY_MASK  0x020                  # Used to turn upper case into lower case
                      .eqv KEY_LEFT  0x061                  # A -> Left walk
                      .eqv KEY_RIGHT 0x064                  # D -> Right walk
                      .eqv KEY_UP    0x077                  # W ->
                      .eqv KEY_DOWN  0x073                  # S ->

                      # Game Constants -------------------- #
                      .eqv STEP      4                      # How many pixels Mario moves at each step
                      .eqv START_X   0                      # Mario 'x' start position
                      .eqv START_Y   216                    # Mario 'x' start position
                      .eqv MAX_X     304                    # Screen limit on the 'x' direction
                      .eqv MAX_Y     224                    # Screen limit on the 'y' direction

                      .data

                      .include "img/fundo1_320x240.s"
                      .include "img/jump_man_parado_direita_16x16.s"

                      .text
                      M_SetEcall(exceptionHandling)

main:                 li s0, 0                              # Current frame
                      li s1, START_X                        # Mario 'x' position
                      li s2, START_Y                        # Mario 'y' position

main_loop:            call paint_scene                      # Paint the whole scene on the screen
                      call handle_input                     # Found a key! Let's do something with it
                      j main_loop                           # Continue the game loop

# Fn paint_scene() ---------------------------------------- #
paint_scene:          addi sp, sp, -4
                      sw ra, 0(sp)

                      la a0, fundo                          # Load background image addr
                      li a1, 0                              # Set 'x' position to start painting
                      li a2, 0                              # Set 'y' position to start painting
                      mv a3, s0                             # Select which frame to paint into
                      call paint

                      la a0, jmpd                           # Load mario image addr
                      mv a1, s1                             # Set 'x' position to start painting
                      mv a2, s2                             # Set 'y' position to start painting
                      mv a3, s0                             # Select which frame to paint into
                      call paint

                      li t0, FRAME_SEL                      # Load frame select MMIO addr
                      sw s0, 0(t0)                          # Show the current frame
                      xori s0, s0, 1                        # Invert selection of the next frame

                      lw ra, 0(sp)
                      addi sp, sp ,4
                      ret

# End paint_scene ----------------------------------------- #

# Fn handle_input() --------------------------------------- #
handle_input:         addi sp, sp, -4
                      sw ra, 0(sp)

                      call key                              # Try to read a key from the keyboard
                      beqz a0, _handle_input_end            # Do nothing if key not found

                      # Check for each key and jump to the apropriate handler
                      CASE a0, KEY_LEFT, _handle_key_left
                      CASE a0, KEY_RIGHT, _handle_key_right
                      CASE a0, KEY_UP, _handle_key_up
                      CASE a0, KEY_DOWN, _handle_key_down

_handle_input_end:    lw ra, 0(sp)
                      addi sp, sp, 4
                      ret

_handle_key_left:     DECREMENT s1, STEP
                      j _handle_input_end

_handle_key_right:    INCREMENT s1, STEP, MAX_X
                      j _handle_input_end

_handle_key_up:       DECREMENT s2, STEP
                      j _handle_input_end

_handle_key_down:     INCREMENT s2, STEP, MAX_Y
                      j _handle_input_end

# End handle_input ---------------------------------------- #

# Fn find_key() -> u8? ------------------------------------ #
#                                                           #
# Read a 'fresh' key from the keyboard                      #
key:                  li t1, KEYBOARD                       # carrega o endereço de controle do KDMMIO
                      lw t0, 0(t1)                          # Le bit de Controle Teclado
                      bne t0, zero, _key_found              # Se não há tecla pressionada então vai para FIM
                      li a0, 0
                      ret

_key_found:           lw a0, 4(t1)                          # le o valor da tecla tecla
                      ori a0, a0, KEY_MASK
                      ret
# End find_key -------------------------------------------- #

# Fn paint(img: u32, x: u32, y: u32, fr: u32) ------------- #
paint:                lw t1, 0(a0)                          # Load image width
                      lw t2, 4(a0)                          # Load image height
                      addi a0, a0, 8                        # Get pointer to the image
                      POSITION t0, a1, a2                   # Start offset on the display
                      DISPLAY t0, t0, a3                    # Get pointer to the display

                      mv t3, t1                             # Backup image width

_paint_loop:          lw t5, 0(a0)                          # Load pixel from image
                      addi a0, a0, 4                        # Update image pointer
                      sw t5, 0(t0)                          # Paint loaded pixel on the display
                      addi t0, t0, 4                        # Update display pointer

                      addi t1, t1, -4                       # One less pixel to paint
                      bnez t1 _paint_loop                   # Are we done with this line?

                      addi t2, t2, -1                       # One less line to paint
                      mv t1, t3                             # Let's start the next one
                      addi t0, t0, DISPLAY_W                # Move display pointer to the next line
                      sub t0, t0, t3                        # But we needed it to point to the START of the next line!

                      bnez t2, _paint_loop                  # Are we done with this image?
                      ret                                   # Yes we are!

# End paint ----------------------------------------------- #

                      .include "./SYSTEMv14.s"
