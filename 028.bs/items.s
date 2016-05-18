	include "includes.i"

	xdef SetupItemSpriteData
	xdef ScrollItemSprites
	xdef RenderItemSprite
	xdef ResetItems
	xdef EnableItemSprites
	xdef DetectItemCollisions
	xdef InitialiseItems
	xdef SwitchItemSpriteBuffers
	xdef PrepareItemSpriteData
	xdef VerticalScrollBees
	xdef DetectBeeCollisions


DeleteItemSprite:
	move.w	#0,ITEM_SPRITE(a1)
	move.w	#0,ITEM_X(a1)
	move.w	#0,ITEM_Y_OFFSET(a1)
	move.w	ITEM_Y(a1),d2
	rts


VerticalScrollBees:
	lea	item25,a1
	move.w	#ITEM_NUM_BEES-1,d6
.loop:
	cmp.w	#0,ITEM_SPRITE(a1)
	beq	.done
	move.w	ITEM_Y(a1),d4
	lsl.w	#ITEM_SPRITE_SPACING_SHIFT_CONVERT,d4
	add.w	#ITEM_SPRITE_VSTART,d4
	lsl.w	#ITEM_Y_OFFSET_SHIFT_CONVERT,d4
	move.w	ITEM_Y_OFFSET(a1),d0
	add.w	d0,d4	
	cmp.w	#1,beeMovingDown
	bne	.up
.down:	
	add.w	#1,d0
	bra	.c1
.up:
	sub.w	#1,d0
.c1:
	move.w	d0,ITEM_Y_OFFSET(a1)
	cmp.w	#(ITEM_SPRITE_VSTART+(16*5))<<ITEM_Y_OFFSET_SHIFT_CONVERT,d4
	bge	.beeAtBottom
	cmp.w	#0,d0
	ble	.beeAtTop
	bra	.done
.beeAtTop:
	move.w	#1,beeMovingDown
	bra	.done	
.beeAtBottom:
	move.w	#0,beeMovingDown
.done:
	add.l	#ITEM_STRUCT_SIZE,a1
	dbra	d6,.loop
	rts


ScrollItemSprites:
	move.w	#ITEM_NUM_SLOTS-1,d1
	lea	item1,a1
.loop:
	move.l 	foregroundScrollPixels,d0
	cmp.w	#0,ITEM_SPRITE(a1)
	beq	.skip
	sub.w	d0,ITEM_X(a1)	
	cmp.w	#160<<FOREGROUND_SCROLL_SHIFT_CONVERT,ITEM_X(a1)
	bgt	.skip
	move.w	#0,ITEM_SPRITE(a1)
	move.w	#0,ITEM_X(a1)
	move.w	#0,ITEM_Y_OFFSET(a1)
	move.w	ITEM_Y(a1),d2
.skip:
	add.l	#ITEM_STRUCT_SIZE,a1		; multiply by 16 (item control structure size)
	dbra	d1,.loop
	rts


DetectItemCollisions:
	move.w	#ITEM_NUM_SLOTS-ITEM_NUM_BEES-1,d1
	lea	item1,a1
.loop:
	cmp.w	#0,ITEM_SPRITE_ENABLED(a1)
	beq	.skip
	cmp.w	#0,ITEM_SPRITE(a1)	
	beq	.skip
	move.w	spriteX,d2
	move.w	ITEM_X(a1),d3
	move.w	ITEM_Y(a1),d4
	lsl.w	#ITEM_SPRITE_SPACING_SHIFT_CONVERT,d4
	add.w	#ITEM_SPRITE_VSTART,d4
	lsr.w	#FOREGROUND_SCROLL_SHIFT_CONVERT,d3 ; convert to pixels
	add.w	#ITEM_SPRITE_HORIZONTAL_START_PIXELS,d3
	cmp.w	d2,d3
	bne	.skip
	move.w	spriteY,d2
	add.w	#ITEM_SPRITE_Y_COLLISION_OFFSET,d2	
	cmp.w	d2,d4
	bne	.skip	
	cmpi.w	#ITEM_SPRITE_ARROW_INDEX,ITEM_SPRITE(a1)		
	bge	.arrowCollision
.coinCollision:	
	bsr	DeleteItemSprite
	lea	coinCounterText,a0
	jsr	IncrementCounter
	bsr	RenderCoinScore
	PlaySound Chaching
	rts
	
.arrowCollision:
	bsr	DeleteItemSprite	
	jsr	SpriteEnableAuto
	rts
	
.skip:
	add.l	#ITEM_STRUCT_SIZE,a1
	dbra	d1,.loop	
	rts


