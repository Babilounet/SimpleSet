# Changelog

## v1.3.2

- **Fix**: minimap icon now updates on login (`PLAYER_ENTERING_WORLD` + 1s delay)
- **Fix**: minimap icon now updates when changing a single gear piece (debounced 0.5s timer)

## v1.3.1

- **Fix**: bag lock icons now refresh immediately after saving a set (default bags + Baganator)

## v1.3

- **Icon picker**: choose an icon per set from 36 presets (gear, weapons, all class spec icons)
- **Auto-detect icon**: first save captures the main hand weapon texture automatically
- **Icons in dropdowns**: set icons displayed in Load, Save, and minimap menus
- **Minimap button**: left-click to quick-load a set, right-click for settings, draggable around the minimap edge
- **Square minimap support**: button positioning adapts to square minimaps (e.g. SexyMap)
- **Dynamic minimap icon**: button reflects the currently equipped set's icon
- **Spec binding**: bind a set to talent spec 1 or 2 in settings (S1/S2 button)
- **Auto-equip on spec change**: bound sets equip automatically when switching talent spec
- **Spec indicator**: dropdowns show (S1)/(S2) next to bound sets
- Settings frame widened to accommodate icon + name + spec controls

## v1.1

- **Ring/trinket fix**: duplicate item names (e.g. two identical rings) now equip correctly with staggered timing
- **Bag lock icons**: items belonging to a set display a lock overlay in bags
- **Baganator integration**: lock icon registered as a native corner widget (25x25, top-left)
- **Default bags fallback**: lock overlay via `ContainerFrame_Update` hook for non-Baganator users

## v1.0

- Initial release — full rewrite from EquipmentSets addon
- **Per-slot equipping** using `EquipItemByName(name, slotID)` instead of `/equip`
- **UI repositioned** to top of character panel (under player name)
- **Dynamic sets**: start with 2, add or remove up to 10 via settings
- **Rename sets**: both Load and Save dropdowns reflect custom names
- **Save confirmation**: overwrite popup before saving
- **Slash commands**: `/ss save <n>`, `/ss load <n>`, `/ss list`, `/unequipall`
