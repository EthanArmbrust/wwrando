
; This patch modifies the game's code to make certain items progressive, so even if you get them out of order, they will always be upgraded, never downgraded.
; (Note that most of the modifications for this are in the make_items_progressive function of tweaks.py, not here.)


; Swap out the item ID of progressive items for item get events as well as for field items so that their model and item get text change depending on what the next progressive tier of that item you should get is.
.open "sys/main.dol"
.org 0x80026A24 ; In createDemoItem (for item get events)
  ; Convert progressive item ID before storing in params
  bl convert_progressive_item_id_for_createDemoItem
.org @NextFreeSpace
.global convert_progressive_item_id_for_createDemoItem
convert_progressive_item_id_for_createDemoItem:
  stwu sp, -0x10 (sp)
  mflr r0
  stw r0, 0x14 (sp)
  
  mr r3, r26 ; createDemoItem keeps the item ID in r26
  bl convert_progressive_item_id ; Get the correct item ID
  mr r26, r3 ; Put it back where createDemoItem expects it, in r26
  
  li r3, 259 ; And then simply replace the line of code in createDemoItem that we overwrote to call this function
  
  lwz r0, 0x14 (sp)
  mtlr r0
  addi sp, sp, 0x10
  blr
.org 0x800F5550 ; In daItem_create
  ; Read params, convert progressive item ID, and store back
  bl convert_progressive_item_id_for_daItem_create
.org @NextFreeSpace
.global convert_progressive_item_id_for_daItem_create
convert_progressive_item_id_for_daItem_create:
  stwu sp, -0x10 (sp)
  mflr r0
  stw r0, 0x14 (sp)
  
  lbz r3, 0xB3 (r31) ; Read this field item's item ID from its params (params are at 0xB0, the item ID is has the mask 0x000000FF)
  bl convert_progressive_item_id ; Get the correct item ID
  stb r3, 0xB3 (r31) ; Store the corrected item ID back into the field item's params
  
  ; Then we return the item ID in r0 so that the next few lines in daItem_create can use it.
  mr r0, r3
  
  lwz r3, 0x14 (sp)
  mtlr r3
  addi sp, sp, 0x10
  blr
.org 0x8012E7B8 ; In dProcGetItem_init__9daPy_lk_cFv
  ; Read item ID property for this event action and convert progressive item ID
  bl convert_progressive_item_id_for_dProcGetItem_init_1
.org @NextFreeSpace
.global convert_progressive_item_id_for_dProcGetItem_init_1
convert_progressive_item_id_for_dProcGetItem_init_1:
  stwu sp, -0x10 (sp)
  mflr r0
  stw r0, 0x14 (sp)
  
  lwz r3, 0x30C (r28) ; Read the item ID property for this event action
  bl convert_progressive_item_id ; Get the correct item ID
  
  ; Then we return the item ID in r0 so that the next few lines in dProcGetItem_init can use it.
  mr r0, r3
  
  lwz r3, 0x14 (sp)
  mtlr r3
  addi sp, sp, 0x10
  blr
.org 0x8012E7DC ; In dProcGetItem_init__9daPy_lk_cFv
  bl convert_progressive_item_id_for_dProcGetItem_init_2
.org @NextFreeSpace
.global convert_progressive_item_id_for_dProcGetItem_init_2
convert_progressive_item_id_for_dProcGetItem_init_2:
  stwu sp, -0x10 (sp)
  mflr r0
  stw r0, 0x14 (sp)
  
  lbz r3, 0x52AC (r3) ; Read the item ID from 803C9EB4
  bl convert_progressive_item_id ; Get the correct item ID
  
  ; Then we return the item ID in r27 so that the next few lines in dProcGetItem_init can use it.
  mr r27, r3
  
  lwz r0, 0x14 (sp)
  mtlr r0
  addi sp, sp, 0x10
  blr
.close
.open "files/rels/d_a_shop_item.rel"
.org 0x9C0
  ; This is where the shop item would originally read its item ID from its params & 0x000000FF and store them to shop item entity+0x63A.
  ; We need to call a custom function to make the item look progressive, but because this is in a relocatable object file, we can't easily add a new function call to the main executable where there was no function call originally.
  ; So instead we first remove this original code.
  nop
  nop
.org 0x8B8
  bl convert_progressive_item_id_for_shop_item
.org @NextFreeSpace
.global convert_progressive_item_id_for_shop_item
convert_progressive_item_id_for_shop_item:
  stwu sp, -0x10 (sp)
  mflr r0
  stw r0, 0x14 (sp)
  
  ; Replace the call to savegpr we overwrote to call this custom function
  bl _savegpr_28
  mr r30, r3 ; Preserve the shop item entity pointer
  
  lbz r3, 0xB3 (r30)
  bl convert_progressive_item_id ; Get the correct item ID
  stb r3, 0x63A (r30) ; Store the item ID to shop item entity+0x63A
  
  mr r3, r30 ; Put the shop item entity pointer back into r3, because that's where the function that called this one expects it to be
  
  lwz r0, 0x14 (sp)
  mtlr r0
  addi sp, sp, 0x10
  blr
.close




; Fix a big where buying a progressive item from the shop would not show the item get animation if it's the tier 2+ item.
.open "files/rels/d_a_npc_bs1.rel"
.org 0x1D00
  ; For the Bait Bag slot.
  bl custom_getSelectItemNo_progressive
.org 0x1F3C
  ; For the 3 Rock Spire Shop Ship slots.
  bl custom_getSelectItemNo_progressive
; Acts as a replacement to getSelectItemNo, but should only be called when the shopkeeper is checking if the item get animation should play or not, in order to have that properly show for progressive items past the first tier.
; If this was used all the time as a replacement for getSelectItemNo it would cause the shop to be buggy since it uses the item ID to know what slot it's on.
.org @NextFreeSpace
.global custom_getSelectItemNo_progressive
custom_getSelectItemNo_progressive:
  stwu sp, -0x10 (sp)
  mflr r0
  stw r0, 0x14 (sp)
  
  bl getSelectItemNo__11ShopItems_cFv
  bl convert_progressive_item_id
  
  lwz r0, 0x14 (sp)
  mtlr r0
  addi sp, sp, 0x10
  blr
.close
