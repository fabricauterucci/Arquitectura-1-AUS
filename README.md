# Arquitectura de las Computadoras
Trabajo Práctico No 3
Estructura de datos en assembly del MIPS R2000
Profesores: Ing. Walter Lozano e Ing. Alejandro Rodríguez Costello

## Descripción
Este proyecto es una aplicación que permite gestionar un sistema de categorías,
con listas circulares.

## Tecnologías
- Lenguaje: MIPS Assembly
- Herramientas: MARS Simulator
- Otras tecnologías: Syscalls de MIPS

## Uso
Para usar este programa, hay que correr el simulador MARS 4.5, ensamblar y ejecutar el codigo, para seleccionar las opciones del menú para gestionar las categorías y objetos.


Código escrito por Fabrizio Cauterucci. Por cuestiones de tiempo, hay cosas que se pueden refactorizar y no llegué a hacerlas.

## Errores y Problemas Conocidos
- El punto 7 no funciona correctamente en algunas condiciones. (Eliminar objeto de categoria por ID). Por cuestiones de tiempo no lo pude hacer andar.

 Los puntos del 1 al 6 funcionan correctamente: crear categoría, seleccionarla, listarla, borrarla, anexar objeto manteniendo la selección y listar los objetos. Dejé la lógica que tenía del punto 7. Se eliminan comentarios repetitivos o innecesarios. Simplifico el menú y completo los códigos de errores.
