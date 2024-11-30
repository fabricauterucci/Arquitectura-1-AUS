	.data
	.align 2
schedv:	.space 32     # Vector de direcciones de funciones
slist:		.word 0       # Puntero a la lista de bloques libres
cclist:	.word 0       # Puntero a la lista de categorías
wclist:	.word 0       # Puntero a la categoría en curso
menu:	.ascii "\nColecciones de objetos categorizados\n"
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
error:	.asciiz "\nError: "
catName:	.asciiz "\nIngrese el nombre de una categoria: \n"
selCat:	.asciiz "\nSe ha seleccionado la categoria:\n"
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: \n"
objName:	.asciiz "\nIngrese el nombre de un objeto:\n "
success:	.asciiz "\nLa operación se realizo con éxito\n"
select_symbol:		.asciiz "> "       # Símbolo para categoría seleccionada
success_del_msg:	.asciiz "\nCategoría eliminada exitosamente.\n"
close_msg:		.asciiz "\nEl programa finalizó\n"
notFound:			.asciiz "\nMensaje de objeto no encontrado.\n"
delete_success_msg: .asciiz "\nObjeto eliminado.\n"
ask_id_msg:		.asciiz "\nPor favor ingrese el id del objeto a eliminar:\n "
return:			.asciiz "\n"

.text
.globl main

main:      
	la $t0, schedv # initialization scheduler vector
        la $t1, newcategory
        sw $t1, 0($t0)
        la $t1, nextcategory
        sw $t1, 4($t0)
        la $t1, prevcategory
        sw $t1, 8($t0)
        la $t1, listcategories
        sw $t1, 12($t0)
        la $t1, delcategory
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
#	la $t1, delobject
#	sw $t1, 28($t0)

main_menu:   li $v0, 4
	la $a0, menu
	syscall
	li $v0, 5
	syscall     # Pedir un entero
	move $t2, $v0
condiciones:    blt $t2, 0, menu_error
	bgt $t2, 8, menu_error
	beq $t2, 0, close_app
	beq $t2, 1, opc1        
	beq $t2, 2, opc2
	beq $t2, 3, opc3    
	beq $t2, 4, opc4
	beq $t2, 5, opc5
	beq $t2, 6, opc6
	beq $t2, 7, opc7
	beq $t2, 8, opc8
	j main_menu
        
opc1:       jal newcategory
        j main_menu
opc2:       jal nextcategory
        j main_menu
opc3:       jal prevcategory
        j main_menu
opc4:       jal listcategories
        j main_menu
opc5:       jal delcategory
        j main_menu
opc6:       jal newobject
        j main_menu
opc7:       jal listobjects
        j main_menu
opc8:       #jal deleteObject
        j main_menu
   
close_app:
    li $v0, 4                  
    la $a0, close_msg          
    syscall
    li $v0, 10                 # Salir del programa
    syscall

###
 
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

###

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
	addiu $sp, $sp, -4          
	sw $ra, 4($sp) 

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
	sw $t3, wclist              
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
	addiu $sp, $sp, -4           
	sw $ra, 4($sp)               

    # Verificar si cclist está vacío (sin categorías)
	lw $t0, cclist               
	beqz $t0, error_no_categories_list

    # Inicializar variables
	move $t1, $t0                # $t1 = puntero actual, empieza en cclist
	lw $t2, wclist               # $t2 = categoría seleccionada actual

list_loop:
	li $v0, 4                    
	beq $t1, $t2, print_selected # Si es la categoría seleccionada, marcar con '>'

    # Categoría no seleccionada
	lw $a0, 8($t1)               
	syscall                      # Imprimir categoria
	j check_next                 # Saltar al siguiente nodo

print_selected:
	la $a0, select_symbol
	syscall                      # Imprimir '>'
	lw $a0, 8($t1)               # Cargar nombre de la categoría actual
	li $v0, 4
	syscall                      

check_next:
	lw $t1, 12($t1)              # $t1 = siguiente nodo
	beq $t1, $t0, list_end       # Si regresamos a cclist, hemos terminado
	j list_loop                  # Continuar al siguiente nodo

list_end:
	j end

###

delcategory:    
	lw $t0, cclist           # Cargar la lista principal en $t0
	beqz $t0, error_401      

        addiu $sp, $sp, -4       
        sw $ra, 4($sp)           

        lw $a0, wclist           
        beqz $a0, no_selection   # Si no hay selección actual, error

        lw $t1, 12($a0)          # Cargar la dirección del siguiente nodo en $t1
        beq $a0, $t1, only_one   # Si el nodo apunta a sí mismo, es el único

        # Actualizar la selección a la siguiente categoría
        move $t2, $t1            # $t2 apunta al siguiente nodo
        sw $t2, wclist           # Actualizar `wclist` con el siguiente nodo

        # Eliminar el nodo seleccionado
	la $a1, cclist           # Apuntar a la lista principal
	jal delnode              
	j delcategory_end

only_one:  
	sw $zero, wclist         # No hay más nodos, deseleccionar
	la $a1, cclist           # Apuntar a la lista principal
	jal delnode              # Eliminar el único nodo
	j delcategory_end

no_selection:
	li $v0, 4
	la $a0, error_no_categories_list
	syscall                
	j delcategory_end

delcategory_end:
	li $v0, 4
	la $a0, success   
	syscall

        lw $ra, 4($sp)     
        addiu $sp, $sp, 4
        jr $ra                  

delcategory1:    
        lw $t0, cclist
        beqz $t0, error_401
        addiu $sp, $sp, -4
        sw $ra, 4($sp)
        lw $a0, wclist 
        la $a1, slist 
        jal delnode
