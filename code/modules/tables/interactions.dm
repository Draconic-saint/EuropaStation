
/obj/structure/table/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(istype(mover,/obj/item/projectile))
		return (check_cover(mover,target))
	if (flipped == 1)
		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	if(locate(/obj/structure/table) in get_turf(mover))
		return 1
	return 0

//checks if projectile 'P' from turf 'from' can hit whatever is behind the table. Returns 1 if it can, 0 if bullet stops.
/obj/structure/table/proc/check_cover(obj/item/projectile/P, turf/from)
	var/turf/cover
	if(flipped==1)
		cover = get_turf(src)
	else if(flipped==0)
		cover = get_step(loc, get_dir(from, loc))
	if(!cover)
		return 1
	if (get_dist(P.starting, loc) <= 1) //Tables won't help you if people are THIS close
		return 1
	if (get_turf(P.original) == cover)
		var/chance = 20
		if (ismob(P.original))
			var/mob/M = P.original
			if (M.lying)
				chance += 20				//Lying down lets you catch less bullets
		if(flipped==1)
			if(get_dir(loc, from) == dir)	//Flipped tables catch mroe bullets
				chance += 20
			else
				return 1					//But only from one side
		if(prob(chance))
			health -= P.damage/2
			if (health > 0)
				visible_message("<span class='warning'>[P] hits \the [src]!</span>")
				return 0
			else
				visible_message("<span class='warning'>[src] breaks down!</span>")
				break_to_parts()
				return 1
	return 1

/obj/structure/table/CheckExit(atom/movable/O as mob|obj, target as turf)
	if(istype(O) && O.checkpass(PASSTABLE))
		return 1
	if (flipped==1)
		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 1


/obj/structure/table/MouseDrop_T(obj/O as obj, mob/user as mob)

	if ((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return ..()
	if(isrobot(user))
		return
	user.drop_item()
	if (O.loc != src.loc)
		step(O, get_dir(O, src))
	return


/obj/structure/table/attackby(obj/item/W as obj, mob/user as mob)
	if (!W) return

	// Handle harm intent grabbing/tabling.
	if(istype(W, /obj/item/weapon/grab) && get_dist(src,user)<2)
		var/obj/item/weapon/grab/G = W
		if (istype(G.affecting, /mob/living))
			var/mob/living/M = G.affecting
			var/obj/occupied = turf_is_crowded()
			if(occupied)
				user << "<span class='danger'>There's \a [occupied] in the way.</span>"
				return
			if (G.state < 2)
				if(user.a_intent == I_HURT)
					if (prob(15))	M.Weaken(5)
					M.apply_damage(8,def_zone = BP_HEAD)
					visible_message("<span class='danger'>[G.assailant] slams [G.affecting]'s face against \the [src]!</span>")
					if(material)
						playsound(loc, material.tableslam_noise, 50, 1)
					else
						playsound(loc, 'sound/weapons/tablehit1.ogg', 50, 1)
					var/list/L = take_damage(rand(1,5))
					// Shards. Extra damage, plus potentially the fact YOU LITERALLY HAVE A PIECE OF GLASS/METAL/WHATEVER IN YOUR FACE
					for(var/obj/item/weapon/material/shard/S in L)
						if(prob(50))
							M.visible_message("<span class='danger'>\The [S] slices [M]'s face messily!</span>",
							                   "<span class='danger'>\The [S] slices your face messily!</span>")
							M.apply_damage(10, def_zone = BP_HEAD)
							if(prob(2))
								M.embed(S, def_zone = BP_HEAD)
				else
					user << "<span class='danger'>You need a better grip to do that!</span>"
					return
			else
				G.affecting.Weaken(5)
				G.affecting.forceMove(src.loc)
				visible_message("<span class='danger'>[G.assailant] puts [G.affecting] on \the [src].</span>")
			qdel(W)
			return

	// Handle dismantling or placing things on the table from here on.
	if(isrobot(user))
		return

	if(W.loc != user) // This should stop mounted modules ending up outside the module.
		return

	if(istype(W, /obj/item/weapon/melee/energy/blade))
		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, src.loc)
		spark_system.start()
		playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
		playsound(src.loc, "sparks", 50, 1)
		user.visible_message("<span class='danger'>\The [src] was sliced apart by [user]!</span>")
		break_to_parts()
		return

	if(user.a_intent == I_HURT)
		return attack_generic(user, W.force)

	if(can_plate && !material)
		user << "<span class='warning'>There's nothing to put \the [W] on! Try adding plating to \the [src] first.</span>"
		return

	user.drop_item(src.loc)
	return

/obj/structure/table/attack_tk() // no telehulk sorry
	return

/obj/structure/table/attack_generic(var/mob/user, var/damage, var/attack_verb, var/wallbreaker)
	if(wallbreaker)
		break_to_parts()
		return
	var/dam_threshhold = material.integrity
	if(reinforced)
		dam_threshhold = ceil(max(dam_threshhold,reinforced.integrity)/2)
	dam_threshhold *= 0.75
	var/dam_prob = min(100,material.hardness*1.2)
	if(dam_prob < 100 && damage > (dam_threshhold/10))
		playsound(src, 'sound/effects/grillehit.ogg', 80, 1)
		if(!prob(dam_prob))
			visible_message("<span class='danger'>\The [user] attacks \the [src] and it [material.destruction_desc]!</span>")
			break_to_parts()
		else
			visible_message("<span class='danger'>\The [user] attacks \the [src]!</span>")
	else
		visible_message("<span class='danger'>\The [user] attacks \the [src], but it bounces off!</span>")
	return
