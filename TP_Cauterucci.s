	.data
	.align 2
schedv:		.space 32     # Vector de direcciones de funciones
slist:		.word 0       # Puntero a la lista de bloques libres
cclist:		.word 0       # Puntero a la lista de categorías
wclist:		.word 0       # Puntero a la categoría en curso
menu:		.ascii "\nColecciones de objetos categorizados\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error:		.asciiz "\nError: "
catName:	.asciiz "\nIngrese el nombre de una categoria: "
selCat:		.asciiz "\nSe ha seleccionado la categoria:"
idObj:		.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:	.asciiz "\nIngrese el nombre de un objeto: "
success:	.asciiz "\nLa operación se realizo con éxito\n"
select_symbol: .asciiz "> "       # Símbolo para categoría seleccionada
success_del_msg:    .asciiz "Categoría eliminada exitosamente.\n"
close_msg:    .asciiz "El programa finalizó\n"
notFound:    .asciiz "Mensaje de objeto no encontrado.\n"
return:		.asciiz "\n"

.text
.globl main


main:
    la $t0, schedv             # Base del vector scheduler
    la $t1, newcategory        # Dirección de newcategory
    sw $t1, 4($t0)             # schedv[1] = newcategory

    la $t1, nextcategory       # Dirección de nextcategory
    sw $t1, 8($t0)             # schedv[2] = nextcategory
    
    la $t1, prevcategory       # Dirección de prevcategory
    sw $t1, 12($t0)             # schedv[3] = prevcategory
    
    la $t1, listcategories     # Dirección de listcategories
    sw $t1, 16($t0)            # schedv[4] = listcategories
    
    la $t1, delcategory     # Dirección de delcategory
    sw $t1, 20($t0)            # schedv[5] = delcategory
    
    la $t1, newobject	       # Dirección de newobject
    sw $t1, 24($t0)            # schedv[6] = newobject
    
    la $t1, listobjects      # Dirección de listobjects
    sw $t1, 28($t0)          # schedv[7] = listobjects
    
    #la $t1, delobject      # Dirección de delobject
    #sw $t1, 32($t0)          # schedv[8] = delobject
  
    j main_menu                # Continuar con el menú principal


main_menu:
    li $v0, 4                  # Imprimir mensaje
    la $a0, menu               # Mensaje del menú principal
    syscall

    li $v0, 5                  # Leer opción del usuario
    syscall
    move $t1, $v0              # Guardar la opción seleccionada

    # Validar la opción seleccionada (asegurarse de que esté dentro del rango válido)
    bltz $t1, menu_error        # Si opción < 0, error
    li $t2, 8                   # Si opción > 8, error
    bgt $t1, $t2, menu_error
    
    # Verificar si es la opción para cerrar la aplicación
    li $t2, 0                  # Suponemos que opción 0 es para salir
    beq $t1, $t2, close_app    # Si opción = 0, cerrar la aplicación


    # Calcular la posición en schedv (t1 * 4 bytes por posición)
    la $t0, schedv             # Base del vector scheduler
    sll $t2, $t1, 2            # Multiplicar opción por 4 (tamaño palabra)
    add $t0, $t0, $t2          # Apuntar a la posición correcta

    lw $t3, 0($t0)             # Cargar la dirección de la función
    beqz $t3, menu_error       # Si $t3 es 0, hay un error (función no definida)

    # Ahora que sabemos que $t3 no es 0, realizamos el salto
    jalr $t3                   # Saltar a la función correspondiente

    j main_menu                # Regresar al menú

    
    # Loop del menú principal
menu_loop:
    li $v0, 4               # Syscall para imprimir string
    la $a0, menu
    syscall

    li $v0, 5               # Syscall para leer entero
    syscall
    move $t0, $v0           # $t0 = opción seleccionada

    # Validar la opción
    bltz $t0, menu_error    # Si opción < 0, error
    li $t1, 8
    bgt $t0, $t1, menu_error # Si opción > 8, error

    # Llamar a la función correspondiente
    la $t2, schedv
    mul $t0, $t0, 4         # Índice * 4 (tamaño palabra)
    lw $t3, 0($t2)          # Carga la dirección de la función
    jalr $t3                # Llama a la función

    j menu_loop             # Regresa al menú
   
close_app:
    li $v0, 4                  # Imprimir mensaje de cierre
    la $a0, close_msg          # Mensaje de despedida
    syscall
    li $v0, 10                 # Salir del programa
    syscall


