# AER Mod Patch
#
# Install using "r2 -nwqi patch.r2 HyperLightDrifter"
#
# Copyright 2021 the aerpatch authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
e asm.arch = x86
e asm.bits = 32



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



# Macros.

# Fill n bytes at current seek with nop sled to ud2.
(deadcode n; b $0-2; wb 90; wa ud2 @+$0-2; s+$0)



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



# Move version symbol table to 0x0200_e000.

# Move version symbol table contents.
s 0x00003202
yt 0x352 0x0200c000
w0 0x352
w0 0xcae @0x200c000+0x352

# Update dynamic section entry.
s 0x016eee8c+0x08*39
wv4 0x0a054000 @+0x04

# Update section header table entry.
s 0x17aefd8+0x28*7
wv4 0xa054000 @+0x0c
wv4 0x0200c000 @+0x10
wv4 0x00001000 @+0x14



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



# Expand dynamic symbol table to account for new hooks.

# Update section header table entry.
s 0x17aefd8+0x28*5
wv4 0x00002f90 @+0x14



# Add mod runtime environment as library dependency.

# Add dynamic string.
s 0x02002510
wz libaermre.so

# Add dynamic section entry.
s 0x016eee8c+0x08*40
wv4 0x00000001 @+0x00
wv4 0x00001510 @+0x04



# Add mod runtime environment initialization hook.

# Add dynamic string.
s 0x02002530
wz AERHookInit

# Add dynamic symbol.
s 0x00000264+0x10*0x1a9
wv4 0x00001530 @+0x00
wv4 0x0a04d000 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xcd0
wv4 0x0a04c000 @+0x00
wv4 0x0001a900 @+0x04
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
# Setup call.
# Function references.
wa push 0x08fa9cd0; so+1 # gmlScriptSetdepth
wa push 0x08de23b0; so+1 # gmlScriptGoToRoom
wa push 0x090c01c0; so+1 # API_dsMapAddMap
wa push 0x090bfa00; so+1 # API_dsMapSet
wa push 0x090c12a0; so+1 # API_dsMapFindValue
wa push 0x090bf010; so+1 # API_dsMapCreate
wa push 0x090631b0; so+1 # Instance_setMotionPolarFromCartesian
wa push 0x09063840; so+1 # Instance_setMaskIndex
wa push 0x090660a0; so+1 # Instance_setPosition
wa push 0x0909edf0; so+1 # actionInstanceDestroy
wa push 0x092679a0; so+1 # actionInstanceChange
wa push 0x092672e0; so+1 # actionInstanceCreate
wa push 0x091291d0; so+1 # actionDrawSetFont
wa push 0x090d3fa0; so+1 # actionDrawSelf
wa push 0x0912a330; so+1 # actionDrawText
wa push 0x0910c770; so+1 # actionDrawRectangle
wa push 0x0910bf80; so+1 # actionDrawTriangle
wa push 0x0910d1d0; so+1 # actionDrawEllipse
wa push 0x0910b9f0; so+1 # actionDrawLine
wa push 0x08ff5b20; so+1 # actionDrawSpriteGeneral
wa push 0x0910ae40; so+1 # actionDrawSetAlpha
wa push 0x0910b080; so+1 # actionDrawGetAlpha
wa push 0x0921a520; so+1 # actionEventPerform
wa push 0x09000f60; so+1 # actionObjectAdd
wa push 0x09031580; so+1 # actionFontAdd
wa push 0x08fec740; so+1 # actionSpriteReplace
wa push 0x08febe50; so+1 # actionSpriteAdd
wa push 0x09267e00; so+1 # actionRoomGoto
wa push 0x09127390; so+1 # actionMouseGetY
wa push 0x09127360; so+1 # actionMouseGetX
# Global references.
wa push 0x09518c19; so+1 # unknownEventAddress
wa push 0x094a47d8; so+1 # eventWrapperClass
wa push 0x0948781c; so+1 # eventClass
wa push 0x09ac53bc; so+1 # stepEventSubscribers
wa push 0x09acbfb8; so+1 # stepEventSubscriberCounts
wa push 0x09ac4bbc; so+1 # alarmEventSubscribers
wa push 0x09acbbb8; so+1 # alarmEventSubscriberCounts
wa push 0x09809028; so+1 # instanceLocalTable
wa push 0x09aa78b8; so+1 # instanceTable
wa push 0x09a091c0; so+1 # objectTableHandle
wa push 0x09ab3b34; so+1 # currentFont
wa push 0x09772b94; so+1 # currentFontIndex
wa push 0x09aa1d6c; so+1 # fontTable
wa push 0x098091ac; so+1 # spriteTable
wa push 0x09ac3638; so+1 # currentRoom
wa push 0x09ac366c; so+1 # currentRoomIndex
wa push 0x09abc908; so+1 # roomTable
wa push 0x09aa564c; so+1 # mousePosY
wa push 0x09aa5648; so+1 # mousePosX
wa push 0x09aa563f; so+1 # mouseButtonsReleasedTable
wa push 0x09aa563c; so+1 # mouseButtonsHeldTable
wa push 0x09aa5642; so+1 # mouseButtonsPressedTable
wa push 0x09aa5434; so+1 # keysReleasedTable
wa push 0x09aa5334; so+1 # keysHeldTable
wa push 0x09aa5534; so+1 # keysPressedTable
wa push 0x09ac33f0; so+1 # deltaTime
wa push 0x09abff64; so+1 # numSteps
wa push 0x09aa7fe0; so+1 # maps
# Perform call.
wa call 0x02005000; so+1 # AERHookInit
# Cleanup call.
wa add esp, 4 * 58; so+1
# Perform overwritten code.
wa call 0x00f88140; so+1 # Instance::FUN_08fd0140
# Exit thunk.
wa jmp 0x00627169

