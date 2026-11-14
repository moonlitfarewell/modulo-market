local MM = _G.ModuloMarket
if not MM then return end

-- Waylaid crate identities are the labelled, tradeable crate items. The
-- generic unlabelled Waylaid Crate is only used to reveal a label and is not
-- added as a second purchase requirement for a known crate type.
MM.TurnInData = {
    version = "0.11.0",
    provider = "User-supplied Polestar Codex item index; Wowhead Forever, WowSeer and Forever Hub item/reward references",
    categories = { "Herbs", "Ore", "Textiles", "Curiosities", "Fabrics", "Ingots", "Parts" },
    tiers = { "Apprentice", "Journeyman", "Expert", "Artisan" },
    -- Each bundle is an alternative. A player completes a crate with ONE
    -- complete bundle, not all listed alternatives.
    crates = {
        { id=248682, name="Waylaid Crate: Apprentice Herbs", tier="Apprentice", category="Herbs", rewardFavor=5, rewardCashCopper=250, reputation=0, bundles={
            {{"Peacebloom",20}},{{"Silverleaf",20}},{{"Earthroot",10}},{{"Mageroyal",10}},{{"Briarthorn",10}},
        }},
        { id=248683, name="Waylaid Crate: Apprentice Ore", tier="Apprentice", category="Ore", rewardFavor=5, rewardCashCopper=250, reputation=0, bundles={
            {{"Copper Ore",20}},{{"Tin Ore",20}},
        }},
        { id=248684, name="Waylaid Crate: Apprentice Textiles", tier="Apprentice", category="Textiles", rewardFavor=5, rewardCashCopper=250, reputation=0, bundles={
            {{"Linen Cloth",40}},{{"Light Leather",20}},
        }},
        { id=248685, name="Waylaid Crate: Apprentice Curiosities", tier="Apprentice", category="Curiosities", rewardFavor=5, rewardCashCopper=250, reputation=0, bundles={
            {{"Strange Dust",20}},{{"Greater Magic Essence",4}},{{"Small Glimmering Shard",6}},{{"Large Glimmering Shard",2}},
        }},
        { id=248702, name="Waylaid Crate: Apprentice Fabrics", tier="Apprentice", category="Fabrics", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Cured Light Hide",2}},{{"Bolt of Linen Cloth",20}},
        }},
        { id=248703, name="Waylaid Crate: Apprentice Ingots", tier="Apprentice", category="Ingots", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Copper Bar",20}},{{"Tin Bar",20}},{{"Bronze Bar",10}},
        }},
        { id=248704, name="Waylaid Crate: Apprentice Parts", tier="Apprentice", category="Parts", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Handful of Copper Bolts",16}},{{"Copper Tube",16}},{{"Copper Modulator",4}},
        }},
        { id=248686, name="Waylaid Crate: Journeyman Herbs", tier="Journeyman", category="Herbs", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Stranglekelp",10}},{{"Bruiseweed",10}},{{"Wild Steelbloom",10}},{{"Grave Moss",10}},{{"Kingsblood",10}},
        }},
        { id=248687, name="Waylaid Crate: Journeyman Ore", tier="Journeyman", category="Ore", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Silver Ore",10}},{{"Iron Ore",20}},
        }},
        { id=248688, name="Waylaid Crate: Journeyman Textiles", tier="Journeyman", category="Textiles", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Wool Cloth",20}},{{"Silk Cloth",40}},{{"Medium Leather",20}},
        }},
        { id=248689, name="Waylaid Crate: Journeyman Curiosities", tier="Journeyman", category="Curiosities", rewardFavor=10, rewardCashCopper=500, reputation=0, bundles={
            {{"Soul Dust",20}},{{"Greater Astral Essence",4}},{{"Small Glowing Shard",6}},{{"Large Glowing Shard",2}},
        }},
        { id=248705, name="Waylaid Crate: Journeyman Fabrics", tier="Journeyman", category="Fabrics", rewardFavor=20, rewardCashCopper=1000, reputation=0, bundles={
            {{"Bolt of Woolen Cloth",6}},{{"Bolt of Silk Cloth",10}},{{"Cured Medium Hide",2}},
        }},
        { id=248706, name="Waylaid Crate: Journeyman Ingots", tier="Journeyman", category="Ingots", rewardFavor=20, rewardCashCopper=1000, reputation=0, bundles={
            {{"Silver Bar",10}},{{"Iron Bar",20}},
        }},
        { id=248707, name="Waylaid Crate: Journeyman Parts", tier="Journeyman", category="Parts", rewardFavor=20, rewardCashCopper=1000, reputation=0, bundles={
            {{"Bronze Tube",8}},{{"Whirring Bronze Gizmo",7}},{{"Bronze Framework",4}},{{"Gold Power Core",45}},
        }},
        { id=248690, name="Waylaid Crate: Earthly Expert Herbs", tier="Expert", category="Herbs", rewardFavor=15, rewardCashCopper=750, reputation=0, bundles={
            {{"Liferoot",20}},{{"Fadeleaf",10}},{{"Goldthorn",10}},{{"Khadgar's Whisker",10}},
        }},
        { id=248691, name="Waylaid Crate: Flowering Expert Herbs", tier="Expert", category="Herbs", rewardFavor=15, rewardCashCopper=750, reputation=0, bundles={
            {{"Wintersbite",10}},{{"Firebloom",10}},{{"Purple Lotus",20}},{{"Arthas' Tears",10}},
        }},
        { id=248692, name="Waylaid Crate: Expert Ore", tier="Expert", category="Ore", rewardFavor=15, rewardCashCopper=750, reputation=0, bundles={
            {{"Gold Ore",10}},{{"Mithril Ore",20}},
        }},
        { id=248693, name="Waylaid Crate: Expert Textiles", tier="Expert", category="Textiles", rewardFavor=15, rewardCashCopper=750, reputation=0, bundles={
            {{"Mageweave Cloth",40}},{{"Heavy Leather",20}},
        }},
        { id=248694, name="Waylaid Crate: Expert Curiosities", tier="Expert", category="Curiosities", rewardFavor=15, rewardCashCopper=750, reputation=0, bundles={
            {{"Vision Dust",20}},{{"Greater Mystic Essence",4}},{{"Small Radiant Shard",6}},{{"Large Radiant Shard",2}},
        }},
        { id=248708, name="Waylaid Crate: Expert Fabrics", tier="Expert", category="Fabrics", rewardFavor=30, rewardCashCopper=1500, reputation=0, bundles={
            {{"Bolt of Mageweave",8}},{{"Cured Heavy Hide",2}},
        }},
        { id=248709, name="Waylaid Crate: Expert Ingots", tier="Expert", category="Ingots", rewardFavor=30, rewardCashCopper=1500, reputation=0, bundles={
            {{"Mithril Bar",20}},{{"Steel Bar",15}},{{"Gold Bar",10}},
        }},
        { id=248710, name="Waylaid Crate: Expert Parts", tier="Expert", category="Parts", rewardFavor=30, rewardCashCopper=1500, reputation=0, bundles={
            {{"Iron Strut",8}},{{"Mithril Tube",5}},{{"Unstable Trigger",12}},{{"Mithril Casing",5}},
        }},
        { id=248695, name="Waylaid Crate: Earthly Artisan Herbs", tier="Artisan", category="Herbs", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Golden Sansam",10}},{{"Sungrass",20}},{{"Blindweed",10}},{{"Ghost Mushroom",10}},{{"Gromsblood",10}},
        }},
        { id=248696, name="Waylaid Crate: Flowering Artisan Herbs", tier="Artisan", category="Herbs", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Dreamfoil",20}},{{"Mountain Silversage",20}},{{"Plaguebloom",20}},{{"Icecap",20}},
        }},
        { id=248697, name="Waylaid Crate: Artisan Ore", tier="Artisan", category="Ore", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Truesilver Ore",10}},{{"Thorium Ore",20}},{{"Dark Iron Ore",20}},
        }},
        { id=248698, name="Waylaid Crate: Artisan Textiles", tier="Artisan", category="Textiles", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Runecloth",40}},{{"Thick Leather",20}},{{"Rugged Leather",20}},
        }},
        { id=248699, name="Waylaid Crate: Artisan Curiosities", tier="Artisan", category="Curiosities", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Dream Dust",20}},{{"Greater Nether Essence",4}},{{"Small Brilliant Shard",6}},{{"Large Brilliant Shard",2}},
        }},
        { id=248711, name="Waylaid Crate: Artisan Fabrics", tier="Artisan", category="Fabrics", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Bolt of Runecloth",8}},{{"Cured Thick Hide",2}},
        }},
        { id=248712, name="Waylaid Crate: Artisan Ingots", tier="Artisan", category="Ingots", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Dark Iron Bar",2}},{{"Truesilver Bar",10}},{{"Thorium Bar",20}},
        }},
        { id=248713, name="Waylaid Crate: Artisan Parts", tier="Artisan", category="Parts", rewardFavor=nil, rewardCashCopper=nil, reputation=0, bundles={
            {{"Thorium Widget",5}},{{"Truesilver Transformer",5}},{{"Thorium Tube",2}},
        }},
    },
    -- One-time Shipping Label quest, deliberately excluded from repeatable
    -- per-crate calculations.
    firstTurnInBonus = { favor=50, reputation=2000, oneTime=true },
    performanceBonusIncluded = false,
}
