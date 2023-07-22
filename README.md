# Generador de Carta de Ajuste de TVE
Descripción en Verilog de un diseño digital que genera una imagen en PAL, entrelazada, de la carta de ajuste de TVE.

La imagen generada está basada en la descripción que de ella hay en la Wikipedia: https://es.wikipedia.org/wiki/Carta_de_ajuste_de_Televisi%C3%B3n_Espa%C3%B1ola

La información sobre la temporización de las señales PAL se ha obtenido de: http://martin.hinner.info/vga/pal.html

Imagen generada en una FPGA Artix 7-200 (el core ocupa muchísimo menos), y mostrada en una TV LG
![](https://github.com/mcleod-ideafix/carta_ajuste_tve/blob/main/img/foto_en_hard_real.jpg)

Representación gráfica de la señal generada, mostrando los dos campos, y la zona de blanking y sincronismos.
![](https://github.com/mcleod-ideafix/carta_ajuste_tve/blob/main/img/fotograma_carta_ajuste_tve_dos_campos.png)

Recreación de la carta de ajuste, obtenida de la Wikipedia, y base del diseño de la carta en este core.
![](https://github.com/mcleod-ideafix/carta_ajuste_tve/blob/main/img/Recreation_of_TVE_Carta_Ajuste.png)