# Inject call to thunk.
s 0x00627164
wa jmp 0x02008000



# Add mod runtime environment step hook.

# Add dynamic string.
s 0x02002550
wz AERHookStep

# Add dynamic symbol.
s 0x00000264+0x10*0x1aa
wv4 0x00001550 @+0x00
wv4 0x0a04d010 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xcd8
wv4 0x0a04c004 @+0x00
wv4 0x0001aa00 @+0x04
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
# No call setup necessary.
# Perform call.
wa call 0x02005010; so+1 # AERHookStep
# No call cleanup necessary.
# Perform overwritten code.
wa call 0x01219260; so+1 # updateInstances
# Exit thunk.
wa jmp 0x01219dd9

# Inject call to thunk.
s 0x01219dd4
wa jmp 0x02009000



# Add mod runtime environment event hook.

# Add dynamic string.
s 0x02002570
wz AERHookEvent

# Add dynamic symbol.
s 0x00000264+0x10*0x1ab
wv4 0x00001570 @+0x00
wv4 0x0a04d020 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xce0
wv4 0x0a04c008 @+0x00
wv4 0x0001ab00 @+0x04
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

# Add breakout thunk 1.
s 0x02009100
# No call setup necessary.
# Perform call.
wa call 0x02005020; so+1 # AERHookEvent
# No call cleanup necessary.
# Perform overwritten code.
wa call 0x012382e0; so+1 # lookupEventWrapper
# Exit thunk.
wa jmp 0x011d21b0

# Inject call to thunk 1.
s 0x011d21ab
wa jmp 0x02009100

# Add breakout thunk 2.
s 0x0200910f
# No call setup necessary.
# Perform call.
wa call 0x02005020; so+1 # AERHookEvent
# No call cleanup necessary.
# Perform overwritten code.
wa call 0x012382e0; so+1 # lookupEventWrapper
# Exit thunk.
wa jmp 0x011d22ed

# Inject call to thunk 2.
s 0x011d22e8
wa jmp 0x0200910f



# Add mod runtime environment load data hook.

# Add dynamic string.
s 0x02002590
wz AERHookLoadData

# Add dynamic symbol.
s 0x00000264+0x10*0x1ac
wv4 0x00001590 @+0x00
wv4 0x0a04d030 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xce8
wv4 0x0a04c00c @+0x00
wv4 0x0001ac00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x0200400c
wv4 0x0a04d036

# Add PLT entry.
s 0x02005030
# jmp dword [0x0a04c00c]
wx ff 25 0c c0 04 0a
so+1
# push 0xce8
wx 68 e8 0c 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk.
s 0x02009200
# Perform overwritten code.
wa call 0x00f88140; so+1 # loadMapSecure
# Setup call.
wa push eax; so+1 # data map index
# Perform call.
wa call 0x02005030; so+1 # AERHookLoadData
# Cleanup call.
wa pop eax; so+1
# Exit thunk.
wa jmp 0x00dd822b;

# Inject call to thunk.
s 0x0x00dd8226
wa jmp 0x02009200



# Add mod runtime environment save data hook.

# Add dynamic string.
s 0x020025b0
wz AERHookSaveData

# Add dynamic symbol.
s 0x00000264+0x10*0x1ad
wv4 0x000015b0 @+0x00
wv4 0x0a04d040 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xcf0
wv4 0x0a04c010 @+0x00
wv4 0x0001ad00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004010
wv4 0x0a04d046

# Add PLT entry.
s 0x02005040
# jmp dword [0x0a04c010]
wx ff 25 10 c0 04 0a
so+1
# push 0xcf0
wx 68 f0 0c 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk.
s 0x02009300
# Setup call.
wa push [esi]; so+1 # data map index
# Perform call.
wa call 0x02005040; so+1 # AERHookSaveData
# Cleanup call.
wa add esp, 4 * 1; so+1
# Perform overwritten code.
wa call 0x00f88140; so+1 # saveMapSecure
# Exit thunk.
wa jmp 0x00e75d4d;

