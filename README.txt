QuickProspect 1.1.4-forever
Target: Warcraft Forever 1.60.1 build 69913, Interface 16001.

Hold Alt and left-click a highlighted item in Blizzard bags to disenchant it,
outside combat. /qp shows version and detected spells; /qp debug toggles diagnostics.

The addon checks that Disenchant is learned, then reads the client's item tooltip
data for disenchant eligibility and required Enchanting skill. Eligible
non-equipment items, including quest items, are supported. Explicitly ineligible
items are excluded. When eligibility data is unavailable, uncommon through epic
armor and weapons are treated as candidates based on item type and quality.

Purple highlights indicate disenchanting candidates. Red highlights indicate
known unmet skill requirements and block the action. Requirements not reported
by the client remain unknown. The game determines final eligibility.

This addon targets Blizzard bags. Custom items without recognizable eligibility
data may not be detected. Restart the client after first installation if
QuickProspect does not appear in its addon list.