##
  
smalloc:
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16 # node size fixed 4 words
	li $v0, 9
	syscall # return node address in v0
	jr $ra
sfree: 
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist # $a0 node address in unused list
	jr $ra

exit:
    li $v0, 10              # Syscall para salir
    syscall

##


newcategory:
    addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName # input category name
	jal getblock
	move $a2, $v0 # $a2 = *char to category name
	la $a0, cclist # $a0 = list
	li $a1, 0 # $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist # update working list if was NULL

newcategory_end:
	li $v0, 0 # return success
	j end
	

###
nextcategory:
    addiu $sp, $sp, -4          # Reservar espacio en la pila
    sw $ra, 4($sp)              # Guardar $ra en la pila

    # Verificar si cclist está vacío (sin categorías)
    lw $t0, cclist              # $t0 = dirección base de la lista de categorías
    beqz $t0, error_no_categories_prev

    # Verificar si solo hay una categoría
    lw $t1, 12($t0)             # $t1 = siguiente nodo de la categoría actual
    beq $t0, $t1, error_one_category_prev

    # Avanzar a la siguiente categoría
    lw $t2, wclist              # $t2 = categoría activa actual
    beqz $t2, load_first        # Si wclist es NULL, cargar la primera categoría
    lw $t3, 12($t2)             # $t3 = siguiente nodo de la categoría activa
    sw $t3, wclist              # Actualizar wclist al siguiente nodo
    j success_select_category

load_first:
    sw $t0, wclist              # Si no hay categoría activa, seleccionar la primera
    j success_select_category

success_select_category:
    li $v0, 4                   # Imprimir mensaje de categoría seleccionada
    la $a0, selCat
    syscall
    lw $a0, 8($t3)              # Obtener nombre de la categoría seleccionada
    li $v0, 4
    syscall

nextcategory_end:
    j end
    


###
prevcategory:
    addiu $sp, $sp, -4          # Reservar espacio en la pila
    sw $ra, 4($sp)              # Guardar $ra en la pila

    # Verificar si cclist está vacío (sin categorías)
    lw $t0, cclist              # $t0 = dirección base de la lista de categorías
    beqz $t0, error_no_categories_prev

    # Verificar si solo hay una categoría
    lw $t1, 0($t0)              # $t1 = categoría previa de la actual
    beq $t0, $t1, error_one_category_prev

    # Retroceder a la categoría anterior
    lw $t2, wclist              # $t2 = categoría activa actual
    beqz $t2, load_last         # Si wclist es NULL, cargar la última categoría
    lw $t3, 0($t2)              # $t3 = categoría previa de la categoría activa
    sw $t3, wclist              # Actualizar wclist a la categoría previa
    j success_select_category_prev

load_last:
    lw $t3, 0($t0)              # Cargar la última categoría (prev del primero)
    sw $t3, wclist
    j success_select_category_prev

success_select_category_prev:
    li $v0, 4                   # Imprimir mensaje de categoría seleccionada
    la $a0, selCat
    syscall
    lw $a0, 8($t3)              # Obtener nombre de la categoría seleccionada
    li $v0, 4
    syscall

prevcategory_end:
	j end
  

###
listcategories:
    addiu $sp, $sp, -4           # Reservar espacio en la pila
    sw $ra, 4($sp)               # Guardar $ra en la pila

    # Verificar si cclist está vacío (sin categorías)
    lw $t0, cclist               # $t0 = dirección base de la lista de categorías
    beqz $t0, error_no_categories_list

    # Inicializar variables
    move $t1, $t0                # $t1 = puntero actual, empieza en cclist
    lw $t2, wclist               # $t2 = categoría seleccionada actual

list_loop:
    li $v0, 4                    # Imprimir categoría
    beq $t1, $t2, print_selected # Si es la categoría seleccionada, marcar con '>'

    # Categoría no seleccionada
    lw $a0, 8($t1)               # Cargar nombre de la categoría actual
    syscall                      # Imprimir nombre
    j check_next                 # Saltar al siguiente nodo

print_selected:
    la $a0, select_symbol        # Cargar el símbolo '>'
    syscall                      # Imprimir '>'
    lw $a0, 8($t1)               # Cargar nombre de la categoría actual
    li $v0, 4
    syscall                      # Imprimir nombre

