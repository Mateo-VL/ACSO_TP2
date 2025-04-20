set disassembly-flavor intel
file ./bomb
break phase_1
break explode_bomb
layout split
layout regs
run < input.txt
