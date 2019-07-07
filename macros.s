# Macro POSITION(out: reg, x: reg, y: reg) -----------------
# From the (x, y) coordinates of a pixel on the screen,
# produces the apropriate offset that can be added to the
# appropriate frame base address to get the exact address
# of that pixel.
#
                      .macro POSITION(%out, %x, %y)
                      li %out, DISPLAY_W                    # Load display width
                      mul %out, %y, %out                    # Multiply that by the 'y' position
                      add %out, %x, %out                    # Get the final offset
                      .end_macro

# Macro DISPLAY(out: reg, offset: reg, frame: reg) ---------
# Produces the address of a pixel on the screen at the
# provided frame and offset.
#
                      .macro DISPLAY(%out, %offset, %frame)
                      mv tp, %offset
                      beqz %frame, frame_0
                      li %out, DISPLAY_1
                      j end
  frame_0:            li %out, DISPLAY_0
  end:                add %out, %out, tp
                      .end_macro

# Macro CASE(test: reg, value: imm, to: label) -------------
# Helper macro for checking if the value in reg is equal to
# a immediate value.
#
                      .macro CASE(%test, %value, %to)
                      li tp, %value
                      beq tp, %test, %to
                      .end_macro

# Macro INCREMENT(r: reg, amt: imm, max: imm) --------------
# Increments the value in reg by amt but does not let it go
# above the max value.
#
                      .macro INCREMENT(%r, %amt, %max)
                      addi %r, %r, %amt
                      li tp, %max
                      ble %r, tp,  end
                      mv %r, tp
 end:
                      .end_macro

# Macro DECREMENT(r: reg, amt: imm) ------------------------
# Decrements the value in reg by amt but does not let it
# become negative.
#
                      .macro DECREMENT(%r, %amt)
                      addi %r, %r, -%amt
                      bgez %r,  end
                      mv %r, zero
  end:
                      .end_macro

# Macro PANIC(msg: string) ---------------------------------
# Is it time to panic? Are there any other way?
#
                      .macro PANIC(%msg)
                      .data
  message:            .string %msg

                      .text
                      la a0, message
                      j panic
                      .end_macro

# Macro DE1(to: label) -------------------------------------
# Jump to label if running on the DE1-SoC
#
                      .macro DE1(%to)
                      li tp, 0x10008000                     # carrega tp = 0x10008000
                      bne gp, tp, %to                       # Na DE1 gp = 0 ! Não tem segmento .extern
                      .end_macro

# Macro NOT_DE1(to: label) ---------------------------------
# Jump to label if not running on the DE1-SoC
#
                      .macro NOT_DE1(%to)
                      li tp, 0x10008000                     # carrega tp = 0x10008000
                      beq gp, tp, %to                       # Na DE1 gp = 0 ! Não tem segmento .extern
                      .end_macro

# Macro M_SetEcall(eh: label) ------------------------------
# Set label as the exception handler and enable interrupt
#
                      .macro M_SetEcall(%eh)
                      la tp, %eh                            # carrega em t6 o endereço base das rotinas do sistema ECALL
                      csrrw zero, 5, tp                     # seta utvec (reg 5) para o endereço t6
                      csrrsi zero, 0, 1                     # seta o bit de habilitação de interrupção em ustatus (reg 0)
                      .end_macro

# Macro SAVE_REGS ------------------------------------------
# Save all registers on the stack.
#
                      .macro PUSH_REGS
                      addi sp, sp, -264                     # Salva todos os registradores na pilha
                      sw  x1,   0(sp)
                      sw  x2,   4(sp)
                      sw  x3,   8(sp)
                      sw  x4,  12(sp)
                      sw  x5,  16(sp)
                      sw  x6,  20(sp)
                      sw  x7,  24(sp)
                      sw  x8,  28(sp)
                      sw  x9,  32(sp)
                      sw x10,  36(sp)
                      sw x11,  40(sp)
                      sw x12,  44(sp)
                      sw x13,  48(sp)
                      sw x14,  52(sp)
                      sw x15,  56(sp)
                      sw x16,  60(sp)
                      sw x17,  64(sp)
                      sw x18,  68(sp)
                      sw x19,  72(sp)
                      sw x20,  76(sp)
                      sw x21,  80(sp)
                      sw x22,  84(sp)
                      sw x23,  88(sp)
                      sw x24,  92(sp)
                      sw x25,  96(sp)
                      sw x26, 100(sp)
                      sw x27, 104(sp)
                      sw x28, 108(sp)
                      sw x29, 112(sp)
                      sw x30, 116(sp)
                      sw x31, 120(sp)

                      fsw  f0, 124(sp)
                      fsw  f1, 128(sp)
                      fsw  f2, 132(sp)
                      fsw  f3, 136(sp)
                      fsw  f4, 140(sp)
                      fsw  f5, 144(sp)
                      fsw  f6, 148(sp)
                      fsw  f7, 152(sp)
                      fsw  f8, 156(sp)
                      fsw  f9, 160(sp)
                      fsw f10, 164(sp)
                      fsw f11, 168(sp)
                      fsw f12, 172(sp)
                      fsw f13, 176(sp)
                      fsw f14, 180(sp)
                      fsw f15, 184(sp)
                      fsw f16, 188(sp)
                      fsw f17, 192(sp)
                      fsw f18, 196(sp)
                      fsw f19, 200(sp)
                      fsw f20, 204(sp)
                      fsw f21, 208(sp)
                      fsw f22, 212(sp)
                      fsw f23, 216(sp)
                      fsw f24, 220(sp)
                      fsw f25, 224(sp)
                      fsw f26, 228(sp)
                      fsw f27, 232(sp)
                      fsw f28, 236(sp)
                      fsw f29, 240(sp)
                      fsw f30, 244(sp)
                      fsw f31, 248(sp)
                      .end_macro