DetectBeeCollisions:
	lea	item25,a1
	move.w	#ITEM_NUM_BEES-1,d7
.loop:
	cmp.w	#0,ITEM_SPRITE_ENABLED(a1)
	beq	.skip
	cmp.w	#0,ITEM_SPRITE(a1)	
	beq	.skip
	move.w	spriteX,d2
	move.w	ITEM_X(a1),d3
	move.w	ITEM_Y(a1),d4
	lsl.w	#ITEM_SPRITE_SPACING_SHIFT_CONVERT,d4
	add.w	#ITEM_SPRITE_VSTART,d4
	move.w	ITEM_Y_OFFSET(a1),d5
	lsr.l	#ITEM_Y_OFFSET_SHIFT_CONVERT,d5	
	add.w	d5,d4
	lsr.w	#FOREGROUND_SCROLL_SHIFT_CONVERT,d3 ; convert to pixels
	add.w	#ITEM_SPRITE_HORIZONTAL_START_PIXELS,d3
	move.w	spriteY,d5
	;; d2 = playerX pixels
	;; d3 = beeX pixels
	;; d4 = beeY pixels
	;; d5 = player Y pixels
	move.w	d3,d6
	add.w	#BEE_COLLIDE_SIZE,d6
	cmp.w	d2,d6 		; r1.x >= r2.x+w
	ble	.skip

	move.w	d2,d6
	add.w	#BEE_COLLIDE_SIZE,d6
	cmp.w	d3,d6		; r1.x+w <= r2.x
	ble	.skip

	move.w	d4,d6
	add.w	#BEE_COLLIDE_SIZE,d6
	cmp.w	d5,d6		; r1.y >= r2.y+h
	ble	.skip

	move.w	d5,d6
	add.w	#BEE_COLLIDE_SIZE,d6
	cmp.w	d4,d6		; r1.y+h < r2.y
	ble	.skip

	bsr	DeleteItemSprite
	jmp	BigBang
.skip:
	add.w	#ITEM_STRUCT_SIZE,a1
	dbra	d7,.loop	
	rts	


RenderCoinScore:
	lea	coinCounterText,a1	
	move.w	#31,d0
	jsr	RenderCounter	
	rts


InitialiseItems:
	move.l	#"0000",coinCounterText
	bsr	RenderCoinScore
	
ResetItems:
	lea	item1,a1	
	move.w  #ITEM_NUM_SLOTS-1,d1
.loop1:
	move.w	#0,ITEM_SPRITE(a1)
	move.w	#0,ITEM_X(a1)
	move.w	ITEM_Y(a1),d2	
	add.l	#ITEM_STRUCT_SIZE,a1		; multiply by 16 (item control structure size)	
	dbra	d1,.loop1
	move.l	#0,itemSpritesEnabled
	bsr	PrepareItemSpriteData
	rts


SwitchItemSpriteBuffers:
	move.w	spriteX,spriteLagX	
	move.w	#ITEM_NUM_SLOTS-1,d1
	move.w	d1,d0
	lea	item1,a1
.loop:
	adda.l	#ITEM_STRUCT_SIZE,a1		
	dbra	d1,.loop
	rts


PrepareItemSpriteData:
	cmp.l	#0,itemSpritesEnabled
	bne	.enableSprites
	move.l	#deadSprite,sprite2Pointer
	move.l	#deadSprite,sprite3Pointer
	move.l	#deadSprite,sprite4Pointer
	move.l	#deadSprite,sprite5Pointer	
	rts
	
.enableSprites:	
	move.l	#ITEM_NUM_SLOTS-1,d0	
.loop:
	bsr 	_SetupItemSpriteData
	dbra	d0,.loop
	rts


SetupItemSpriteData:
	move.l	sprite2Pointer,SPR2PTH(a6)
	move.l	sprite3Pointer,SPR3PTH(a6)
	move.l	sprite4Pointer,SPR4PTH(a6)
	move.l	sprite5Pointer,SPR5PTH(a6)	
	cmp.w	#0,spriteBufferIndex
	beq	.zero
	move.w	#0,spriteBufferIndex
	rts
.zero:
	move.w	#ITEM_SPRITE_BYTES,spriteBufferIndex
	rts
	

_SetupItemSpriteData:
	;; d0.l - item slot	
	move.l	d0,-(sp)
	move.l	d0,d4 					; save item slot
	
	lsl.w	#ITEM_STRUCT_MULU_SHIFT,d0		; multiply by 16 (item control structure size)
	lea	item1,a1
	add.l	d0,a1

	cmpi.w	#0,ITEM_SPRITE_ENABLED(a1)
	beq	.spriteIsNotEnabled
	
	move.w	ITEM_Y(a1),d2	
	move.l	ITEM_SPRITE_ADDRESS(a1),a0
	
	cmp.w	#(ITEM_NUM_COIN_ANIMS-1)<<3,ITEM_INDEX(a1)
	ble	.dontResetIndex
	move.w	#0,ITEM_INDEX(a1)
