# QuickProspect Forever

Alt-click processing for Warcraft Forever, ported from QuickProspect for WoW 3.3.5.

Version **1.1.4-forever** targets client **1.60.1**, build **69913**, interface **16001**.

## Installation

Download or clone this repository, name the addon folder **QuickProspect**, and place it in your client's `Interface/AddOns` directory. `QuickProspect.toc` and `QuickProspect.lua` must be directly inside that folder. Restart the client and enable QuickProspect.

## Usage

Hold **Alt** over an eligible item in Blizzard bags, then left-click to disenchant, prospect, mill, or pick its lock. Processing is disabled during combat. Prospecting and milling require five items in one physical stack.

- `/qp`: show addon/client versions and detected processing spells.
- `/qp debug`: toggle hover and click diagnostics.
- Purple highlights indicate disenchanting or prospecting; blue indicates milling or lockpicking. Red indicates a known unmet skill requirement.

The original Wrath sparkle effect is used when available, with a border glow fallback.

## Disenchant detection

The addon reads tooltip eligibility and Enchanting requirements, including non-equipment quest items. It recognizes Warcraft Forever's description: “The faint magic within can be extracted with the Disenchanting skill.” Explicit cannot-disenchant text takes precedence. When tooltip eligibility is absent, ordinary uncommon through epic armor and weapons use the original equipment heuristic.

Requirements not reported by the client are shown as unknown. The game determines final eligibility. Crude Wax Effigy disenchanting was confirmed working in-game.

## Limitations

Ore, herb, and lockbox lists retain the original 3.3.5 data; custom materials may need additional entries. This port targets Blizzard bags and does not include the original UniBags-specific click hooks. Custom tooltip wording beyond recognized descriptions may need additional support.

Lua syntax and mocked regression checks covered item classification, tooltip parsing, skill thresholds, bag targeting, hover detection, and sparkle start/stop. These checks do not replace testing protected actions in the game client.
