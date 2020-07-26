# AER Mod Patch
#
# Install using "r2 -nwqi patch.r2 HyperLightDrifter"



# Resize binary from 0x017a_f460 to 0x0210_0000 bytes.
# We use [0x0200_0000, 0x0210_0000) for mod patch data.
r 0x02100000



# Locations.

# binary virtual offset
f voff @0x08048000

# original section header table
f orig.sht @0x017aefd8
# original dynamic section
f orig.ds @0x016eee8c

# aer mod section
f aer @0x02000000
# new program header table
f aer.pht @aer
# new dynamic string table
f aer.dstrt @aer.pht+0x1000



# Move the program header table.

# Move program header table contents.
s 0x34
yt 0x120 aer.pht
w0 0x120

# Update ELF header.
s 0x00
wv4 aer.pht @+0x1c
wv2 0x000a @+0x2c

# Update program header table entry.
s aer.pht
wv4 aer.pht @+0x04
wv4 aer.pht+voff @+0x08
wv4 aer.pht+voff @+0x0c
wv4 0x00000140 @+0x10
wv4 0x00000140 @+0x14



# Define new rwx LOAD segment for all mod patch data.
s aer.pht+0x20*9
wv4 0x00000001 @+0x00
wv4 aer @+0x04
wv4 aer+voff @+0x08
wv4 aer+voff @+0x0c
wv4 0x00100000 @+0x10
wv4 0x00100000 @+0x14
wv4 0x00000007 @+0x18
wv4 0x00001000 @+0x1c



# Move dynamic string table.

# Move dynamic string table contents.
s 0x00001cf4
yt 0x150d aer.dstrt
w0 0x150d

# Update dynamic section entries.
s orig.ds+0x8*25
wv4 aer.dstrt+voff @+0x04
s orig.ds+0x8*27
wv4 0x00003000 @+0x04

# Update section header table entry.
s orig.sht+0x28*6
wv4 aer.dstrt+voff @+0x0c
wv4 aer.dstrt @+0x10
wv4 0x00003000 @+0x14



# Move PLT relocation table to 0x0200_b000.

# Move relocation table contents.
s 0x000036fc
yt 0xcd0 0x0200b000
w0 0xcd0

# Update dynamic section entries.
s 0x016eee8c+0x08*31
wv4 0x00000ce8 @+0x04
s 0x016eee8c+0x08*33
wv4 0x0a053000 @+0x04

# Update section header table entry.
s 0x17aefd8+0x28*10
wv4 0x0a053000 @+0x0c
wv4 0x0200b000 @+0x10
wv4 0x00000ce8 @+0x14



# Expand dynamic symbol table to accound for new hooks.

# Update section header table entry.
s 0x17aefd8+0x28*5
wv4 0x00002f90 @+0x14



# Add mod runtime environment as library dependency.

# Add dynamic string.
s 0x02002510
wz aermre.so

# Add dynamic section entry.
s 0x016eee8c+0x08*40
wv4 0x00000001 @+0x00
wv4 0x00001510 @+0x04



# Add mod runtime environment initialization hook.

# Add dynamic string.
s 0x02002530
wz AERHookInit

# For some reason, the dynamic symbol slot 0x1ab causes a segmentation
# fault, so we use slots > 0x1ab.

# Add dynamic symbol.
s 0x00000264+0x10*0x1ac
wv4 0x00001530 @+0x00
wv4 0x0a04d000 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xcd0
wv4 0x0a04c000 @+0x00
wv4 0x0001ac00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004000
wv4 0x0a04d006

# Add PLT entry.
s 0x02005000
# jmp dword [0x0a04c000]
wx ff 25 00 c0 04 0a
so+1
# push 0xcd0
wx 68 d0 0c 00 00
so+1
# jmp section..plt
wx e9 e0 f3 ff fd

