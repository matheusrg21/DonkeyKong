                      .data
                      # Numero de Notas a tocar
NUM:                  .word 22
                      # lista de nota, duração, nota, duração, nota, duraçãoo,...
NOTAS:                .word   66,  700,  64,  700,  59, 800,   0,  200,
                      .word   64,  700,  67,  700,  69, 700,  64,  800,    0,  200,
                      .word   67,  700,   0,  100,  67, 700,   0,  200,
                      .word   66,  700,  67,  700,  69, 700,  62,  800,   71, 1010,    0,  100,   69, 1010,    0,  800
                      .text
                      .include "./macros.s"
                      .include "./macros2.s"

                      M_SetEcall exceptionHandling

                      la s0, NUM                            # define o endereço do número de notas
                      lw s1, 0(s0)                          # le o numero de notas
                      la s0, NOTAS                          # define o endereço das notas
                      li t0, 0                              # zera o contador de notas
                      li a2, 95                             # define o instrumento
                      li a3, 127                            # define o volume

LOOP:                 beq t0, s1, FIM                       # contador chegou no final? então  vá para FIM
                      lw a0, 0(s0)                          # le o valor da nota
                      lw a1, 4(s0)                          # le a duracao da nota
                      li a7, 31                             # define a chamada de syscall
                      M_Ecall                                 # toca a nota
                      mv a0, a1                             # passa a duração da nota para a pausa
                      li a7, 32                             # define a chamada de syscal
                      M_Ecall                                 # realiza uma pausa de $a0 ms
                      addi s0, s0, 8                        # incrementa para o endereço da próxima nota
                      addi t0, t0, 1                        # incrementa o contador de notas
                      j LOOP                                # volta ao loop

                      # toca a nota
FIM:                  la s0, NUM
                      lw s1, 0(s0)                          # le o numero de notas
                      la s0, NOTAS                          # define o endereço das notas
                      li t0, 0
                      j LOOP

                      li a7, 10                             # define o syscall Exit
                      M_Ecall                                 # exit

                      .include "./SYSTEMv13.s"
