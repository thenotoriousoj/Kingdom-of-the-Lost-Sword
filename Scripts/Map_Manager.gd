extends Node

class_name Tile_Generator
var rng
var textures = {
	"grass": preload("res://Assets/Textures/Grass.jpg"),
	"mountain": preload("res://Assets/Textures/Mountain.jpg"),
	"desert": preload("res://Assets/Textures/Desert.jpg"),
	"forest": preload("res://Assets/Textures/Forest.jpg"),
	"dirt": preload("res://Assets/Textures/Dirt.jpg")
}
# Elevation varies from 0 to 100
var biomes = {
	"lowerFields": {
		"humidity": {
			"low": .3,
			"high": 1
		},
		"elevation": {
			"low": 0,
			"high": 40
		},
		"terrainMultiplier": .7,
		"name": "lowerFields"
	},
	"upperFields": {
		"humidity": {
			"low": .3,
			"high": 1
		},
		"elevation": {
			"low": 40,
			"high": 60
		},
		"terrainMultiplier": 1,
		"name": "upperFields"
	},
	"Mountains": {
		"humidity": {
			"low": .3,
			"high": 1
		},
		"elevation": {
			"low": 60,
			"high": 100
		},
		"terrainMultiplier": 1.5,
		"name": "Mountains"
	},
	"desert": {
		"humidity": {
			"low": 0,
			"high": .3
		},
		"elevation": {
			"low": 0,
			"high": 40
		},
		"terrainMultiplier": .7,
		"name": "desert"
	},
	"salts": {
		"humidity": {
			"low": 0,
			"high": .3
		},
		"elevation": {
			"low": 40,
			"high": 60
		},
		"terrainMultiplier": .2,
		"name": "salts"
	},
	"volcano": {
		"humidity": {
			"low": 0,
			"high": .3
		},
		"elevation": {
			"low": 60,
			"high": 100
		},
		"terrainMultiplier": 2,
		"name": "volcano"
	},
}
var world_generator = {
	"lowerFields": [
		{"type": "grass", "priority": 5},
		{"type": "forest", "priority": 1},
	],
	"upperFields": [
		{"type": "grass", "priority": 1},
		{"type": "forest", "priority": 5},
		{"type": "mountain", "priority": 1},
	],
	"Mountains": [
		{"type": "forest", "priority": 2},
		{"type": "mountain", "priority": 5},
	],
	"desert": [
		{"type": "grass", "priority": 2},
		{"type": "desert", "priority": 6},
	],
	"salts": [
		{"type": "mountain", "priority": 3},
		{"type": "desert", "priority": 3},
	],
	"volcano": [
		{"type": "mountain", "priority": 10},
		{"type": "desert", "priority": 3},
	],
	
}

func _init(requestedSeed : int):
	rng = RandomNumberGenerator.new()
	rng.seed = requestedSeed
func generateBiome(humidity, elevation):
	elevation = (elevation + 1) * .5 * 100
	for biome in biomes:
		if (humidity <= biomes[biome].humidity.high && humidity >= biomes[biome].humidity.low):
			if (elevation <= biomes[biome].elevation.high && elevation >= biomes[biome].elevation.low):
				return biomes[biome]
	return 'upperFields'		
		
func generateTile(biome):
	var worldPool = world_generator[biome]
	var totalPriority: int = 0
	for hextype in worldPool:
		totalPriority += hextype.priority
			
	if (totalPriority <=0): return null
	var num = rng.randi_range(1, totalPriority)
	for tileObj in worldPool:
		var priority = tileObj["priority"]
		if (num <= priority):
			var hex = {
				"type": tileObj["type"],
				"biome": biome,
				"texture": {
					"top": textures[tileObj["type"]],
					"side": textures["dirt"]
					},
			}
			return hex
		else:
			num -= priority
