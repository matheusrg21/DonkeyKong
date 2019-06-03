# Macro POSITION(reg, reg, reg) -----------------
#
# Produces the apropriate offset for painting at
# the input 'x' and 'y' position
.macro POSITION(%out, %x, %y)
                    li %out, DISPLAY_W            # Load display width
                    mul %out, %y, %out            # Multiply that by the 'y' position
                    add %out, %x, %out            # Get the final offset
.end_macro

# Macro DISPLAY(reg, reg, reg) ------------------
#
# Produces the full addr for the display at the
# provided frame and offset
.macro DISPLAY(%out, %offset, %frame)
                    mv tp, %offset
                    beqz %frame, frame_0
                    li %out, DISPLAY_1
                    j end
frame_0:            li %out, DISPLAY_0
end:                add %out, %out, tp
.end_macro