# Add breakout thunk.
s 0x02008000
wa sub esp, 0x27c; so+1
# lea ebx, [actionInstanceDestroy]; push ebx
wx 8d 1d f0 ed 09 09 53; so+2
# lea ebx, [actionInstanceCreate]; push ebx
wx 8d 1d e0 72 26 09 53; so+2
# lea ebx, [gmlScriptSetdepth]; push ebx
wx 8d 1d d0 9c fa 08 53; so+2
# lea ebx, [actionEventPerform]; push ebx
wx 8d 1d 20 a5 21 09 53; so+2
# lea ebx, [actionObjectAdd]; push ebx
wx 8d 1d 60 0f 00 09 53; so+2
# lea ebx, [actionSpriteAdd]; push ebx
wx 8d 1d 50 be fe 08 53; so+2
# lea ebx, [instanceTable]; push ebx
wx 8d 1d b8 78 aa 09 53; so+2
# lea ebx, [objectTableHandle]; push ebx
wx 8d 1d c0 91 a0 09 53; so+2
# lea ebx, [spriteTable]; push ebx
wx 8d 1d b0 91 80 09 53; so+2
# lea ebx, [currentRoom]; push ebx
wx 8d 1d 38 36 ac 09 53; so+2
# lea ebx, [currentRoomIndex]; push ebx
wx 8d 1d 6c 36 ac 09 53; so+2
# lea ebx, [numRooms]; push ebx
wx 8d 1d 08 c9 ab 09 53; so+2
# lea ebx, [keysReleasedTable]; push ebx
wx 8d 1d 34 54 aa 09 53; so+2
# lea ebx, [keysHeldTable]; push ebx
wx 8d 1d 34 53 aa 09 53; so+2
# lea ebx, [keysPressedTable]; push ebx
wx 8d 1d 34 55 aa 09 53; so+2
# lea ebx, [numTicks]; push ebx
wx 8d 1d 64 ff ab 09 53; so+2
wa call 0x02005000; so+1 # AERHookInit
wa add esp, 4 * 16; so+1
wa jmp 0x011cb70c

# Inject call to thunk.
s 0x011cb706
wa jmp 0x02008000
so+1
wa nop



# Add mod runtime environment update hook.

# Add dynamic string.
s 0x02002550
wz AERHookUpdate

# Add dynamic symbol.
s 0x00000264+0x10*0x1ad
wv4 0x00001550 @+0x00
wv4 0x0a04d010 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xcd8
wv4 0x0a04c004 @+0x00
wv4 0x0001ad00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004004
wv4 0x0a04d016

# Add PLT entry.
s 0x02005010
# jmp dword [0x0a04c004]
wx ff 25 04 c0 04 0a
so+1
# push 0xcd8
wx 68 d8 0c 00 00
so+1
# jmp section..plt
wx e9 d0 f3 ff fd

# Add breakout thunk.
s 0x02009000
wa call 0x02005010 # AERHookUpdate
so+1
wa call 0x01219830 # gameTick
so+1
wa jmp 0x011cbf89

# Inject call to thunk.
s 0x011cbf84
wa jmp 0x02009000



# Add mod runtime environment event hook.

# Add dynamic string.
s 0x02002570
wz AERHookEvent

# Add dynamic symbol.
s 0x00000264+0x10*0x1ae
wv4 0x00001570 @+0x00
wv4 0x0a04d020 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xce0
wv4 0x0a04c008 @+0x00
wv4 0x0001ae00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004008
wv4 0x0a04d026

# Add PLT entry.
s 0x02005020
# jmp dword [0x0a04c008]
wx ff 25 08 c0 04 0a
so+1
# push 0xce0
wx 68 e0 0c 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk.
s 0x02009100
# Perform overwritten code.
wx c7 45 dc 00 00 00 00; so+1 # mov [ebp+var_24], 0
# Setup call.
wa push eax; so+1 # eventNum
wa push ecx; so+1 # eventType
wa push edx; so+1 # targetObjectIndex
# Perform call.
wa call 0x02005020; so+1 # AERHookEvent
# Cleanup call.
wa add esp, 4 * 3; so+1
# Exit thunk.
wa jmp 0x11d2551

# Inject call to thunk.
s 0x11d254a
wa jmp 0x02009100; so+1
wa nop; so+1
wa nop
