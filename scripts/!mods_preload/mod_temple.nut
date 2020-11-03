::mods_registerMod("mod_temple", 1, "Talent booster");

::mods_hookNewObject("items/misc/ghoul_brain_item", function ( sub )
{
  sub.create = function()
  {
		this.m.ID = "misc.ghoul_brain";
		this.m.Name = "Nachzehrer Brain";
		this.m.Description = "The greasy brain of a slain Nachzehrer. Whatddwdwdw could you possibly want with this?";
		this.m.Icon = "misc/inventory_ghoul_brain.png";
		this.m.SlotType = this.Const.ItemSlot.None;
		this.m.ItemType = this.Const.Items.ItemType.Misc | this.Const.Items.ItemType.Crafting | this.Const.Items.ItemType.Usable;
		this.m.IsAllowedInBag = false;
		this.m.IsUsable = true;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 200;
  };

  sub.onUse = function(_actor, _item = null )
  {
    if(_actor.getLevel() - _actor.getLevelUps() > 1)
    {
      this.logInfo("Failed!");
      return false;
    }

    local count = 0;

    local talents = _actor.getTalents();
    for(local a = 0 ; a < talents.len() ; a++)
    {
      if (talents[a] > 0)
      {
        while(talents[a] < 3)
        {
          //Try and add a permanent injury for each talents gained.
          _actor.addInjury(this.Const.Injury.Permanent);
          talents[a] = talents[a] + 1;
          count++;
        }
      }
    }

    if(0 == count)
    {
      return false;
    }

    //reset talents
    _actor.fillAttributeLevelUpValues(this.Const.XP.MaxLevelWithPerkpoints - 1);

    return true;
  };
});


::mods_hookNewObject("ui/screens/world/modules/world_town_screen/town_temple_dialog_module", function ( sub )
{
	sub.onTreatInjury = function( _data )
	{
		local entityID = _data[0];
		local injuryID = _data[1];
		local entity = this.Tactical.getEntityByID(entityID);
		local injury = entity.getSkills().getSkillByID(injuryID);
		injury.setTreated(true);
		this.World.Assets.addMoney(-injury.getPrice());

    local permaInj = entity.getSkills().getAllSkillsOfType( this.Const.SkillType.PermanentInjury );

    if(permaInj.len() > 0)
    {
          this.logInfo("cost: " + entity.m.HiringCost);
      if(10 < entity.m.HiringCost) //recycle hiring cost as injury counter.
      {
        entity.m.HiringCost = 0;
      }
          this.logInfo("cost: " + entity.m.HiringCost);
      entity.m.HiringCost = entity.m.HiringCost + 1;
          this.logInfo("cost: " + entity.m.HiringCost);

      if(10 == entity.m.HiringCost)
      {
        entity.getSkills().remove(permaInj[0]);
        entity.m.HiringCost = 0;
      }
          this.logInfo("cost: " + entity.m.HiringCost);
    }

		entity.updateInjuryVisuals();



		local injuries = [];
		local allInjuries = entity.getSkills().query(this.Const.SkillType.TemporaryInjury);

		foreach( inj in allInjuries )
		{
			if (!inj.isTreated())
			{
				injuries.push({
					id = inj.getID(),
					icon = inj.getIconColored(),
					name = inj.getNameOnly(),
					price = inj.getPrice()
				});
			}
		}

		local background = entity.getBackground();
		local e = {
			ID = entity.getID(),
			Name = entity.getName(),
			ImagePath = entity.getImagePath(),
			ImageOffsetX = entity.getImageOffsetX(),
			ImageOffsetY = entity.getImageOffsetY(),
			BackgroundImagePath = background.getIconColored(),
			BackgroundText = background.getDescription(),
			Injuries = injuries
		};
		local r = {
			Entity = e,
			Assets = this.m.Parent.queryAssetsInformation()
		};
		this.World.Statistics.getFlags().increment("InjuriesTreatedAtTemple");
		this.updateAchievement("PatchedUp", 1, 1);
		return r;
	};
});