check_next:
    lw $t1, 12($t1)              # $t1 = siguiente nodo
    beq $t1, $t0, list_end       # Si regresamos a cclist, hemos terminado
    j list_loop                  # Continuar al siguiente nodo


list_end:
	j end
    

###
delcategory:
    # Verificar si hay categoría seleccionada
    lw $t0, wclist               # Cargar categoría seleccionada
    beqz $t0, error_401          # Si no hay categoría seleccionada, error 401

    # Verificar si hay objetos en la categoría seleccionada
    lw $t1, 4($t0)               # Cargar dirección de la lista de objetos
    beqz $t1, delete_only_category # Si la lista está vacía, solo eliminar categoría

delobjects:                   # Borrar todos los objetos de la categoría
    move $t2, $t1                 # Puntero al objeto actual
delete_loop:
    beqz $t2, delete_only_category # Si no hay más objetos, ir a borrar categoría
    lw $t3, 12($t2)              # Cargar dirección del siguiente objeto
    jal add_to_free_list          # Liberar el objeto actual
    move $a0, $t2                # Dirección del objeto actual
    move $t2, $t3                # Pasar al siguiente objeto
    j delete_loop                # Continuar con el siguiente objeto

delete_only_category:             # Borrar la categoría seleccionada
    lw $t4, cclist               # Cargar la cabeza de la lista de categorías
    beqz $t4, error_401          # Si no hay categorías, error 401

    # Verificar si es la primera categoría
    beq $t4, $t0, delete_first_category

delete_middle_or_last:            # Eliminar categoría en medio o al final
    move $t5, $t4                # Puntero para recorrer la lista
find_previous:
    lw $t6, 12($t5)              # Cargar siguiente categoría
    beq $t6, $t0, unlink_category # Si encuentra la categoría seleccionada, desvincular
    move $t5, $t6                # Avanzar al siguiente nodo
    j find_previous

unlink_category:
    lw $t7, 12($t0)              # Cargar siguiente categoría
    sw $t7, 12($t5)              # Actualizar puntero del nodo anterior
    beqz $t7, clear_current_category # Si no hay siguiente categoría, limpiar selección
    sw $t7, wclist               # Actualizar categoría seleccionada
    j free_category_memory       # Liberar memoria de la categoría eliminada

delete_first_category:
    lw $t8, 12($t4)              # Cargar siguiente categoría
    sw $t8, cclist               # Actualizar cabeza de la lista de categorías
    beqz $t8, clear_current_category # Si no hay más categorías, nulificar seleccionada
    sw $t8, wclist               # Actualizar categoría seleccionada
    j free_category_memory

clear_current_category:
    li $zero, 0
    sw $zero, wclist             # Nulificar categoría seleccionada
    sw $zero, cclist             # Nulificar cabeza de la lista

    # Llamar al menú después de limpiar
    jal menu_loop
    jr $ra

free_category_memory:
    # Simular liberación de memoria al agregar la categoría a la lista libre
    jal add_to_free_list
    move $a0, $t0                # Dirección de la categoría

    # Confirmar eliminación exitosa
    li $v0, 4
    la $a0, success_del_msg
    syscall

    # Llamar al menú después de liberar memoria
    jal menu_loop                     # Regresar al menú principal
    jr $ra                       # Retornar correctamente

add_to_free_list:
    # Agregar nodo a la lista libre (slist)
    lw $t0, slist                # Cargar lista libre
    sw $t0, 12($a0)              # Conectar nodo actual con la lista libre
    sw $a0, slist                # Actualizar la cabeza de la lista libre
    jr $ra


###    
    

###
newobject:
    addiu $sp, $sp, -8            # Reservar espacio en la pila
    sw $ra, 4($sp)                # Guardar $ra
    sw $t0, 0($sp)                # Guardar $t0

    # Verificar si hay categorías (cclist)
    lw $t0, cclist                # Cargar la lista de categorías
    beqz $t0, error_501 # Si no hay categorías, error 501

    # Verificar si hay categoría seleccionada (wclist)
    lw $t1, wclist                # Cargar la categoría seleccionada
    beqz $t1, error_no_selected_listobj   # Si no hay categoría seleccionada, error 502

    # Solicitar nombre del objeto al usuario
    la $a0, objName               # Mensaje para ingresar el nombre
    jal getblock                  # Obtener el nombre del objeto
    move $a2, $v0                 # Guardar la dirección del nombre del objeto

    # Obtener lista de objetos de la categoría actual
    lw $t2, 4($t1)                # Dirección de la lista de objetos en la categoría
    beqz $t2, add_first_object    # Si no hay objetos, agregar el primero

    # Calcular ID del nuevo objeto
    lw $t3, 0($t2)                # Dirección del último objeto
    lw $t4, 8($t3)                # Leer el ID del último objeto
    addiu $t4, $t4, 1             # Nuevo ID = último ID + 1
    j add_object_to_list

