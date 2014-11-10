--Calculates combat info for weapons/armor. Alpha version!

--Future goal is to calculate info for body part weapons (using attack info), wounded tissue layers
--ranged weapons


unit=dfhack.gui.getSelectedUnit()
if unit==nil then
	 print ("No unit under cursor!  Aborting!")
	 return
	 end

print("Creature size (base/current): ", unit.body.size_info.size_base, unit.body.size_info.size_cur)
print("Creature strength (base): ", unit.body.physical_attrs.STRENGTH.value) --should update to use curse strengths etc.
print(" ") 

for k,v in pairs(unit.inventory) do

--print(v.mode)
--enum-item	Hauled	0
--enum-item	Weapon	1
--enum-item	Worn	2
--enum-item	InBody	3
--enum-item	Flask	4
--enum-item	WrappedAround	5
--enum-item	StuckIn	6
--enum-item	InMouth	7
--enum-item	Shouldered	8
--enum-item	SewnInto	9

vitype=df.item_type[v.item:getType()]
print(vitype)
material=dfhack.matinfo.decode(v.item)
matdata=material.material.strength
vmatname=material.material.state_name.Solid
--print(vmatname, v.item.subtype.name) --WOULD ENABLE THIS BUT BUG ON QUIVERS, OTHER ITEMS W/O SUBTYPES!

vbpart=unit.body.body_plan.body_parts[v.body_part_id]
print(vbpart.name_singular[0].value)

if vitype=="WEAPON" then
	print(vmatname, v.item.subtype.name)
	v.item:calculateWeight()
	effweight=unit.body.size_info.size_cur/100+v.item.weight*100+v.item.weight_fraction/10000
	actweight=v.item.weight*1000+v.item.weight_fraction/1000
	if v.item.subtype.flags.HAS_EDGE_ATTACK==true then
		print("shear yield, shear fracture: ", matdata.yield.SHEAR, matdata.fracture.SHEAR)
		print("Sharpness: ", v.item.sharpness)
	end
	print("NAME", "EDGE", "CONTACT", "PNTRT", "WEIGHT", "VEL", "MOMENTUM(+100%/-50%)")
		for kk,vv in pairs(v.item.subtype.attacks) do
			vvel=unit.body.size_info.size_base * unit.body.physical_attrs.STRENGTH.value * 

vv.velocity_mult/1000/effweight/1000
			vmom=vvel*actweight/1000+1
			vedge="blunt"
			vcut=""
			if vv.edged==true then
				vedge="edged" 
				vcut=100
			end
			print(vv.verb_2nd, vedge, vv.contact, vv.penetration, actweight/1000, math.floor(vvel), math.floor(vmom))
		end
	actvol=v.item:getVolume()
	print("Blunt deflect if layer weight more than:", actvol * matdata.yield.IMPACT / 100 / 500)

else
	if v.mode==1 then
		--item held in hands treated as misc weapon
		--1000 velocity mod, power math for contact and penetration
		print(vmatname, "(misc weapon)") --v.item.subtype.name quiver bug
		actvol=v.item:getVolume()
		v.item:calculateWeight()
		actweight=v.item.weight*1000+v.item.weight_fraction/1000
		effweight=unit.body.size_info.size_cur/100+v.item.weight*100+v.item.weight_fraction/10000
		misccontact=math.floor(actvol ^ 0.666)
		miscpene=math.floor((actvol*10000) ^ 0.333)
		print("NAME", "EDGE", "CONTACT", "PNTRT", "WEIGHT", "VEL", "MOMENTUM(+100%/-50%)")
		vvel=unit.body.size_info.size_base * unit.body.physical_attrs.STRENGTH.value/effweight/1000
		vmom=vvel*actweight/1000+1
		vedge="blunt"
		print("strike", vedge, misccontact, miscpene, actweight/1000, math.floor(vvel), math.floor(vmom))
		print("Blunt deflect if layer weight more than:", actvol * matdata.yield.IMPACT / 100 / 500)
		print(" ")
	end
end


if vitype=="ARMOR" or vitype=="HELM" or vitype=="GLOVES" or vitype=="SHOES" or vitype=="PANTS" then
	print(vmatname, v.item.subtype.name)
	actvol=v.item:getVolume()
	v.item:calculateWeight()
	actweight=v.item.weight*1000+v.item.weight_fraction/1000
	vbca=actvol*matdata.yield.IMPACT/100/500/10
	vbcb=actvol*(matdata.fracture.IMPACT-matdata.yield.IMPACT)/100/500/10
	vbcc=actvol*(matdata.fracture.IMPACT-matdata.yield.IMPACT)/100/500/10
	deduct=vbca/10
	if matdata.strain_at_yield.IMPACT >= 50000 or v.item.subtype.props.flags.STRUCTURAL_ELASTICITY_WOVEN_THREAD==true or 

