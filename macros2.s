######### Seta o endereco UTVEC ###############
.macro M_SetEcall(%label)
 	la t6,%label		# carrega em t6 o endere�o base das rotinas do sistema ECALL
 	csrrw zero,5,t6 	# seta utvec (reg 5) para o endere�o t6
 	csrrsi zero,0,1 	# seta o bit de habilita��o de interrup��o em ustatus (reg 0)
 	la tp,UTVEC		# caso nao tenha csrrw apenas salva o endereco %label em UTVEC
 	sw t6,0(tp)
 .end_macro

######### Chamada de Ecall #################
.macro M_Ecall
	DE1(NotECALL)
 	ecall		# tem ecall? s� chama
 	j FimECALL
NotECALL: la tp,UEPC
	la t6,FimECALL	# endereco ap�s o ecall
	sw t6,0(tp)	# salva UEPC
	lw tp,4(tp)	# le UTVEC
	jalr zero,tp,0	# chama UTVEC
FimECALL: nop
 .end_macro

######### Chamada de Uret #################
.macro M_Uret
	DE1(NotURET)
 	uret			# tem uret? s� retorna
NotURET: la tp,UEPC		# nao tem uret
	lw tp,0(tp)		# carrega o endereco UEPC
	jalr zero,tp,0		# pula para UEPC
 .end_macro

