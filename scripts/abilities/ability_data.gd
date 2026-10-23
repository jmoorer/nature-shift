class_name AbilityData
extends Resource
## One castable ability. Behaviour comes from `effect` (a registered effect id)
## plus `params`; no per-ability code.

@export var id := ""
@export var display_name := ""
## Element id from the nature chart ("lightning", "water", ...).
@export var nature := ""
## "spreadsheet" = technique listed in the xlsx; "proposed" = gameplay addition.
@export_enum("spreadsheet", "proposed") var source := "proposed"
## Catalog row this builds on (data/catalog/catalog.json), e.g. "Nature Chart: Lightning Release".
@export var catalog_ref := ""
@export var effect := ""
@export var cooldown := 1.0
@export var max_range := 400.0
@export var color := Color.WHITE
@export var params := {}
