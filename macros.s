# Macro POSITION(reg, reg, reg) ----------------------------
#
# Produces the apropriate offset for painting at the input
# 'x' and 'y' position
.macro POSITION(%out, %x, %y)
                      li %out, DISPLAY_W                    # Load display width
                      mul %out, %y, %out                    # Multiply that by the 'y' position
                      add %out, %x, %out                    # Get the final offset
.end_macro

# Macro DISPLAY(reg, reg, reg) -----------------------------
#
# Produces the full addr for the display at the provided
# frame and offset
.macro DISPLAY(%out, %offset, %frame)
                      mv tp, %offset
                      beqz %frame, frame_0
                      li %out, DISPLAY_1
                      j end
frame_0:              li %out, DISPLAY_0
end:                  add %out, %out, tp
.end_macro

# Macro CASE(reg, value, label) ----------------------------
#
# If the value in reg is equal to value, then jump to label
.macro CASE(%reg, %value, %label)
                      li t0, %value
                      beq t0, %reg, %label
.end_macro

# Macro DE1(label) -----------------------------------------
#
# Verifica se eh a DE1-SoC
.macro DE1(%salto)
                      li tp, 0x10008000                     # carrega tp = 0x10008000
                      bne gp, tp, %salto                    # Na DE1 gp = 0 ! Não tem segmento .extern
.end_macro

# Macro M_SetEcall(label) ----------------------------------
#
# Seta o endereco UTVEC
.macro M_SetEcall(%label)
                      la t6, %label                         # carrega em t6 o endereço base das rotinas do sistema ECALL
                      csrrw zero, 5, t6                     # seta utvec (reg 5) para o endereço t6
                      csrrsi zero, 0, 1                     # seta o bit de habilitação de interrupção em ustatus (reg 0)
                      la tp, UTVEC                          # caso nao tenha csrrw apenas salva o endereco %label em UTVEC
                      sw t6, 0(tp)
.end_macro

# Macro M_Ecall --------------------------------------------
#
# Chamada de Ecall
.macro M_Ecall
                      DE1(NotECALL)
                      ecall                                 # tem ecall? só chama
                      j FimECALL
NotECALL:             la tp, UEPC
                      la t6, FimECALL                       # endereco após o ecall
                      sw t6, 0(tp)                          # salva UEPC
                      lw tp, 4(tp)                          # le UTVEC
                      jalr zero, tp, 0                      # chama UTVEC
FimECALL:             nop
.end_macro

# Macro M_Uret ---------------------------------------------
#
# Chamada de Uret
.macro M_Uret
                      DE1(NotURET)
                      uret                                  # tem uret? só retorna
NotURET:              la tp, UEPC                           # nao tem uret
                      lw tp, 0(tp)                          # carrega o endereco UEPC
                      jalr zero, tp, 0                      # pula para UEPC
.end_macro

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