.dontResetIndex:
	cmp.l	#deadSprite,a0
	bne	.setupSprite
	bra	.c1
.setupSprite:

	move.w	ITEM_INDEX(a1),d0
	
	lsr.l	#3,d0	
	mulu.w	#ITEM_SPRITE_BYTES*2,d0
	add.w	spriteBufferIndex,d0
	adda.w	d0,a0

	lsl.w	#ITEM_SPRITE_VERTICAL_BYTES_SHIFT_CONVERT,d2
	adda.w	d2,a0

	move.w	ITEM_X(a1),d0
	lsr.w	#FOREGROUND_SCROLL_SHIFT_CONVERT,d0 ; convert to pixels

	add.w	#ITEM_SPRITE_HORIZONTAL_START_PIXELS,d0
	move.w	d0,d1
	andi	#1,d1
	move.b	d1,3(a0)	;spriteControl
	lsr.l	#1,d0
	move.b	d0,1(a0)	;spriteHStart

	move.w	ITEM_Y_OFFSET(a1),d1
	cmp.w	#0,d1
	;; beq	.noYOffset

	move.w	ITEM_Y(a1),d0
	lsl.w	#ITEM_SPRITE_SPACING_SHIFT_CONVERT,d0
	lsr.w	#ITEM_Y_OFFSET_SHIFT_CONVERT,d1
	add.w   d1,d0
	add.w	#ITEM_SPRITE_VSTART,d0
	move.b	d0,(a0) ; spriteVStart
	add.w	#ITEM_SPRITE_HEIGHT,d0
	move.b	d0,2(a0) ; spriteVStart
	
.noYOffset:	
.c1:

	sub.l	d2,a0	;#1*ITEM_SPRITE_VERTICAL_BYTES,a0
	cmp.b	#ITEM_SPRITE_BEE_INDEX,d4
	bge	.beeSprite	
	cmp.b	#ITEM_SPRITE_ARROW_INDEX,d4
	bge	.arrowSprite
	cmp.b	#ITEM_SPRITE_COINB_INDEX,d4
	bge	.coinBSprite
.coinASprite:
	move.l	a0,sprite2Pointer
	bra	.done
.coinBSprite:
	move.l	a0,sprite3Pointer
	bra	.done	
.arrowSprite:
	move.l	a0,sprite4Pointer
	cmp.w	#0,ITEM_X(a1)
	beq	.done
	bsr	InstallArrowPalette
	bra	.done
.beeSprite:
	move.l	a0,sprite5Pointer
	cmp.w	#0,ITEM_X(a1)
	beq	.dontAnimate
	bsr	InstallBeePalette
	bra	.dontAnimate

.dontAnimate:
	cmp.w	#1,beeMovingDown
	beq	.setBeeDown
.setBeeUp:
	move.w	#1<<3,ITEM_INDEX(a1)
	bra	.spriteIsNotEnabled	
.setBeeDown:
	move.w	#0,ITEM_INDEX(a1)	
	bra	.spriteIsNotEnabled
.done:	
	add.w	#1,ITEM_INDEX(a1)
.spriteIsNotEnabled:
	move.l	(sp)+,d0
	rts


RenderItemSprite:
	;; d2.l - y tile index ?
	movem.l	d2-d3,-(sp)

	move.l	foregroundScrollX,d1
	lsr.w	#FOREGROUND_SCROLL_SHIFT_CONVERT,d1 ; convert to pixels
	andi.w	#$f,d1
	cmp.b	#$f,d1		; only add sprite after tile has scrolled in
	bne	.dontAddSprite
	move.l	a2,a3
	add.l	itemsMapOffset,a3
	cmpi.w	#0,(a3)
	beq	.dontAddSprite

.getSpriteSlot:
	move.w	(a3),d0 		; sprite slot
	sub.w	#1,d0
	
	move.w	d0,d1
	cmp.w	#ITEM_NUM_SLOTS,d0
	bge	.dontAddSprite
	lsl.w	#ITEM_STRUCT_MULU_SHIFT,d0		; multiply by 16 (item control structure size)
	lea	item1,a1
	adda.w	d0,a1	
	
	move.w	#336<<FOREGROUND_SCROLL_SHIFT_CONVERT,ITEM_X(a1)
	sub.l	#1,d2
	move.w	d2,ITEM_Y(a1)
	move.w	#0,ITEM_Y_OFFSET(a1)
	
	add.w	#1,d1
	move.w	d1,ITEM_SPRITE(a1)

