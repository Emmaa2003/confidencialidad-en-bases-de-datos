# Controles ISO/IEC 27001:2022 para la confidencialidad en la administración de bases de datos

Curso: Administración de Bases de Datos · Universidad Nacional de Costa Rica · II Ciclo 2026
Estudiante: Emmanuel Rodriguez Picado · Profesor: Johnny Villalobos Murillo

Auditoría de confidencialidad sobre Oracle Database 21c Express Edition (21.3.0.0.0), PDB `XEPDB1`, aplicando el ciclo PHVA.

## Contenido

| Archivo | Qué es |
|---|---|
| `Informe_ISO27001_Confidencialidad.pdf` | Informe: marco teórico, evidencias, correcciones, límites y referencias APA 7. |
| `auditoria-iso27001.html` | Artefacto interactivo: riesgos, tareas del DBA, mapeo de controles, controles observables, matriz de evaluación y batería de pruebas. |
| `01_verificacion_confidencialidad.sql` | Fase Verificar. Pruebas P-01 a P-17, solo lectura. |
| `02_actuar_correcciones.sql` | Fase Actuar. Correcciones A-01 a A-04; **modifica la base**. |
| `Tabla_Uso_IA_y_Declaracion.pdf` | Tabla de uso de IA y declaración jurada con firma digital. |

## Cómo ejecutar los scripts

1. Conectarse como `SYSTEM` al servicio `XEPDB1` con SQL Developer.
2. Script 01: abrir y ejecutar con F5. No modifica nada.
3. Script 02: ejecutar un bloque a la vez (seleccionar y F5). Pedirá una contraseña de prueba en el bloque 2; no debe guardarse en el repositorio.
4. El bloque 3 requiere conexión como `SYS`; desde `SYSTEM` falla con ORA-01927.
