                    .text

                    # Display ------------------- #
                    .eqv DISPLAY_0 0xFF000000
                    .eqv DISPLAY_1 0xFF100000
                    .eqv FRAME_SEL 0xFF200604

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

main:               li a0, DISPLAY_0              # endereco inicial da Memoria VGA
                    li a1, 0xFF012C00             # endereco final
                    la a2, fundo                  # endereço dos dados da tela na memoria
                    addi a2, a2, 8                # primeiro pixels depois das informações de nlin ncol
                    jal fundoBMP

                    li a0, 0xFF010F40             # endereco inicial da Memoria VGA
                    li a1, 0xFF01220F             # endereco final
                    la a2, jmpd                   # endereço dos dados da tela na memoria
                    addi a2, a2, 8                # primeiro pixels depois das informações de nlin ncol
                    li a3, 16
                    jal boneco

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

                    li a7, 10                     # syscall de exit
                    ecall

fundoBMP:           beq a0, a1, SAI               # Se for o último endereço então sai do loop
                    lb t0, 0(a2)                  # le um conjunto de 4 pixels : word
                    sb t0, 0(a0)                  # escreve a word na memória VGA
                    addi a0, a0, 1                # soma 4 ao endereço
                    addi a2, a2, 1
                    j fundoBMP                    # volta a verificar

boneco:             beq a0, a1, SAI
                    lb t0, 0(a2)                  # le um conjunto de 1 pixel
                    sb t0, 0(a0)
                    addi a3, a3, -1
                    addi a0, a0, 1                # soma 1 ao endereço
                    addi a2, a2, 1
                    beq a3 zero mudaLinha

                    j boneco

mudaLinha:          addi a0, a0, -16
                    addi a0, a0, 320
                    li a3, 16
                    j boneco

SAI:                ret

