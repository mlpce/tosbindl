  xdef _do_lc_aes_trap,_do_lc_vdi_trap,_do_lc_vq_gdos_trap
  section code

_do_lc_vdi_trap:
  move.l 4(sp),d1 # VDI parameter block address
  move.l d2,-(sp)
  move.l a2,-(sp)
  moveq #115,d0
  trap #2
  move.l (sp)+,a2
  move.l (sp)+,d2
  rts

_do_lc_aes_trap:
  move.l 4(sp),d1 # AES parameter block address
  move.l d2,-(sp)
  move.l a2,-(sp)
  move.w #200,d0
  trap #2
  move.l (sp)+,a2
  move.l (sp)+,d2
  rts

_do_lc_vq_gdos_trap:
  move.l d2,-(sp)
  move.l a2,-(sp)
  moveq #-2,d0
  trap #2
  cmp.w #-2,d0
  sne d0
  ext.w d0 # non-zero if gdos is present
  move.l (sp)+,a2
  move.l (sp)+,d2
  rts

  end
