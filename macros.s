# Macro POSITION(out: reg, x: reg, y: reg) ------ #
.macro POSITION(%out, %x, %y)

# Produces the apropriate offset for painting at  #
# the input 'x' and 'y' position                  #
                    li %out, DISPLAY_W            # Load display width
                    mul %out, %y, %out            # Multiply that by the 'y' position
                    add %out, %x, %out            # Get the final offset
.end_macro
