################################################################
#>>>>>>>>>>>>>>>>>>> MAQUINA VIRTUAL MIPS-USB<<<<<<<<<<<<<<<<<<#
#  Giuli Latella USBid: 08-10596                               #
#  Fernando Gonzalez USBid: 08-10464                           #
################################################################

.data

	mensaje1: .asciiz "Bienvenido diga el nombre del archivo: "
	mensaje2: .asciiz "si es windows escriba 1, si es Unix escriba 2: "
	mensaje3: .asciiz "Error: Caracter especial en la entrada"
	opp: .asciiz "Op = "
	rd: .asciiz "Rd = "
	ra: .asciiz"Ra = "
	rb: .asciiz"Rb = "
	inm: .asciiz"   o   Inm = " 
		.align 2
	buffer: .space 12 		#espacio asignado para la lectura de las tres palabras de los hexadecimales
		.align 2
	nombre:.space 80	 	#espacio para el nombre de archivo de entrada
		.align 2
	codigo: .space 65536	 	#espacio para lmacenar las instrucciones en hexadecimal
	
.text 

main:
################################################################
#       Solicitando nombre de archivo a decodificar            #
################################################################
#imprimiendo mensaje de solicitud del archivo
	li $v0,4
	la $a0,mensaje1 #imprime el mensaje 1
	syscall

#solicita nombre 
	li $v0,8
	la $a0,nombre  #almacena en nombre el String
	la $a1,80      #el limite de caracteres es 80
	syscall

#recorta el \n del nombre
	li $s0,0                # Set index to 0
remove:
    	lb $a3,nombre($s0)      # carga caracter del index
    	addi $s0,$s0,1          # incrementa index
    	bnez $a3,remove         # loop hasta que el limite sea alcanzado
    	beq $a1,$s0,skip        # no quite \n cuando no este presente
    	subiu $s0,$s0,2         # Backtrack index a '\n'
    	sb $0, nombre($s0)      # agrega el caracter terminal en su posicion
skip:

################################################################
#       Solicitando tipo de sistema operativo a usar           #
################################################################
#impresion de solicitud tipo de S.O.
	li $v0,4
	la $a0,mensaje2     #imprime el mensaje2
	syscall

 	li $v0, 5
 	syscall
	beq $v0,1, else	    #si es windows el tam(buffer) es 10
 	li $t0,9	    #si es unix el tam(buffer) es 9
 	li $t3,0x0a
	j salta
 else:
 	li $t0,10
 	li $t3, 0x0d
 salta:
 	
################################################################
#                 Lectura del Archivo                          #
################################################################	
# Apertura de archivo
open:
	li	$v0, 13		# Open File Syscall
	la	$a0, nombre	# carga el nombre del archivo
	li	$a1, 0		# flag de solo lectura
	li	$a2, 0		# ignorar modo
	syscall
	move	$s4, $v0	# salvar descriptor del archivo

        li $t8,0		#inicializo en cero un contador de palabras decodificadas
	la $s0, buffer	        # $s0 pongo la direccion del buffer	
	la $s1, codigo		# asigno a un registro la etiqueta donde tengo el espacio para la decodificacion
	
# Lectura de Datos
read:
	li	$v0, 14		# Read File Syscall
	move	$a0, $s4	# cargar el descriptor del archivo
	move	$a1, $s0	# carga la direccion del buffer
	move	$a2, $t0        # tamano del buffer
	syscall

	beqz $v0, impresion		#si no ha leido todo el archivo vuelve a leer
	
	
################################################################
#                     Decodificacion                           #
################################################################
        li $t9,0		   #inicializo en cero $t9 para recorrer las palabras en la etiqueta codigo
	move $t2, $zero		   #reinicio el registro conversor para dar espacio a la nueva instruccion
convertir:	

	lb $t1,0($s0) 	           #carga byte del buffer
	beq $t1,$t3, almacenaje    #si llego al salto de linea almacena palabra
	blt $t1,0x30, error_ascii  #si es menor a 0x30 es caracter especial
	bgt $t1,0x39, letra        #si el byte es mayor o igual a 0x39 ve a letra
	subi $t1,$t1,0x30          #en caso contrario restale 0x30 y dejalo en $t0	
	sll $t2, $t2, 4            #desplaza 4bytes en $t2 para agregar a la derecha
	add $t2, $t2,$t1	   #agrega a la derecha el caracter convertido
	addi $s0,$s0,1		   #desplaza al siguiente byte a convertir en buffer
	b convertir
letra:  
	blt $t1,0x47, mayuscula	     #si el byte es menor a 0x47 es una letra mayuscula
	blt $t1,0x61, error_ascii    #si es menor a 0x61 es caracter especial
	bgt $t1,0x66, error_ascii    #si es mayor a 0x66 es caracter especial
	subi $t1,$t1,0x57            #resta 0x57 al byte 
	sll $t2, $t2, 4              #desplaza 4 bytes a la derecha para agregar a la izquierda
	add $t2, $t2,$t1	     #agrega el byte convertido a la izquierda
	addi $s0,$s0,1               #desplaza al siguiente byte a convertir en el buffer
	b convertir
	
mayuscula:
	beq $t1,0x40, error_ascii    #si es caracter especial va a impresion de error
	bgt $t1,0x46, error_ascii    #si es caracter especial va a la impresion de error
	subi $t1,$t1,0x37            #Resto 0x37 para dejarlo en su representacion
	sll $t2, $t2, 4              #desplaza 4 bytes a la derecha para agregar el caracter
	add $t2, $t2,$t1	     #agrega a derecha el caracter convertido a izquierda
	addi $s0,$s0,1		     #desplaza al siguiente byte para convertir en buffer
	b convertir
	
