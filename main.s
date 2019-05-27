                    .data

                    .include "fundo1_320x240.s"
                    .include "jump_man_parado_direita_16x16.s"

                    .text

                    li a0,0xFF000000              # endereco inicial da Memoria VGA
                    li a1,0xFF012C00              # endereco final
                    la a2,fundo                   # endereço dos dados da tela na memoria
                    addi a2,a2,8                  # primeiro pixels depois das informações de nlin ncol
                    jal fundoBMP

                    li a0,0xFF010F40              # endereco inicial da Memoria VGA
                    li a1,0xFF01220F              # endereco final
                    la a2,jmpd                    # endereço dos dados da tela na memoria
                    addi a2,a2,8                  # primeiro pixels depois das informações de nlin ncol
                    li a3 16
                    jal boneco

                    # Polling do teclado e echo na tela
                    li s0,0                       # zera o contador
CONTA:              addi s0,s0,1                  # incrementa o contador
                    call KEY                      # le o teclado sem wait
                    j CONTA                       # volta ao loop

                    ### Apenas verifica se há tecla apertada
KEY:                li t1,0xFF200000              # carrega o endereço de controle do KDMMIO
                    lw t0,0(t1)                   # Le bit de Controle Teclado
                    andi t0,t0,0x0001             # mascara o bit menos significativo
                    beq t0,zero,FIM               # Se não há tecla pressionada então vai para FIM
                    lw t2,4(t1)                   # le o valor da tecla tecla

FIM:                ret                           # retorna

                    li a7,10                      # syscall de exit
                    ecall

fundoBMP:           beq a0,a1,SAI                 # Se for o último endereço então sai do loop
                    lb t0,0(a2)                   # le um conjunto de 4 pixels : word
                    sb t0,0(a0)                   # escreve a word na memória VGA
                    addi a0,a0,1                  # soma 4 ao endereço
                    addi a2,a2,1
                    j fundoBMP                    # volta a verificar

boneco:             beq a0,a1,SAI
                    lb t0,0(a2)                   # le um conjunto de 1 pixel
                    sb t0,0(a0)
                    addi a3 a3 -1
                    addi a0,a0,1                  # soma 1 ao endereço
                    addi a2,a2,1
                    beq a3 zero mudaLinha

                    j boneco

mudaLinha:          addi a0 a0 -16
                    addi a0 a0 320
                    li a3 16
                    j boneco

SAI:                ret

