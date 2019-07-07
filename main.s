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
                      .eqv START_ST  0                      # Mario start state
                      .eqv MAX_X     304                    # Screen limit on the 'x' direction
                      .eqv MAX_Y     224                    # Screen limit on the 'y' direction

                      .data

                      .include "img/level_1_bg.asm"
                      .include "img/mario_still_right.asm"
                      .include "img/mario_still_left.asm"
                      .include "img/mario_walk_right_1.asm"
                      .include "img/mario_walk_left_1.asm"
                      .include "img/mario_walk_right_2.asm"
                      .include "img/mario_walk_left_2.asm"

                      .text
                      M_SetEcall(exceptionHandling)

                      # Global Values --------------------- #
                      # s0 - In which frame are we drawing?
                      # s1 - Mario current 'x' position.
                      # s2 - Mario current 'y' position.
                      # s3 - Current mario state.
                      #    - 0: Right, Still
                      #    - 4: Right, Still
                      #    - 16: Left, Still
                      #    - 20: Left, Still
                      #    - 8: Right, Walking 1
                      #    - 12: Right, Walking 2
                      #    - 24: Left, Walking 1
                      #    - 28: Left, Walking 2

main:                 li s0, 0                              # Current frame
                      li s1, START_X                        # Mario 'x' position
                      li s2, START_Y                        # Mario 'y' position
                      li s3, START_ST                       # Mario current state

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
                      call paint_fast

                      call paint_mario

                      li t0, FRAME_SEL                      # Load frame select MMIO addr
                      sw s0, 0(t0)                          # Show the current frame
                      xori s0, s0, 1                        # Invert selection of the next frame

                      lw ra, 0(sp)
                      addi sp, sp ,4
                      ret

# End paint_scene ----------------------------------------- #

# Fn paint_mario() ---------------------------------------- #
                      .data
_images:              .word mario_still_right
                      .word mario_still_right
                      .word mario_walk_right_1
                      .word mario_walk_right_2
                      .word mario_still_left
                      .word mario_still_left
                      .word mario_walk_left_1
                      .word mario_walk_left_2

                      .text
paint_mario:          andi t1, s3, 0x1C
                      la t0, _images
                      add t0, t0, t1

                      lw a0, 0(t0)
                      mv a1, s1                             # Set 'x' position to start painting
                      mv a2, s2                             # Set 'y' position to start painting
                      mv a3, s0                             # Select which frame to paint into
                      j paint                               # TCO

# End paint_mario ----------------------------------------- #

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
                      li s3, 24
                      j _handle_input_end

_handle_key_right:    INCREMENT s1, STEP, MAX_X
                      li s3, 8
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
#
# Paints the referenced image at the provided position and
# frame. Depending on detected support this function will
# forward to paint_fast or paint_slow to do the work.
paint:                NOT_DE1 paint_slow                    # On the DE1, paint_fast seems to handle transparent pixels correctly
                      # Falls through and runs paint_fast
# End paint ----------------------------------------------- #

# Fn paint_fast(img: u32, x: u32, y: u32, fr: u32) -------- #
#
# Paints the referenced image at the provided position and
# frame. This function takes the fast approach of painting
# the image word by word, but it doesn't handle transparent
# pixels on rars as requires that the image width be a
# multiple of 4.
paint_fast:           lw t1, 0(a0)                          # Load image width
                      lw t2, 4(a0)                          # Load image height
                      addi a0, a0, 8                        # Get pointer to the image
                      POSITION t0, a1, a2                   # Start offset on the display
                      DISPLAY t0, t0, a3                    # Get pointer to the display

                      mv t3, t1                             # Backup image width

_paint_fast_loop:     lw t5, 0(a0)                          # Load pixel from image
                      addi a0, a0, 4                        # Update image pointer
                      sw t5, 0(t0)                          # Paint loaded pixel on the display
                      addi t0, t0, 4                        # Update display pointer

                      addi t1, t1, -4                       # One less pixel to paint
                      bnez t1 _paint_fast_loop              # Are we done with this line?

                      addi t2, t2, -1                       # One less line to paint
                      mv t1, t3                             # Let's start the next one
                      addi t0, t0, DISPLAY_W                # Move display pointer to the next line
                      sub t0, t0, t3                        # But we needed it to point to the START of the next line!

                      bnez t2, _paint_fast_loop             # Are we done with this image?
                      ret                                   # Yes we are!

# End paint_fast ------------------------------------------ #


# Fn paint_slow(img: u32, x: u32, y: u32, fr: u32) -------- #
#
# Paints the referenced image at the provided position and
# frame. This function takes the slow approach of painting
# the image pixel by pixel and correctly handle transparent
# pixels.
paint_slow:           lw t1, 0(a0)                          # Load image width
                      lw t2, 4(a0)                          # Load image height
                      li t4, 0xC7
                      addi a0, a0, 8                        # Get pointer to the image
                      POSITION t0, a1, a2                   # Start offset on the display
                      DISPLAY t0, t0, a3                    # Get pointer to the display

                      mv t3, t1                             # Backup image width

_paint_slow_loop:     lbu t5, 0(a0)                          # Load pixel from image
                      beq t5, t4, _paint_slow_skip
                      sb t5, 0(t0)                          # Paint loaded pixel on the display

_paint_slow_skip:     addi a0, a0, 1                        # Update image pointer
                      addi t0, t0, 1                        # Update display pointer
                      addi t1, t1, -1                       # One less pixel to paint
                      bnez t1 _paint_slow_loop              # Are we done with this line?

                      addi t2, t2, -1                       # One less line to paint
                      mv t1, t3                             # Let's start the next one
                      addi t0, t0, DISPLAY_W                # Move display pointer to the next line
                      sub t0, t0, t3                        # But we needed it to point to the START of the next line!

                      bnez t2, _paint_slow_loop             # Are we done with this image?
                      ret                                   # Yes we are!

# End paint_slow ------------------------------------------ #

                      .include "./SYSTEMv14.s"
