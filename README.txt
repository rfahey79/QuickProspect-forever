QuickProspect 1.1.4-forever
Target: Warcraft Forever 1.60.1 build 69913, Interface 16001.

Hold Alt and left-click a highlighted item in Blizzard bags, outside combat.
Prospecting and milling require at least five items in one physical stack.
/qp shows version and learned processing spells. /qp debug toggles diagnostics.

This first port retains the 3.3.5 ore, herb, and lockbox lists. Custom server
items and later expansion materials require additional data. Disenchanting
first reads the client's tooltip for eligibility and required Enchanting skill,
including non-equipment quest items. Explicit cannot-disenchant lines override
the equipment-quality fallback. Unknown skill requirements are labeled unknown;
the game checks final eligibility. Red highlighting blocks known unmet requirements.
With /qp debug enabled, unrecognized items print their tooltip text for diagnosis.
Unknown profession ranks defer eligibility to the game. UniBags-specific
3.3.5 click hooks are not included; this build targets Blizzard bag buttons.

Validated with a mocked Lua environment; actual casting and client-specific
behavior require in-game testing. Restart the client after first installation
if QuickProspect does not appear in its addon list.