# Inject call to thunk.
s 0x00e75d48
wa jmp 0x02009300



# Add mod runtime environment room start hook.

# Add dynamic string.
s 0x020025d0
wz AERHookRoomStart

# Add dynamic symbol.
s 0x00000264+0x10*0x1ae
wv4 0x000015d0 @+0x00
wv4 0x0a04d050 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xcf8
wv4 0x0a04c014 @+0x00
wv4 0x0001ae00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004014
wv4 0x0a04d056

# Add PLT entry.
s 0x02005050
# jmp dword [0x0a04c014]
wx ff 25 14 c0 04 0a
so+1
# push 0xcf8
wx 68 f8 0c 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk.
s 0x02009400
# No call setup necessary.
# Perform call.
wa call 0x02005050; so+1 # AERHookRoomStart
# No call cleanup necessary.
# Perform overwritten code.
wa call 0x011d27d0; so+1 # otherEventLoop
# Exit thunk.
wa jmp 0x01216671;

# Inject call to thunk.
s 0x0121666c
wa jmp 0x02009400



# Add mod runtime environment room end hook.

# Add dynamic string.
s 0x020025f0
wz AERHookRoomEnd

# Add dynamic symbol.
s 0x00000264+0x10*0x1af
wv4 0x000015f0 @+0x00
wv4 0x0a04d060 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xd00
wv4 0x0a04c018 @+0x00
wv4 0x0001af00 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004018
wv4 0x0a04d066

# Add PLT entry.
s 0x02005060
# jmp dword [0x0a04c018]
wx ff 25 18 c0 04 0a
so+1
# push 0xd00
wx 68 00 0d 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk.
s 0x02009500
# Perform overwritten code.
wa call 0x011d27d0; so+1 # otherEventLoop
# No call setup necessary.
# Perform call.
wa call 0x02005060; so+1 # AERHookRoomEnd
# No call cleanup necessary.
# Exit thunk.
wa jmp 0x012167d4;

# Inject call to thunk.
s 0x012167cf
wa jmp 0x02009500



# Add mod runtime environment room change hook.

# Add dynamic string.
s 0x02002610
wz AERHookRoomChange

# Add dynamic symbol.
s 0x00000264+0x10*0x1b0
wv4 0x00001610 @+0x00
wv4 0x0a04d070 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xd08
wv4 0x0a04c01c @+0x00
wv4 0x0001b000 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x0200401c
wv4 0x0a04d076

# Add PLT entry.
s 0x02005070
# jmp dword [0x0a04c01c]
wx ff 25 1c c0 04 0a
so+1
# push 0xd08
wx 68 08 0d 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk.
s 0x02009600
# No call setup necessary.
# Perform call.
wa call 0x02005070; so+1 # AERHookRoomChange
# No call cleanup necessary.
# Perform overwritten code.
wa call 0x01102690; so+1 # isRoomIndexValid
# Exit thunk.
wa jmp 0x0121fe39;

# Inject call to thunk.
s 0x0121fe34
wa jmp 0x02009600



# Add mod runtime environment primitive pointer copy hook.

# Add dynamic string.
s 0x02002630
wz AERHookPrimitivePointerCopy

# Add dynamic symbol.
s 0x00000264+0x10*0x1b1
wv4 0x00001630 @+0x00
wv4 0x0a04d080 @+0x04
wv4 0x00000000 @+0x08
wv1 0x12 @+0x0c
wv1 0x00 @+0x0d
wv2 0x0000 @+0x0e

# Add PLT relocation table entry.
s 0x0200b000+0xd10
wv4 0x0a04c020 @+0x00
wv4 0x0001b100 @+0x04
wv1 0x07 @+0x04

# Add GOT PLT entry.
s 0x02004020
wv4 0x0a04d086

# Add PLT entry.
s 0x02005080
# jmp dword [0x0a04c020]
wx ff 25 20 c0 04 0a
so+1
# push 0xd10
wx 68 10 0d 00 00
so+1
wa jmp 0x000043f0 # section..plt

# Add breakout thunk 1.
s 0x02009700
# Setup call.
wa push dword [ebp-0x1c]; so+1
wa push dword [ebp-0x18]; so+1
# Perform call.
wa call 0x02005080; so+1 # AERHookPrimitivePointerCopy
# Cleanup call.
wa add esp, 4 * 2; so+1
# No overwritten code.
# Exit thunk.
wa jmp 0x00f97a1e

# Redirect switch case to thunk 1.
s 0x0143f504
wv4 0x0a051700
# Disable original switch case handler.
s 0x00f979df
.(deadcode 15)