add_first_object:
    li $t4, 1                     # ID del primer objeto
    move $t2, $zero               # No hay lista de objetos aún

add_object_to_list:
    jal smalloc                   # Asignar memoria para el nuevo objeto
    move $t5, $v0                 # Dirección del nuevo nodo
    sw $t4, 8($t5)                # Guardar el ID
    sw $a2, 12($t5)               # Guardar el nombre del objeto

    # Configurar lista circular de objetos
    beqz $t2, setup_first_object  # Si no hay objetos, configurar primero
    # Insertar al final de la lista
    lw $t6, 0($t2)                # Último nodo de la lista
    sw $t6, 0($t5)                # Nodo previo al nuevo objeto
    sw $t2, 12($t5)               # Nodo siguiente al nuevo objeto
    sw $t5, 12($t6)               # Actualizar next del último nodo
    sw $t5, 0($t2)                # Actualizar prev del primero
    j newobject_success

    
setup_first_object:
    sw $t5, 4($t1)                # Guardar el nuevo nodo en la categoría
    sw $t5, 0($t5)                # Configurar prev = self
    sw $t5, 12($t5)               # Configurar next = self
    j newobject_success


newobject_success:
    li $v0, 4                    # Imprimir mensaje de éxito
    la $a0, success
    syscall
    j newobject_end

newobject_end:
    lw $ra, 4($sp)               # Restaurar $ra
    lw $t0, 0($sp)               # Restaurar $t0
    addiu $sp, $sp, 8            # Restaurar el stack pointer
    jr $ra                       # Retornar

newobject_exit:
    lw $t0, 0($sp)                # Restaurar $t0
    lw $ra, 4($sp)                # Restaurar $ra
    addiu $sp, $sp, 8             # Restaurar el stack pointer
    jr $ra                        # Retornar
###

listobjects:
    addiu $sp, $sp, -8            # Reservar espacio en la pila
    sw $ra, 4($sp)                # Guardar $ra
    sw $t0, 0($sp)                # Guardar $t0

    # Verificar si hay categorías (cclist)
    lw $t0, cclist                # Cargar la lista de categorías
    beqz $t0, error_no_categories_listobj # Si no hay categorías, error 601

    # Verificar si hay categoría seleccionada (wclist)
    lw $t1, wclist                # Cargar la categoría seleccionada
    beqz $t1, error_no_selected_listobj   # Si no hay categoría seleccionada, error 502

    # Obtener lista de objetos de la categoría actual
    lw $t2, 4($t1)                # Dirección de la lista de objetos en la categoría
    beqz $t2, error_no_objects_listobj    # Si no hay objetos, error 602

    # Recorrer la lista de objetos e imprimir sus nombres
listobjects_loop:
    lw $t3, 12($t2)               # Cargar la dirección del siguiente objeto
    beqz $t3, listobjects_end     # Si llegamos al final de la lista (next = 0), fin

    lw $a0, 12($t2)               # Cargar el nombre del objeto
    li $v0, 4                     # Imprimir el nombre del objeto
    syscall

    # Avanzar al siguiente objeto
    move $t2, $t3
    j listobjects_loop

listobjects_end:
    li $v0, 4                     # Imprimir nueva línea
    la $a0, return
    syscall

    j listobjects_exit


listobjects_exit:
    lw $t0, 0($sp)                # Restaurar $t0
    lw $ra, 4($sp)                # Restaurar $ra
    addiu $sp, $sp, 8             # Restaurar el stack pointer
    jr $ra                        # Retornar
  
###	
					
##	
addnode:
    addi $sp, $sp, -8
    sw $ra, 8($sp)             # Guardar valor de retorno
    sw $a0, 4($sp)             # Guardar dirección de la lista en el stack

    jal smalloc                # Asignar memoria para el nodo
    sw $a1, 4($v0)             # Establecer contenido del nodo
    sw $a2, 8($v0)             # Guardar el nombre o contenido del nodo

    lw $a0, 4($sp)             # Recuperar dirección de la lista
    lw $t0, ($a0)              # Cargar primer nodo

    beqz $t0, addnode_empty_list

    # Agregar al final de la lista circular
