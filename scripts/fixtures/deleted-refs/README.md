Derivado de un borrado real en un proyecto de Raken.

Los fuentes llevan `.txt` al final (`page.tsx.txt`) para que el `tsc`, jest, vitest o knip del repo que los vendoriza no los recoja (#51); `check-deleted-refs.test.sh` les quita el `.txt` al armar el árbol de prueba.
