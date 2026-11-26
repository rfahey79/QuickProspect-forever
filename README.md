# QuickProspect Forever

Alt-click disenchanting for Warcraft Forever.

Version **1.1.4-forever** targets client **1.60.1**, build **69913**, interface **16001**.

## Installation

Download or clone this repository, name the addon folder **QuickProspect**, and place it in your client's `Interface/AddOns` directory. `QuickProspect.toc` and `QuickProspect.lua` must be directly inside that folder. Restart the client and enable QuickProspect.

To clone directly from your `Interface/AddOns` directory:

```powershell
git clone https://github.com/rfahey79/QuickProspect-forever.git QuickProspect
```

For future updates, run `git pull` inside `QuickProspect`. Local development files under `tests/` are ignored.

## Usage

Hold **Alt** over an eligible item in Blizzard bags, then left-click to disenchant it. Disenchanting through the addon is disabled during combat.

- `/qp`: show addon/client versions and detected processing spells.
- `/qp debug`: toggle hover and click diagnostics.
- Purple highlights indicate a disenchanting candidate. Red indicates a known unmet skill requirement.

Eligible items display a sparkle effect when available, with a border glow fallback.

## Disenchant detection

The addon checks that Disenchant is learned, then reads the client's item tooltip data for disenchant eligibility and required Enchanting skill. This supports eligible non-equipment items, including quest items. Items explicitly marked ineligible are excluded. When eligibility data is unavailable, uncommon through epic armor and weapons are treated as candidates based on their item type and quality.

Known skill requirements are compared with your Enchanting skill, and unmet requirements block the action. Requirements not reported by the client are shown as unknown. The game determines final eligibility.

## Limitations

The addon targets Blizzard bags. Custom items without recognizable eligibility data may not be detected, and equipment identified by type and quality may still be rejected by the game.

Lua syntax and mocked regression checks covered item classification, tooltip parsing, skill thresholds, bag targeting, hover detection, and sparkle start/stop. These checks do not replace testing protected actions in the game client.