almacenaje:
	sw $t2,($s1)		#guarda la palabra decodificada en la etiqueta codigo
	addi $s1,$s1,4		#desplaza a la siguiente posicion en la etiqueta codigo
	subi $s0,$s0,8		#desplazo el buffer 
	addi $t8,$t8,1		#suma un elemento al contador de instrucciones decodificadas
	b read			#leer el siguiente hexadecimal

################################################################
#                  Impresion de resultados                     #
################################################################		
impresion:
#impresion de la palabra que guarda el hexadecimal entero
	lw $t6, codigo($t9)
	li	$v0, 34		# Print String Syscall
	move	$a0, $t6	# cargar contenidos a la impresion
	syscall
	
#impresion de salto de linea	
	li $a0, 10
	li $v0,11
	syscall	
	
#impresion del string de igualdad del OP		
	li $v0,4
	la $a0, opp
	syscall	

#mascara para tomar e imprimir el primer bit de la palabra
	li $t4,0xf0000000	#tomo el primer bit de la izquierda
	and $t7,$t6,$t4		#mismo bit que tomo de la primera palabra almaceno en $t7
	srl $t7,$t7,28		#corro el bit hacia la derecha del hexadecimal
	li $s2,0x00000009	#almaceno el 9 hexadecimal en $s2
	bgt $t7,$s2, letter	#si el valor almacenado es mayor a 9 es una letra
	move $a0, $t7		#de lo contrario imprime el entero
	li $v0,1
	syscall
	j jump
	
letter:
	addi $t7,$t7,0x57	#si es una letra, se le suma 0x57 					
	move $a0, $t7		# se imprime el valor transformado
	li $v0, 11
	syscall
jump:

#mismo procedimiento se repite para cada uno de los bits 
#que integran al valor hexadecimal alojado en memoria en
#forma de palabras, imprimiendolo en su respectiva etiqueta.

#proceso para el segundo bit del operador
	li $t4,0x0f000000
	and $t7,$t6,$t4
	srl $t7,$t7,24
	li $s2,0x00000009
	bgt $t7,$s2, letter1
	move $a0, $t7
	li $v0,1
	syscall
	j jump1
	
letter1:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump1:

#proceso para el bit de registro destino	
registroDestino:

	li $a0, 10
	li $v0,11
	syscall		
	li $v0,4
	la $a0, rd
	syscall	
	li $t4,0x00f00000
	and $t7,$t6,$t4
	srl $t7,$t7,20
	li $s2,0x00000009
	bgt $t7,$s2, letter2
	move $a0, $t7
	li $v0,1
	syscall
	j jump2
	
letter2:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump2:

#proceso para el bit del registro fuente 1
registroFuente1:
	li $a0, 10
	li $v0,11
	syscall		
	li $v0,4
	la $a0, ra
	syscall	
	li $t4,0x000f0000
	and $t7,$t6,$t4
	srl $t7,$t7,16
	li $s2,0x00000009
	bgt $t7,$s2, letter3
	move $a0, $t7
	li $v0,1
	syscall
	j jump3
	
letter3:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump3:

#proceso para el bit del registro fuente 2
regitroFuente2:
	li $a0, 10
	li $v0,11
	syscall		
	li $v0,4
	la $a0, rb
	syscall	
	li $t4,0x0000f000
	and $t7,$t6,$t4
	srl $t7,$t7,12
	li $s2,0x00000009
	bgt $t7,$s2, letter4
	move $a0, $t7
	li $v0,1
	syscall
	j jump4
	
letter4:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump4:

#proceso para los 4 bits de la constante inmediata	
ConstanteInmediata:	
	li $v0,4
	la $a0, inm
	syscall	
	li $t4,0x0000f000
	and $t7,$t6,$t4
	srl $t7,$t7,12
	li $s2,0x00000009
	bgt $t7,$s2, letter5
	move $a0, $t7
	li $v0,1
	syscall
	j jump5
	
letter5:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump5:

#proceso para el segundo bit de la constante inmediata
	li $t4,0x00000f00
	and $t7,$t6,$t4
	srl $t7,$t7,8
	li $s2,0x00000009
	bgt $t7,$s2, letter6
	move $a0, $t7
	li $v0,1
	syscall
	j jump6
	
letter6:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump6:

#proceso para el tercer bit de la constante inmediata
	li $t4,0x000000f0
	and $t7,$t6,$t4
	srl $t7,$t7,4
	li $s2,0x00000009
	bgt $t7,$s2, letter7
	move $a0, $t7
	li $v0,1
	syscall
	j jump7
	
letter7:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump7:

#proceso para el ultimo bit de la constante inmediata
	li $t4,0x0000000f
	and $t7,$t6,$t4
	li $s2,0x00000009
	bgt $t7,$s2, letter8
	move $a0, $t7
	li $v0,1
	syscall
	j jump8
	
letter8:
	addi $t7,$t7,0x57					
	move $a0, $t7
	li $v0, 11
	syscall
jump8:

	li $a0, 10
	li $v0,11
	syscall
	li $a0, 10
	li $v0,11
	syscall
	
	subi $t8,$t8,1		#resta una unidad al contador de palabras por imprimir
	addi $t9,$t9,4		#desplaza 4 bytes para ir a la siguiente palabra
	bnez $t8,impresion	#mientras queden palabras por imprimir, ve a impresion
	
error_ascii:
	beqz $t8,pass		#si ya no quedan palabras por imprimir termina el programa
	li $v0,4
	la $a0, mensaje3	#imprime el mensaje de error:caracter especial
	syscall
pass:

li $v0,10
syscall	

#FIN

