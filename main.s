                      .text

                      .include "./macros.s"

                      # Display ----------------------------
                      .eqv DISPLAY_0 0xFF000000
                      .eqv DISPLAY_1 0xFF100000
                      .eqv FRAME_SEL 0xFF200604
                      .eqv DISPLAY_W 320
                      .eqv DISPLAY_H 240

                      # Analog-Digital Converter -----------
                      .eqv ADC_CH0   0xFF200200
                      .eqv ADC_CH1   0xFF200204
                      .eqv ADC_CH2   0xFF200208
                      .eqv ADC_CH3   0xFF20020C
                      .eqv ADC_CH4   0xFF200210
                      .eqv ADC_CH5   0xFF200214
                      .eqv ADC_CH6   0xFF200218
                      .eqv ADC_CH7   0xFF20021C

                      # Keyboard  --------------------------
                      .eqv KEYBOARD  0xFF200000             # Keyboard MMIO address
                      .eqv KEY_MASK  0x020                  # Used to turn upper case into lower case
                      .eqv KEY_LEFT  0x061                  # A -> Left walk
                      .eqv KEY_RIGHT 0x064                  # D -> Right walk
                      .eqv KEY_UP    0x077                  # W ->
                      .eqv KEY_DOWN  0x073                  # S ->

                      # Game Constants ---------------------
                      .eqv STEP      4                      # How many pixels Mario moves at each step
                      .eqv START_X   0                      # Mario 'x' start position
                      .eqv START_Y   216                    # Mario 'x' start position
                      .eqv START_ST  0                      # Mario start state
                      .eqv MAX_X     304                    # Screen limit on the 'x' direction
                      .eqv MAX_Y     224                    # Screen limit on the 'y' direction

                      # State masks ------------------------
                      .eqv STATE     0x1C
                      .eqv DIRECTION 0x10
                      .eqv WALKING   0x08
                      .eqv SPRITE    0x04

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

                      # Global Values ----------------------
                      # s0 - In which frame are we drawing?
                      # s1 - Mario current 'x' position.
                      # s2 - Mario current 'y' position.
                      # s3 - Current mario state. (WS)(LR)(12)
                      #    - 0: Right, Still
                      #    - 4: Right, Still
                      #    - 16: Left, Still
                      #    - 20: Left, Still
                      #    - 8: Right, Walking 1
                      #    - 12: Right, Walking 2
                      #    - 24: Left, Walking 1
                      #    - 28: Left, Walking 2
                      # s4 - X joystick base value
                      # s5 - Y joystick base value

# Fn main() -> ! -------------------------------------------
main:                 li s0, 0                              # Current frame
                      li s1, START_X                        # Mario 'x' position
                      li s2, START_Y                        # Mario 'y' position
                      li s3, START_ST                       # Mario current state

                      # X axis calibration
                      li t0, ADC_CH1                        # Load X axis addr
                      lw s4, 0(t0)                          # Set current value for X as its zero
                      srli s4, s4, 4
                      slli s4, s4, 4

                      # Y axis calibration
                      li t0, ADC_CH2                        # Load X axis addr
                      lw s5, 0(t0)                          # Set current value for Y as its zero
                      srli s5, s5, 4
                      slli s5, s5, 4

_loop:                call paint_scene                      # Paint the whole scene on the screen
                      call update_state                     # Update walking animation
                      call handle_js_input                  # Handle input from the joystick
                      call handle_input                     # Handle keyboard input
                      j _loop                               # Continue the game loop
# End main -------------------------------------------------

# Fn paint_scene() -----------------------------------------
paint_scene:          addi sp, sp, -4
                      sw ra, 0(sp)

                      la a0, fundo                          # Load background image addr
                      li a1, 0                              # Set 'x' position to start painting
                      li a2, 0                              # Set 'y' position to start painting
                      mv a3, s0                             # Select which frame to paint into
                      call paint_fast

                      call update_position
                      call paint_mario

                      li t0, FRAME_SEL                      # Load frame select MMIO addr
                      sw s0, 0(t0)                          # Show the current frame
                      xori s0, s0, 1                        # Invert selection of the next frame

                      lw ra, 0(sp)
                      addi sp, sp ,4
                      ret

# End paint_scene ------------------------------------------

# Fn update_position() -------------------------------------
update_position:      addi t2, s2, 15                       # Get the last line of mario's sprite
                      andi t0, s3, DIRECTION                # Get walking direction
                      mv t1, s1                             # Get first pixel of the line
                      bnez t0, _left                        # If walking direction is left, we're done here
                      addi t1, s1, 15                       # If walking direction is right, get the last pixel of the line

_left:                POSITION t0, t1, t2                   # Start offset on the display
                      DISPLAY t0, t0, s0                    # Get pointer to the display
                      addi t1, t0, 320                      # Get address one line

                      lbu t0, 0(t0)                         # Load pixel above floor
                      lbu t1, 0(t1)                         # Load pixel on the floor

                      li t3, 6                              # Get red color
                      beq t0, t3, _too_low                  # If pixel above the floor is red, we're on the floor
                      beqz t1, _too_high                    # If pixel on the floor is black, we're above the floor
                      ret                                   # Else we're ok

