#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
FAILED=0

run_and_check() {
  local name="$1"
  local expected="$2"
  shift 2
  local output
  local status
  output="$("$GODOT" --headless --path "$ROOT" "$@" 2>&1)"
  status=$?
  printf '%s\n' "$output"
  if [ "$status" -ne 0 ]; then
    printf 'TEST_RUNNER_FAILED %s exit=%d\n' "$name" "$status" >&2
    FAILED=1
  fi
  if printf '%s\n' "$output" | grep -Eq 'SCRIPT ERROR:|PARSE ERROR:|(^|[[:space:]])ERROR:'; then
    printf 'TEST_RUNNER_FAILED %s engine_error=true\n' "$name" >&2
    FAILED=1
  fi
  if [ -n "$expected" ] && [ "$(printf '%s\n' "$output" | grep -Fc "$expected")" -ne 1 ]; then
    printf 'TEST_RUNNER_FAILED %s expected=%s\n' "$name" "$expected" >&2
    FAILED=1
  fi
}

run_and_check editor "" --editor --quit
run_and_check levels LEVELS_OK --script res://tools/test_level_catalog.gd
run_and_check content_pools CONTENT_POOLS_OK --script res://tools/test_content_pools.gd
run_and_check stages STAGES_OK --script res://tools/test_stage_director.gd
run_and_check spawner SPAWNER_OK --script res://tools/test_enemy_spawner.gd
run_and_check enemy_abilities ENEMY_ABILITIES_OK --script res://tools/test_enemy_abilities.gd
run_and_check enemy_budgets ENEMY_BUDGETS_OK --script res://tools/test_enemy_ability_budgets.gd
run_and_check victory VICTORY_OK --script res://tools/test_victory_conditions.gd
run_and_check records RECORDS_OK --script res://tools/test_run_records.gd
run_and_check progression PROGRESSION_OK --script res://tools/test_hero_progression.gd
run_and_check power_equipment POWER_EQUIPMENT_OK --script res://tools/test_power_equipment.gd
run_and_check equipment_progression EQUIPMENT_PROGRESSION_OK --script res://tools/test_equipment_progression.gd
run_and_check heroes HEROES_OK --script res://tools/test_hero_systems.gd
run_and_check run_safety RUN_SAFETY_OK --script res://tools/test_run_safety.gd
run_and_check hero_rig HERO_RIG_OK --script res://tools/test_hero_rig.gd
run_and_check hero_rig_tuner HERO_RIG_TUNER_OK --script res://tools/test_hero_rig_tuner.gd
run_and_check run_build RUN_BUILD_OK --script res://tools/test_run_build.gd
run_and_check content_runtime CONTENT_RUNTIME_OK --script res://tools/test_content_runtime.gd
run_and_check balance BALANCE_OK --script res://tools/test_balance_contracts.gd
run_and_check start_ui START_UI_OK --script res://tools/test_start_ui.gd
run_and_check home_continuity HOME_CONTINUITY_OK --script res://tools/test_home_carousel_continuity.gd
run_and_check character_ui CHARACTER_UI_OK --script res://tools/test_character_ui.gd
run_and_check campaign CAMPAIGN_OK --script res://tools/smoke_campaign.gd
run_and_check smoke SMOKE_OK --script res://tools/smoke_game.gd
run_and_check responsive RESPONSIVE_OK --script res://tools/test_responsive_layout.gd
run_and_check architecture ARCHITECTURE_OK --script res://tools/check_architecture.gd

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi

printf 'ALL_TESTS_OK suites=26 responsive_profiles=4 content_catalogs=data_driven home_carousel=stable_shell engine_errors=false\n'