# Macro POP_REGS -------------------------------------------
# Restore all registers that were previously saved on the
# stack.
# Note: registers a0 and fa0 are not restored because they
# are used to return values.
#
                      .macro POP_REGS
                      lw  x1,   0(sp)                       # recupera QUASE todos os registradores na pilha
                      lw  x2,   4(sp)
                      lw  x3,   8(sp)
                      lw  x4,  12(sp)
                      lw  x5,  16(sp)
                      lw  x6,  20(sp)
                      lw  x7,  24(sp)
                      lw  x8,  28(sp)
                      lw  x9,  32(sp)
                      # lw x10,  36(sp)                       # a0 retorno de valor
                      lw x11,  40(sp)
                      lw x12,  44(sp)
                      lw x13,  48(sp)
                      lw x14,  52(sp)
                      lw x15,  56(sp)
                      lw x16,  60(sp)
                      lw x17,  64(sp)
                      lw x18,  68(sp)
                      lw x19,  72(sp)
                      lw x20,  76(sp)
                      lw x21,  80(sp)
                      lw x22,  84(sp)
                      lw x23,  88(sp)
                      lw x24,  92(sp)
                      lw x25,  96(sp)
                      lw x26, 100(sp)
                      lw x27, 104(sp)
                      lw x28, 108(sp)
                      lw x29, 112(sp)
                      lw x30, 116(sp)
                      lw x31, 120(sp)

                      flw  f0, 124(sp)
                      flw  f1, 128(sp)
                      flw  f2, 132(sp)
                      flw  f3, 136(sp)
                      flw  f4, 140(sp)
                      flw  f5, 144(sp)
                      flw  f6, 148(sp)
                      flw  f7, 152(sp)
                      flw  f8, 156(sp)
                      flw  f9, 160(sp)
                      # flw f10, 164(sp)                      # fa0 retorno de valor
                      flw f11, 168(sp)
                      flw f12, 172(sp)
                      flw f13, 176(sp)
                      flw f14, 180(sp)
                      flw f15, 184(sp)
                      flw f16, 188(sp)
                      flw f17, 192(sp)
                      flw f18, 196(sp)
                      flw f19, 200(sp)
                      flw f20, 204(sp)
                      flw f21, 208(sp)
                      flw f22, 212(sp)
                      flw f23, 216(sp)
                      flw f24, 220(sp)
                      flw f25, 224(sp)
                      flw f26, 228(sp)
                      flw f27, 232(sp)
                      flw f28, 236(sp)
                      flw f29, 240(sp)
                      flw f30, 244(sp)
                      flw f31, 248(sp)
                      addi sp, sp, 264
                      .end_macro

# Constants ------------------------------------------------
#

                      # definicao do mapa de enderecamento de MMIO
                      .eqv VGAADDRESSINI0 0xFF000000
                      .eqv VGAADDRESSFIM0 0xFF012C00
                      .eqv VGAADDRESSINI1 0xFF100000
                      .eqv VGAADDRESSFIM1 0xFF112C00
                      .eqv NUMLINHAS      240
                      .eqv NUMCOLUNAS     320
                      .eqv VGAFRAMESELECT 0xFF200604

                      .eqv KDMMIO_Ctrl    0xFF200000
                      .eqv KDMMIO_Data    0xFF200004

                      .eqv Buffer0Teclado 0xFF200100
                      .eqv Buffer1Teclado 0xFF200104

                      .eqv TecladoxMouse  0xFF200110
                      .eqv BufferMouse    0xFF200114

                      .eqv AudioBase      0xFF200160
                      .eqv AudioINL       0xFF200160
                      .eqv AudioINR       0xFF200164
                      .eqv AudioOUTL      0xFF200168
                      .eqv AudioOUTR      0xFF20016C
                      .eqv AudioCTRL1     0xFF200170
                      .eqv AudioCTRL2     0xFF200174

                      # Sintetizador - 2015/1
                      .eqv NoteData       0xFF200178
                      .eqv NoteClock      0xFF20017C
                      .eqv NoteMelody     0xFF200180
                      .eqv MusicTempo     0xFF200184
                      .eqv MusicAddress   0xFF200188

                      .eqv IrDA_CTRL      0xFF20 0500
                      .eqv IrDA_RX        0xFF20 0504
                      .eqv IrDA_TX        0xFF20 0508

                      .eqv STOPWATCH      0xFF200510

                      .eqv LFSR           0xFF200514

                      .eqv KeyMap0        0xFF200520
                      .eqv KeyMap1        0xFF200524
                      .eqv KeyMap2        0xFF200528
                      .eqv KeyMap3        0xFF20052C