_too_high:            INCREMENT s2, 1, MAX_Y                # Move mario 1px down.
                      ret

_too_low:             DECREMENT s2, 1                       # Move mario 1px up.
                      ret

# End update_position --------------------------------------

# Fn update_state() ----------------------------------------
update_state:         andi t0, s3, WALKING                  # Get walk bit value
                      bnez t0, _update_state_walk           # Is mario walking?

                      ret                                   # No.

_update_state_walk:   andi t0, s3, SPRITE                   # Yes.
                      bnez t0, _update_state_walk_2         # But in which state?

_update_state_walk_1: addi s3, s3, 4                        # Update to walk 2 state
                      ret

_update_state_walk_2: andi s3, s3, -9                       # Update to still state
                      ret

# End update_state -----------------------------------------

# Fn paint_mario() -----------------------------------------
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
paint_mario:          andi t1, s3, STATE
                      la t0, _images
                      add t0, t0, t1

                      lw a0, 0(t0)
                      mv a1, s1                             # Set 'x' position to start painting
                      mv a2, s2                             # Set 'y' position to start painting
                      mv a3, s0                             # Select which frame to paint into
                      j paint                               # TCO

# End paint_mario ------------------------------------------

# Fn handle_input() ----------------------------------------
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

# End handle_input -----------------------------------------

# Fn handle_js_input() -------------------------------------
handle_js_input:      addi sp, sp, -4                       # Reserve stack space
                      sw ra, 0(sp)                          # Store return addr

                      call joystick                         # Read joystick input
                      beqz a0, _handle_input_end            # Do nothing if not changed
                      bnez a1, move_y                       # Handle changes on y derection

move_x:               blt a0, s4, _handle_key_left          # Move left
                      bge a0, s4, _handle_key_right         # Move Right
                      PANIC "reached unreachable code!"

move_y:               blt a0, s5, _handle_key_up            # Move up
                      bge a0, s5, _handle_key_down          # Move down
                      PANIC "reached unreachable code!"

# End handle_js_input --------------------------------------

# Fn find_key() -> u8? -------------------------------------
#
# Read a 'fresh' key from the keyboard
key:                  li t1, KEYBOARD                       # carrega o endereço de controle do KDMMIO
                      lw t0, 0(t1)                          # Le bit de Controle Teclado
                      bne t0, zero, _key_found              # Se não há tecla pressionada então vai para FIM
                      li a0, 0
                      ret

_key_found:           lw a0, 4(t1)                          # le o valor da tecla tecla
                      ori a0, a0, KEY_MASK
                      ret
# End find_key ---------------------------------------------

# Fn joistick() -> (i32?, bool) ----------------------------
#
# Read a 'fresh' (changed) value from the joystick. This
# function returns two values:
#   - a0: value of the changed input, zero if unchanged
#   - a1: direction of the change. 0 -> X; 1 -> Y.
joystick:             li t0, ADC_CH1                        # Read value on X direction
                      lw t1, 0(t0)
                      srli t1, t1, 4
                      slli t1, t1, 4

                      li t0, ADC_CH2                        # Read value on Y direction
                      lw t2, 0(t0)
                      srli t2, t2, 4
                      slli t2, t2, 4

                      # Debugging
                      mv a6, t1
                      mv a7, t2

                      # Check direction on the input change
                      bne t1, s4, _joystick_x_changed
                      bne t2, s5, _joystick_y_changed

                      # If reached here, no input has changed
                      li a0, 0                              # Unchanged joystick input code
                      li a1, 0                              # Unchanged joystick input code
                      ret

_joystick_x_changed:  mv a0, t1                             # Move read value to the return register
                      li a1,  0                             # Code for change detected on the X direction
                      ret

_joystick_y_changed:  mv a0, t2                             # Move read value to the return register
                      li a1, 1                              # Code for change detected on the Y direction
                      ret

# End joystick ---------------------------------------------

# Fn paint(img: u32, x: u32, y: u32, fr: u32) --------------
#
# Paints the referenced image at the provided position and
# frame. Depending on detected support this function will
# forward to paint_fast or paint_slow to do the work.
paint:                NOT_DE1 paint_slow                    # On the DE1, paint_fast seems to handle transparent pixels correctly
                      # Falls through and runs paint_fast
# End paint ------------------------------------------------

# Fn paint_fast(img: u32, x: u32, y: u32, fr: u32) ---------
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

# End paint_fast -------------------------------------------


# Fn paint_slow(img: u32, x: u32, y: u32, fr: u32) ---------
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

_paint_slow_loop:     lbu t5, 0(a0)                         # Load pixel from image
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

# End paint_slow -------------------------------------------

                      .include "./SYSTEMv14.s"