addnode_to_end:
    lw $t1, ($t0) # last node address
    # update prev and next pointers of new node
    sw $t1, 0($v0)
    sw $t0, 12($v0)
    # update prev and first node to new node
    sw $v0, 12($t1)
    sw $v0, 0($t0)
    j addnode_exit

addnode_empty_list:
    sw $v0, ($a0)              # Actualiza cclist con el nuevo nodo
    sw $v0, 0($v0)             # prev apunta a sí mismo
    sw $v0, 12($v0)            # next apunta a sí mismo

addnode_exit:
    lw $ra, 8($sp)
    addi $sp, $sp, 8
    jr $ra
	
##	
delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) # get block address
	jal sfree # free block
	lw $a0, 4($sp) # restore argument a0
	lw $t0, 12($a0) # get address to next node of a0
node:
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) # get address to prev node
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) # get address to first node
again:
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1) # list point to next node
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1) # only one node
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra
	# a0: msg to ask
	# v0: block address allocated with string
getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra
###

print_error:
    addiu $sp, $sp, -8        # Reservar espacio en la pila
    sw $ra, 4($sp)            # Guardar $ra
    sw $a0, 0($sp)            # Guardar el código del error (en $a0)

    la $a0, error             # Cargar el mensaje de error
    li $v0, 4                 # Imprimir string
    syscall

    lw $a0, 0($sp)            # Cargar el código del error desde la pila
    li $v0, 1                 # Imprimir número
    syscall

    lw $ra, 4($sp)            # Restaurar $ra
    addiu $sp, $sp, 8         # Restaurar el stack pointer
    jr $ra                    # Retornar

###
print_error_and_jump:
    addiu $sp, $sp, -12         # Reservar espacio en la pila
    sw $ra, 8($sp)              # Guardar $ra
    sw $a0, 4($sp)              # Guardar el código del error
    sw $a1, 0($sp)              # Guardar la dirección a donde saltar

    la $a0, error               # Cargar el mensaje de error
    li $v0, 4                   # Imprimir string
    syscall

    lw $a0, 4($sp)              # Cargar el código del error
    li $v0, 1                   # Imprimir número
    syscall

    lw $ra, 8($sp)              # Restaurar $ra
    lw $a1, 0($sp)              # Cargar dirección para saltar
    addiu $sp, $sp, 12          # Restaurar el stack pointer
    jr $a1                      # Saltar a la dirección especificada


###
menu_error:
    li $a0, 101                # Código de error
    la $a1, main_menu          # Dirección del menú principal
    jal print_error_and_jump   # Llamar al procedimiento
 
error_one_category_prev:
    li $a0, 202                # Código de error
    la $a1, nextcategory_end   # Dirección para continuar
    jal print_error_and_jump

error_no_categories_prev:
    li $a0, 201                # Código de error
    la $a1, prevcategory_end   # Dirección para continuar
    jal print_error_and_jump

error_no_categories_list:
    li $a0, 301                # Código de error
    la $a1, list_end           # Dirección para continuar
    jal print_error_and_jump
    
error_401:
    li $a0, 401                # Código de error
    move $a1, $ra              # Retornar al llamador
    jal print_error_and_jump   # Llamar al procedimiento

###
error_501: # No hay categorías creadas
    li $a0, 501               # Código de error
    jal print_error           # Llamar al procedimiento de error
    j newobject_end           # Continuar con la lógica

 
 error_no_categories_listobj:
    li $a0, 601               # Código de error 601
    jal print_error           # Llamar al procedimiento de error
    j listobjects_exit        # Continuar con la lógica
    
error_no_selected_listobj:
    li $a0, 502               # Código de error 502
    jal print_error           # Llamar al procedimiento de error
    j listobjects_exit        # Continuar con la lógica

error_no_objects_listobj:
    li $a0, 602               # Código de error 602
    jal print_error           # Llamar al procedimiento de error
    j listobjects_exit        # Continuar con la lógica

end:
    lw $ra, 4($sp)              # Restaurar $ra
    addiu $sp, $sp, 4           # Restaurar el stack pointer
    jr $ra                      # Retornar

