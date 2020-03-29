################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub data_convert {
  my $set_url = shift;
  my $file;
  foreach my $url (keys %set::convert_url){
    if($set_url =~ s#^${url}data/(.*?).html#$1#){
      $file = "$set::convert_url{$url}data/${set_url}.cgi";
      last;
    }
  }
  my %pc;
  open my $IN, '<', $file or error '旧ゆとシートのデータが開けませんでした:'.$file;
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
  
  $pc{'playerName'} = $::pc{'playerName'};
  $pc{'characterName'} = $pc{'name'};
  $pc{'aka'} = $pc{'codename'};
  $pc{'words'} = $pc{'word'};
  
  $pc{'tags'} = $pc{'tag'};
  
  $pc{'age'}      = $pc{'prof_age'};
  $pc{'gender'}   = $pc{'prof_sex'};
  $pc{'height'}   = $pc{'prof_height'};
  $pc{'weight'}   = $pc{'prof_weight'};
  $pc{'sign'}     = $pc{'prof_sign'};
  $pc{'blood'}    = $pc{'prof_blood'};
  
  $pc{'sttWorks'}      = $pc{'stt_works'};
  $pc{'sttWorks'} =~ s/spirit/mind/;
  $pc{'sttGrowBody'}   = $pc{'stt_grow_body'};
  $pc{'sttGrowSense'}  = $pc{'stt_grow_sense'};
  $pc{'sttGrowMind'}   = $pc{'stt_grow_spirit'};
  $pc{'sttGrowSocial'} = $pc{'stt_grow_social'};
  $pc{'sttAddBody'}   = $pc{'stt_add_body'};
  $pc{'sttAddSense'}  = $pc{'stt_add_sense'};
  $pc{'sttAddMind'}   = $pc{'stt_add_spirit'};
  $pc{'sttAddSocial'} = $pc{'stt_add_social'};
  
  $pc{'maxHpAdd'} = $pc{'sub_hp_add'};
  $pc{'stockAdd'} = $pc{'sub_provide_add'};
  $pc{'initiativeAdd'} = $pc{'sub_speed_add'};
  $pc{'moveAdd'} = $pc{'sub_move_add'};
  
  $pc{'skillMelee'}     = $pc{'skill_fight_lv'};
  $pc{'skillRanged'}    = $pc{'skill_shoot_lv'};
  $pc{'skillRC'}        = $pc{'skill_RC_lv'};
  $pc{'skillNegotiate'} = $pc{'skill_nego_lv'};
  $pc{'skillDodge'}     = $pc{'skill_dodge_lv'};
  $pc{'skillPercept'}   = $pc{'skill_perce_lv'};
  $pc{'skillWill'}      = $pc{'skill_will_lv'};
  $pc{'skillProcure'}   = $pc{'skill_raise_lv'};
  
  $pc{'skillNum'} = $pc{'count_skill'};
  foreach my $num (1 .. $pc{'skillNum'}){
    $pc{"skillRide${num}Name"} = '運転:'.$pc{"skill_drive${num}_name"}; $pc{"skillRide${num}"} = $pc{"skill_drive${num}_lv"};
    $pc{"skillArt${num}Name" } = '芸術:'.$pc{"skill_art${num}_name"  }; $pc{"skillArt${num}" } = $pc{"skill_art${num}_lv"  };
    $pc{"skillKnow${num}Name"} = '知識:'.$pc{"skill_know${num}_name" }; $pc{"skillKnow${num}"} = $pc{"skill_know${num}_lv" };
    $pc{"skillInfo${num}Name"} = '情報:'.$pc{"skill_info${num}_name" }; $pc{"skillInfo${num}"} = $pc{"skill_info${num}_lv" };
  }
  
  $pc{'lifepathOrigin'}     = $pc{'lifepath_birth'};
  $pc{'lifepathOriginNote'} = $pc{'lifepath_birth_note'};
  $pc{'lifepathExperience'} = $pc{'lifepath_exp'};
  $pc{'lifepathExperienceNote'} = $pc{'lifepath_exp_note'};
  $pc{'lifepathEncounter'}      = $pc{'lifepath_meet'};
  $pc{'lifepathEncounterNote'}  = $pc{'lifepath_meet_note'};
  $pc{'lifepathAwaken'}          = $pc{'lifepath_awaken'};
  $pc{'lifepathAwakenEncroach'}  = $pc{'lifepath_awaken_invade'};
  $pc{'lifepathAwakenNote'}      = $pc{'lifepath_awaken_note'};
  $pc{'lifepathImpulse'}         = $pc{'lifepath_urge'};
  $pc{'lifepathImpulseEncroach'} = $pc{'lifepath_urge_invade'};
  $pc{'lifepathImpulseNote'}     = $pc{'lifepath_urge_note'};
  $pc{'lifepathOtherEncroach'} = $pc{'lifepath_other_invade'};
  $pc{'lifepathOtherNote'}     = $pc{'lifepath_other_note'};
  
  foreach my $num (1 .. 7) {
    $pc{"lois${num}Relation"}     = $pc{"lois${num}_relation"};
    $pc{"lois${num}Name"}         = $pc{"lois${num}_name"};
    $pc{"lois${num}EmoPosiCheck"} = $pc{"lois${num}_positive"};
    $pc{"lois${num}EmoNegaCheck"} = $pc{"lois${num}_negative"};
    $pc{"lois${num}Note"}         = $pc{"lois${num}_note"};
    $pc{"lois${num}State"}        = $pc{"lois${num}_titus"} ? 'タイタス' : '';
  }
  foreach my $num (1 .. 3) {
    $pc{"memory${num}Relation"} = $pc{"memory${num}_relation"};
    $pc{"memory${num}Name"}     = $pc{"memory${num}_name"};
    $pc{"memory${num}Emo"}      = $pc{"memory${num}_emotion"};
    $pc{"memory${num}Note"}     = $pc{"memory${num}_note"};
    $pc{"memory${num}State"}    = $pc{"memory${num}_titus"} ? 'タイタス' : '';
  }
  
  $pc{'effectNum'} = $pc{'count_effect'}+2;
  my $i = 1;
  foreach my $num (3 .. $pc{'effectNum'}) {
    $pc{"effect${num}Name"}     = $pc{"effect${i}_name"};
    $pc{"effect${num}Lv"}       = $pc{"effect${i}_lv"};
    $pc{"effect${num}Timing"}   = $pc{"effect${i}_timing"};
    $pc{"effect${num}Skill"}    = $pc{"effect${i}_skill"};
    $pc{"effect${num}Dfclty"}   = $pc{"effect${i}_diffi"};
    $pc{"effect${num}Target"}   = $pc{"effect${i}_target"};
    $pc{"effect${num}Range"}    = $pc{"effect${i}_range"};
    $pc{"effect${num}Encroach"} = $pc{"effect${i}_point"};
    $pc{"effect${num}Restrict"} = $pc{"effect${i}_limit"};
    $pc{"effect${num}Note"}     = $pc{"effect${i}_note"};
    $i++;
  }
  my $i = 1;
  foreach my $num ($pc{'effectNum'}+1 .. $pc{'effectNum'}+$pc{'count_effect_ez'}) {
    $pc{"effect${num}Type"}     = 'easy';
    $pc{"effect${num}Name"}     = $pc{"effect_ez${i}_name"};
    $pc{"effect${num}Lv"}       = $pc{"effect_ez${i}_lv"};
    $pc{"effect${num}Timing"}   = $pc{"effect_ez${i}_timing"};
    $pc{"effect${num}Skill"}    = $pc{"effect_ez${i}_skill"};
    $pc{"effect${num}Dfclty"}   = $pc{"effect_ez${i}_diffi"};
    $pc{"effect${num}Target"}   = $pc{"effect_ez${i}_target"};
    $pc{"effect${num}Range"}    = $pc{"effect_ez${i}_range"};
    $pc{"effect${num}Encroach"} = $pc{"effect_ez${i}_point"};
    $pc{"effect${num}Restrict"} = $pc{"effect_ez${i}_limit"};
    $pc{"effect${num}Note"}     = $pc{"effect_ez${i}_note"};
    $i++;
  }
  $pc{'effectNum'} += $pc{'count_effect_ez'};
  
  $pc{'comboNum'} = $pc{'count_combo'};
  foreach my $num (1 .. $pc{'comboNum'}) {
    $pc{"combo${num}Name"}     = $pc{"combo${num}_name"};
    $pc{"combo${num}Combo"}    = $pc{"combo${num}_set"};
    $pc{"combo${num}Timing"}   = $pc{"combo${num}_timing"};
    $pc{"combo${num}Skill"}    = $pc{"combo${num}_skill"};
    $pc{"combo${num}Dfclty"}   = $pc{"combo${num}_diffi"};
    $pc{"combo${num}Target"}   = $pc{"combo${num}_target"};
    $pc{"combo${num}Range"}    = $pc{"combo${num}_range"};
    $pc{"combo${num}Encroach"} = $pc{"combo${num}_point"};
    $pc{"combo${num}Restrict"} = $pc{"combo${num}_limit"};
    $pc{"combo${num}Note"}     = $pc{"combo${num}_note"};
    $pc{"combo${num}Condition1"}  = '100%未満';
    $pc{"combo${num}Dice1"}       = $pc{"combo${num}_under_dice"};
    $pc{"combo${num}Crit1"}       = $pc{"combo${num}_under_crit"};
    $pc{"combo${num}Atk1"}        = $pc{"combo${num}_under_power"};
    $pc{"combo${num}Condition2"}  = '100%以上';
    $pc{"combo${num}Dice2"}       = $pc{"combo${num}_over_dice"};
    $pc{"combo${num}Crit2"}       = $pc{"combo${num}_over_crit"};
    $pc{"combo${num}Atk2"}        = $pc{"combo${num}_over_power"};
  }
  
  $pc{'weaponNum'} = $pc{'count_weapon'};
  foreach my $num (1 .. $pc{'weaponNum'}) {
    $pc{"weapon${num}Name"}  = $pc{"weapon${num}_name"};
    $pc{"weapon${num}Stock"} = $pc{"weapon${num}_point"};
    $pc{"weapon${num}Exp"}   = $pc{"weapon${num}_exp"};
    $pc{"weapon${num}Type"}  = $pc{"weapon${num}_type"};
    $pc{"weapon${num}Skill"} = $pc{"weapon${num}_skill"};
    $pc{"weapon${num}Acc"}   = $pc{"weapon${num}_hit"};
    $pc{"weapon${num}Atk"}   = $pc{"weapon${num}_power"};
    $pc{"weapon${num}Guard"} = $pc{"weapon${num}_guard"};
    $pc{"weapon${num}Range"} = $pc{"weapon${num}_range"};
    $pc{"weapon${num}Note"}  = $pc{"weapon${num}_note"};
  }
  $pc{'armorNum'} = $pc{'count_weapon'};
  foreach my $num (1 .. $pc{'armorNum'}) {
    $pc{"armor${num}Name"}       = $pc{"armor${num}_name"};
    $pc{"armor${num}Stock"}      = $pc{"armor${num}_point"};
    $pc{"armor${num}Exp"}        = $pc{"armor${num}_exp"};
    $pc{"armor${num}Type"}       = $pc{"armor${num}_type"};
    $pc{"armor${num}Initiative"} = $pc{"armor${num}_dodge"};
    $pc{"armor${num}Dodge"}      = $pc{"armor${num}_speed"};
    $pc{"armor${num}Armor"}      = $pc{"armor${num}_guard"};
    $pc{"armor${num}Note"}       = $pc{"armor${num}_note"};
  }
  $pc{'armorNum'} = $pc{'count_weapon'};
  foreach my $num (1 .. $pc{'armorNum'}) {
    $pc{"item${num}Name"}       = $pc{"item${num}_name"};
    $pc{"item${num}Stock"}      = $pc{"item${num}_point"};
    $pc{"item${num}Exp"}        = $pc{"item${num}_exp"};
    $pc{"item${num}Type"}       = $pc{"item${num}_type"};
    $pc{"item${num}Skill"}      = $pc{"item${num}_skill"};
    $pc{"item${num}Note"}       = $pc{"item${num}_note"};
  }
  
  $pc{'freeNote'} = $pc{'text_free'};
  $pc{'freeHistory'} = $pc{'text_history'};
  
  $pc{'historyNum'} = $pc{'count_history'};
  foreach my $num (1 .. $pc{'historyNum'}) {
    $pc{"history${num}Date"}       = $pc{"hist_date$num"};
    $pc{"history${num}Title"}      = $pc{"hist_name$num"};
    $pc{"history${num}Exp"}        = $pc{"hist_exp$num"};
    $pc{"history${num}Gm"}         = $pc{"hist_gm$num"};
    $pc{"history${num}Member"}     = $pc{"hist_member$num"};
  }
  
  return %pc;
}

1;