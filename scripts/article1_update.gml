//article1_update.gml -- CD
//=====================================================
#macro AR_STATE_BUFFER      -1 
#macro AR_STATE_DEAD         0 
#macro AR_STATE_IDLE         1
#macro AR_STATE_BOUNCE       2
#macro AR_STATE_FSTRONG      AT_FSTRONG
#macro AR_STATE_FSTRONG_ROLL 4
#macro AR_STATE_USTRONG      AT_USTRONG
#macro AR_STATE_DSTRONG      AT_DSTRONG
#macro AR_STATE_DSTRONG_AIR  AT_DSTRONG_2
#macro AR_STATE_DSPECIAL     AT_DSPECIAL_2
//=====================================================

// no logic/timers affected if we're currently in hitstop
if (hitstop) exit;

//=====================================================
//applying buffered state
if (buffered_state != AR_STATE_BUFFER)
{
    set_state(buffered_state);
    cd_saved_spin_meter = cd_spin_meter;
    buffered_state = AR_STATE_BUFFER;
}
//=====================================================

//General logic
visible = (state != AR_STATE_DEAD);
ignores_walls = (state == AR_STATE_DSPECIAL);

switch (state)
{
//=====================================================
    case AR_STATE_DEAD:
    {
        x = 0; y = 0; hsp = 0; vsp = 0;
    } break;
//=====================================================
    case AR_STATE_IDLE:
    {
        //Update
        do_gravity();
        do_friction();
        try_pickup();
        
        //Dying
        if !(pre_dspecial_immunity > 0) && (cd_spin_meter == 0)
        {
            buffered_state = AR_STATE_DEAD;
        }
        
        //Animation
        sprite_index = spr_article_cd_idle;
        image_index += 0.8;
        
    } break;
//=====================================================
    case AR_STATE_FSTRONG:
    {
        //Update
        if (hsp * spr_dir > 0)
        {
            hsp -= (spr_dir * cd_accel_force);
            if (0 == state_timer % 5)
            {
                spawn_hitbox(AT_FSTRONG, 2, true, false);
            }
        }
        else
        {
            if (has_hit) //finisher
            { spawn_hitbox(AT_FSTRONG, 3, false, false); }
            set_state(AR_STATE_FSTRONG_ROLL);
        }
        
        //Animation
        sprite_index = spr_article_cd_shoot;
        image_index += 0.5;
        
    } break;
//=====================================================
    case AR_STATE_FSTRONG_ROLL:
    {
        //Update
        if (state_timer > 30)
        {
            set_state(AR_STATE_IDLE);
        }
        else if (-hsp * spr_dir < cd_roll_speed)
        {
            hsp -= (spr_dir * cd_accel_force);
        }
        else
        {
            hsp = -spr_dir * cd_roll_speed;
        }
        do_gravity();
        try_pickup();
        
        //Animation
        sprite_index = spr_article_cd_shoot;
        image_index += 0.25;
    } break;
//=====================================================
    case AR_STATE_USTRONG:
    {
        //Update
        if (vsp < 0)
        {
            do_gravity();
            if (0 == state_timer % 5)
            {
                spawn_hitbox(AT_FSTRONG, 2, true, false);
            }
        }
        else
        {
            if (has_hit) //finisher
            { spawn_hitbox(AT_FSTRONG, 3, false, false); }
            set_state(AR_STATE_DSTRONG_AIR);
        }
        
        //Animation
        sprite_index = spr_article_cd_shoot;
        image_index += 0.5;
    } break;
//=====================================================
    case AR_STATE_DSTRONG_AIR:
    {
        //Update
        do_gravity();
        
        if (state_timer <= 1)
        {
            state_timer = 1;
            has_dstrong_hitbox = false;
        }
        if (vsp > cd_dstrong_air_min_speed_for_hitbox) && (!has_dstrong_hitbox)
        {
            spawn_hitbox(AT_DSTRONG_2, 1, false, false);
            has_dstrong_hitbox = true;
        }
        else if (!free || has_hit)
        {
            if (!has_hit) { sound_play(asset_get("sfx_blow_weak1")); }
            set_state(AR_STATE_IDLE);
            vsp = -6;
            hsp = spr_dir * -1;
        }
        
        //Animation
        sprite_index = spr_article_cd_shoot;
        image_index += 0.25;
    } break;
//=====================================================
    case AR_STATE_DSPECIAL:
    {
        //Update
        //Shoot towards player
        var total_speed = point_distance(0, 0, hsp, vsp);
        if (total_speed < cd_dspecial_speed)
        {
            total_speed += cd_dspecial_force;
        }
        else
        {
            total_speed = cd_dspecial_speed;
        }
        var lookat_angle = point_direction(x, y, 
                      player_id.x, player_id.y - 20);
        hsp = lengthdir_x(total_speed, lookat_angle);
        vsp = lengthdir_y(total_speed, lookat_angle);
        
        try_pickup();
        if (state == AR_STATE_DEAD)
        {
            //blade was caught!
            //Activate DSPECIAL 2
        }
        else if (0 == state_timer % 5)
        {
            spawn_hitbox(AT_FSTRONG, 2, true, false);
        }
        
        //Animation
        sprite_index = spr_article_cd_shoot;
        //image_angle = lookat_angle;
        image_index += 0.25;
                               
    } break;
//=====================================================
    default: state = AR_STATE_IDLE;
    break;
}