delcategory_end1:
        li $v0, 4
        la $a0, success
        syscall
        li $v0, 0
        lw $ra, 4($sp)
        addiu $sp, $sp, 4
        jr $ra

###    
    

###

newobject:  
        lw $t0, cclist 
        beqz $t0, error_501
        addiu $sp, $sp, -4
        sw $ra, 4($sp)
        la $a0, objName
        jal getblock
        move $a2, $v0
        lw $t0, wclist
        la $a0, 4($t0)
        li $a1, 0 
        jal addnode
        lw $t0, 0($v0)
        lw $t1, 4($t0)
        addi $t1, $t1, 1
        sw $t1, 4($v0)
newobject_end:  
        li $v0, 0 # return success
        lw $ra, 4($sp)
        addiu $sp, $sp, 4
        jr $ra  

###

listobjects:    
        lw $t0, wclist # $t0 = selected category in progress
        beqz $t0, error_no_categories_listobj # If there are no lists, error code 601
        lw $t0, 4($t0) # $t0 = list of objects of the current category 
        beqz $t0, error_no_objects_listobj    # Si no hay objetos, error 602
        li $t2, 0 # i = 0
        lw $t4, ($t0) # $t4 = first element of object list

listobj_loop:    bne $t0, $t4, listobj_else
        addi $t2, $t2, 1 # if cclist is repeated: i++
        
listobj_else:    beq $t2, 2, listobjects_end
        lw $t3, 8($t0)  # object name
        li $v0, 4
        la $a0, ($t3)
        syscall # print the object
        lw $t4, ($t0) # $t4 = first element of object list
        lw $t0, 12($t0) # next object
        j listobj_loop

listobjects_end:
        li $v0, 4
        la $a0, success
        syscall
        li $v0, 0
        jr $ra

listobjects_exit:
	#jr $ra    
   	j main_menu
  
###	

deleteObject:
	lw $t0, wclist               # $t0 = categoría seleccionada en curso
	beqz $t0, error_no_category

	lw $t0, 4($t0)               # $t0 = lista de objetos de la categoría actual
	beqz $t0, notFound           # Si no hay objetos, no se encuentra el ID

    # Preguntar al usuario por el ID
	la $a0, ask_id_msg           # Cargar mensaje para solicitar el ID
	li $v0, 4                    # Syscall para imprimir string
	syscall

	li $v0, 5                    # Syscall para leer entero
	syscall
	move $a1, $v0                # Guardar el ID ingresado en $a1

    # Búsqueda y eliminación del objeto
	li $t1, 0                    # Índice inicial en la lista de objetos
	li $t2, 0                    # Flag para verificar si se encontró el ID
    
deleteObject_loop:
	lw $t3, 0($t0)               # $t3 = ID del objeto actual
	beqz $t3, not_Found           # Si llegamos al final de la lista, no se encuentra el ID

	beq $t3, $a1, deleteObject_found # Si el ID actual es igual al provisto, eliminar
	addiu $t0, $t0, 4            # Avanzar al siguiente objeto en la lista
	j deleteObject_loop          # Repetir el proceso

deleteObject_found:
    # Eliminación lógica del objeto:
	lw $t4, 4($t0)               # $t4 = Dirección del siguiente objeto
	sw $t4, -4($t0)              # Sobreescribir la dirección actual con la del siguiente
	li $t2, 1                    # Establecer flag de éxito
	j deleteObject_exit          # Salir del procedimiento

not_Found:
	la $a0, notFound         # Cargar mensaje de error "notFound"
	li $v0, 4                    # Imprimir string
    	syscall
	j deleteObject_exit

deleteObject_exit:
	beqz $t2, main_menu          # Si no se encontró el ID, regresar al menú
    # Si se eliminó correctamente, mensaje de éxito
	la $a0, delete_success_msg   # Cargar mensaje de éxito
	li $v0, 4                    # Imprimir string
	syscall
	j main_menu                  # Regresar al menú principal
			
###

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
	
###

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
	addiu $sp, $sp, -8 
	sw $ra, 4($sp)      
	sw $a0, 0($sp)     

	la $a0, error         
	li $v0, 4                
	syscall

	lw $a0, 0($sp)      
	li $v0, 1                
	syscall

	lw $ra, 4($sp)            
	addiu $sp, $sp, 8       
	jr $ra                    

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

	lw $ra, 8($sp)          
	lw $a1, 0($sp)         
	addiu $sp, $sp, 12   
	jr $a1                      

### Errores

menu_error:
	li $a0, 101                
	la $a1, main_menu          
	jal print_error_and_jump   
 
error_one_category_prev:
	li $a0, 202                
	la $a1, nextcategory_end  
	jal print_error_and_jump

error_no_categories_prev:
	li $a0, 201              
	la $a1, prevcategory_end 
	jal print_error_and_jump

error_no_categories_list:
	li $a0, 301                
	la $a1, list_end          
	jal print_error_and_jump
    
error_401:
	li $a0, 401                
	move $a1, $ra          
	jal print_error_and_jump   

###

error_501: # No hay categorías creadas
	li $a0, 501             
	move $t0, $a0
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        la $a0, ($t0)
	syscall
	li $v0, 4
	la $a0, return
	syscall
	jr $ra                    

error_no_selected_listobj:
	li $a0, 502            
	jal print_error         
	j listobjects_exit     

error_no_categories_listobj:
	li $a0, 601            
	jal print_error         
	j listobjects_exit     

error_no_objects_listobj:
	li $a0, 602               
	jal print_error           
	j listobjects_exit       
	
error_no_category:
	li $a0, 701                
	jal print_error             
	j deleteObject_exit

end:
	lw $ra, 4($sp)              # Restaurar $ra
	addiu $sp, $sp, 4           # Restaurar el stack pointer
	jr $ra                      # Retornar