.dontAddSprite:
	movem.l	(sp)+,d2-d3
	rts


EnableItemSprites:
	move.l	#1,itemSpritesEnabled
	rts


InstallBeePalette:
	include "out/sprite_bee-0-palette.s"
	rts


InstallArrowPalette:
	include "out/sprite_arrow-1-palette.s"
	rts


itemSpritesEnabled:
	dc.l	0
spriteBufferIndex:
	dc.l	0	
sprite2Pointer:
	dc.l	0
sprite3Pointer:
	dc.l	0
sprite4Pointer:
	dc.l	0
sprite5Pointer:
	dc.l	0
beeMovingDown:
	dc.w	1
	
	;; coinA
	ItemControl item1,spriteCoinA1,1
	ItemControl item2,spriteCoinA1,1
	ItemControl item3,spriteCoinA1,1
	ItemControl item4,spriteCoinA1,1
	ItemControl item5,spriteCoinA1,1
	ItemControl item6,spriteCoinA1,1
	ItemControl item7,spriteCoinA1,0
	ItemControl item8,spriteCoinA1,0

	;; coinB
	ItemControl item9,spriteCoinB1,1
	ItemControl item10,spriteCoinB1,1
	ItemControl item11,spriteCoinB1,1
	ItemControl item12,spriteCoinB1,1
	ItemControl item13,spriteCoinB1,1
	ItemControl item14,spriteCoinB1,1
	ItemControl item15,spriteCoinB1,0
	ItemControl item16,spriteCoinB1,0

	;; arrow1
	ItemControl item17,spriteArrow1,1
	ItemControl item18,spriteArrow1,1
	ItemControl item19,spriteArrow1,1
	ItemControl item20,spriteArrow1,1
	ItemControl item21,spriteArrow1,1
	ItemControl item22,spriteArrow1,1
	ItemControl item23,spriteArrow1,0
	ItemControl item24,spriteArrow1,0

	;; bee
	ItemControl item25,spriteBee1,1
	ItemControl item26,spriteBee1,1
	if 0
	ItemControl item27,spriteArrow1,1
	ItemControl item28,spriteArrow1,1
	endif

	ItemSprite spriteCoinA1,sprite_coin-0.bin
	ItemSprite spriteCoinA2,sprite_coin-0.bin
	ItemSprite spriteCoinA3,sprite_coin-1.bin
	ItemSprite spriteCoinA4,sprite_coin-2.bin
	ItemSprite spriteCoinA5,sprite_coin-3.bin
	ItemSprite spriteCoinA6,sprite_coin-2.bin
	ItemSprite spriteCoinA7,sprite_coin-1.bin
	ItemSprite spriteCoinA8,sprite_coin-1.bin	

	ItemSprite spriteCoinB1,sprite_coin-0.bin
	ItemSprite spriteCoinB2,sprite_coin-0.bin
	ItemSprite spriteCoinB3,sprite_coin-1.bin
	ItemSprite spriteCoinB4,sprite_coin-2.bin
	ItemSprite spriteCoinB5,sprite_coin-3.bin
	ItemSprite spriteCoinB6,sprite_coin-2.bin
	ItemSprite spriteCoinB7,sprite_coin-1.bin
	ItemSprite spriteCoinB8,sprite_coin-1.bin		
	
	ItemSprite spriteArrow1,sprite_arrow-0.bin
	ItemSprite spriteArrow2,sprite_arrow-0.bin
	ItemSprite spriteArrow3,sprite_arrow-1.bin
	ItemSprite spriteArrow4,sprite_arrow-2.bin
	ItemSprite spriteArrow5,sprite_arrow-3.bin
	ItemSprite spriteArrow6,sprite_arrow-2.bin
	ItemSprite spriteArrow7,sprite_arrow-1.bin
	ItemSprite spriteArrow8,sprite_arrow-1.bin

	ItemSprite spriteBee1,sprite_bee-1.bin
	ItemSprite spriteBee2,sprite_bee-0.bin
	ItemSprite spriteBee3,sprite_bee-1.bin
	ItemSprite spriteBee4,sprite_bee-0.bin
	ItemSprite spriteBee5,sprite_bee-1.bin
	ItemSprite spriteBee6,sprite_bee-0.bin
	ItemSprite spriteBee7,sprite_bee-1.bin
	ItemSprite spriteBee8,sprite_bee-0.bin		


nextSpriteSlot:
	dc.w	0


coinCounterText:
	dc.b	"0000"
	dc.b	0
	align	4