state_timer++;

// Charge drain
if (cd_spin_meter > 0) && !(state == AR_STATE_DEAD && 
                            (player_id.uhc_no_charging || !player_id.uhc_has_cd_blade) )
{
    cd_spin_meter -= (state == AR_STATE_IDLE) ? player_id.uhc_cd_spin_drain_idle
                                              : player_id.uhc_cd_spin_drain_base;
    cd_spin_meter = clamp(cd_spin_meter, 0, player_id.uhc_cd_spin_max);
}

//immunity to bottom blast zone for a couple of frames 
if (pre_dspecial_immunity > 0)
{
   //when activating AT_DSPECIAL_2 while CD is still alive, needs to be allowed to call back
   pre_dspecial_immunity--;
}
else if (y > room_height)
{
    //fell off the stage 
    buffered_state = AR_STATE_DEAD;
}

//=====================================================
#define set_state(new_state)
{
    state = new_state;
    state_timer = 0;
    has_hit = false;
}

//==============================================================================
#define do_gravity()
{
    if (free && vsp < cd_fall_speed) vsp += cd_grav_force;
}
//==============================================================================
#define do_friction()
{
    if (!free) hsp *= (1 - cd_frict_force);
}

//==============================================================================
#define try_pickup()
{
    if (pickup_cooldown > 0)
    {
        pickup_cooldown--;
    }
    else if (place_meeting(x, y, player_id))
    {
        state = AR_STATE_DEAD;
        player_id.uhc_has_cd_blade = true;
        player_id.uhc_update_blade_status = true;
        sound_play(asset_get("sfx_coin_collect"));
        
        if (self != player_id.uhc_current_cd)
        {
            player_id.uhc_other_cd = player_id.uhc_current_cd;
            player_id.uhc_current_cd = self;
        }
        
    }
}
//==============================================================================
#define spawn_hitbox(atk, hnum, multihits, hit_self)
{
    var hb = create_hitbox(atk, hnum, x, y);
    hb.uhc_parent_cd = self;
    hb.can_hit_self = hit_self;
    hb.multihits = multihits;
    
    //apply buffs (should have the same effects as attack_update's adjust_blade_attack_grid)
    var charge_percent = cd_saved_spin_meter / player_id.uhc_cd_spin_max;
    with (player_id)
    {
        if (0 < get_hitbox_value(atk, hnum, HG_SPIN_DAMAGE_BONUS))
        { 
            hb.damage += charge_percent * get_hitbox_value(atk, hnum, HG_SPIN_DAMAGE_BONUS); 
            hb.damage = floor(hb.damage);
        }
        if (0 < get_hitbox_value(atk, hnum, HG_SPIN_HITPAUSE_BONUS))
        { hb.hitpause += charge_percent * get_hitbox_value(atk, hnum, HG_SPIN_HITPAUSE_BONUS); }
        if (0 < get_hitbox_value(atk, hnum, HG_SPIN_KNOCKBACK_BONUS))
        { hb.kb_value += charge_percent * get_hitbox_value(atk, hnum, HG_SPIN_KNOCKBACK_BONUS); }
        if (0 < get_hitbox_value(atk, hnum, HG_SPIN_KNOCKBACK_SCALING_BONUS))
        { hb.kb_scale += charge_percent * get_hitbox_value(atk, hnum, HG_SPIN_KNOCKBACK_SCALING_BONUS); }
    }
    
    return hb;
}