v.item.subtype.props.flags.STRUCTURAL_ELASTICITY_CHAIN_METAL==true or v.item.subtype.props.flags.STRUCTURAL_ELASTICITY_CHAIN_ALL==true 

then
		vbcb=0
		vbcc=0
	end
	print("Full contact blunt momentum resist: ", math.floor(vbca+vbcb+vbcc))
	print("Contact 10 blunt momentum resist: ", math.floor((vbca+vbcb+vbcc)*10/actvol))
	print("Unbroken momentum deduction (full,10): ", math.floor(deduct), math.floor(deduct*10/actvol))
	print("Volume/contact area/penetration: ", actvol)	
	print("Weight: ", actweight/1000)
	vshyre=matdata.yield.SHEAR
	vshfre=matdata.fracture.SHEAR
	if v.item.subtype.props.flags.STRUCTURAL_ELASTICITY_WOVEN_THREAD==true and vmatname ~= "leather" then
		if vshyre>20000 then vshyre=20000 end
		if vshfre>30000 then vshfre=30000 end
	end
	print("shear yield, shear fracture: ", vshyre, vshfre)
end

print(" ")
end    --end of unit inventory loop


--printall(unit.body.body_plan.attacks) --wait for next DFHack version?
--print(" ")

print("BODY PART ATTACKS (some assumptions!)")
print("NAME", " ", "SIZE", "CONTACT", "PNTRT", "WEIGHT", "VEL", "MOMENTUM(+100%/-50%)")
for k,v in pairs(unit.body.body_plan.body_parts) do
	if v.flags.STANCE==true or v.flags.GRASP==true then
		--ASSUME THAT ALL GRASP/STANCE PARTS ARE COMBAT
		partsize = math.floor(unit.body.size_info.size_cur * v.relsize / unit.body.body_plan.total_relsize)
		contact = math.floor(partsize ^ 0.666)
		partweight = math.floor(partsize * 500 / 100) --bone, change to 8250 for bronze colossus etc.
		vvel = 100 * unit.body.physical_attrs.STRENGTH.value / 1000 --some assumptions
		vmom = vvel * partweight / 1000 + 1
		print(v.name_singular[0].value, partsize, contact, partsize, partweight/1000, vvel, vmom)
	end
end

print(" ")
print("BODY PART DEFENSE (some assumptions/bugs!)")
print("Volume/Contact/Thickness/Blunt_Momentum_Resistance(full contact)")

for k,v in pairs(unit.body.body_plan.body_parts) do
	if (v.flags.SMALL==false and v.flags.INTERNAL==false) or v.flags.TOTEMABLE==true or false then
		--change the final "or false" to "or true" to list all body parts!
		--(or just change the whole statement to "if true then" instead of checking the flags

		partsize = math.floor(unit.body.size_info.size_base * v.relsize / unit.body.body_plan.total_relsize)
		partthick = math.floor((partsize * 10000) ^ 0.333)
		contact = math.floor(partsize ^ 0.666)

		print(v.name_singular[0].value)

		for kk,vv in pairs(v.layers) do


			layername = vv.layer_name
			matdata=nil
			for x,y in pairs(unit.body.body_plan.materials.mat_type) do
				--Temporary kludge
				material=dfhack.matinfo.decode(y, unit.body.body_plan.materials.mat_index[x])
				if material.material.id==layername then
					matdata=material.material.strength
					break
				end
				if material.material.id=="" then		--kludge for bronze colossus
					matdata=material.material.strength
					break
				end
			end
			
			if matdata~=nil then 

			modpartfraction= vv.part_fraction

			if layername == "FAT" then
				modpartfraction = unit.counters2.stored_fat * modpartfraction / 2500 / 100
			end

			if layername == "MUSCLE" then
				--should update to consider strength bonus due to curses etc.
				modpartfraction = unit.body.physical_attrs.STRENGTH.value * modpartfraction / 1000
			end

			layervolume = math.floor(partsize * modpartfraction / v.fraction_total)
			layerthick = math.floor(partthick * modpartfraction / v.fraction_total)
			if layervolume == 0 then
				layervolume = 1
			end
			if layerthick == 0 then
				layerthick = 1
			end

			vbca=layervolume*matdata.yield.IMPACT/100/500/10
			vbcb=layervolume*(matdata.fracture.IMPACT-matdata.yield.IMPACT)/100/500/10
			vbcc=layervolume*(matdata.fracture.IMPACT-matdata.yield.IMPACT)/100/500/10
			deduct= math.floor(vbca/10)
			if matdata.strain_at_yield.IMPACT >= 50000 then
				vbcb=0
				vbcc=0
			end
			fullbmr= math.floor(vbca+vbcb+vbcc)

			print(" ",vv.layer_name, layervolume, contact, layerthick, fullbmr)
			
			else
				--temporary material kludge until I get tissue access
				print(" ",vv.layer_name,"ERROR-material")
			end
		end
	end
end

