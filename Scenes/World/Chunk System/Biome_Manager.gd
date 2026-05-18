extends Node

class_name BiomeManager
var materials = {
	"Dirt": preload("res://Assets/Textures/Retro/Biomes/Forest Hills/Materals/Dirt/Ground082L_1K-JPG.tres"),
	"Grass": preload("res://Assets/Textures/Retro/Biomes/Forest Hills/Materals/Grass/Grass007_1K-JPG.tres"),
	"Sand" : preload("res://Assets/Textures/Retro/Biomes/Arid Desert/Materials/Sand/Ground097_1K-JPG.tres"),
	"Lush Sand" : preload("res://Assets/Textures/Retro/Biomes/Arid Desert/Materials/Lush Sand/Ground093A_1K-JPG.tres"),
	"Red Rock" : preload("res://Assets/Textures/Retro/Biomes/Arid Desert/Materials/Red Rock/Rock029_1K-JPG.tres"),
	"Sandstone" : preload("res://Assets/Textures/Retro/Biomes/Arid Desert/Materials/Sandstone/Bricks083_1K-JPG.tres"),
	"Stone": preload("res://Assets/Textures/Retro/Biomes/Stone Plateau/Materials/Wet Rock/Rock058_1K-JPG.tres"),
	"Cobble": preload("res://Assets/Textures/Retro/Biomes/Stone Plateau/Materials/Cobble/Rock034_1K-JPG.tres"),
	"Ash": preload("res://Assets/Textures/Retro/Biomes/Volcanic Wastes/Materials/Ash/Ash.tres"),
	"Volcanic Rock": preload("res://Assets/Textures/Retro/Biomes/Volcanic Wastes/Materials/Volcanic Rock/Rock035_1K-JPG.tres"),
	"Salt": preload("res://Assets/Textures/Retro/Biomes/Salt Flats/Materials/Onyx/Onyx015_1K-JPG.tres"),
}
var textures = {
	"Grass": { # Name of Tile
		"material": materials["Grass"], # Material to be used on top.
		"class": "Plain", # Class determines what can be built on it and how it acts.
		"point": 0,  # Center Vertex elevation multiplied by Tile Size
		"scale": .1, # Scale of Texture. Bigger Value = Smaller Texture
		"map": {}, # Dictionary to store tinted variations of textures.
		"side": {  # Same Data but for Side Material when a Hex Cliff is Made.
			"material": materials["Dirt"],
			"map": {},
			"scale": .1
		}
	},
	"Lush Sand": { # Name of Tile
		"material": materials["Lush Sand"], # Material to be used on top.
		"class": "Forest", # Class determines what can be built on it and how it acts.
		"point": 0,  # Center Vertex elevation multiplied by Tile Size
		"scale": .1, # Scale of Texture. Bigger Value = Smaller Texture
		"map": {}, # Dictionary to store tinted variations of textures.
		"side": {  # Same Data but for Side Material when a Hex Cliff is Made.
			"material": materials["Sandstone"],
			"map": {},
			"scale": .1
		}
	},
	"Mountain": {
		"material": materials["Stone"],
		"class": "Quarry",
		"point": .5,
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Stone"],
			"map": {},
			"scale": .1
			}
		},
	"Cobble": {
		"material": materials["Cobble"],
		"class": "Forsaken",
		"point": 0,
		"scale": .03,
		"map": {},
		"side": {
			"material": materials["Cobble"],
			"map": {},
			"scale": .1
			}
		},
	"Sand": {
		"material" : materials["Sand"],
		"class": "Forsaken",
		"point": 0,
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Sandstone"],
			"map": {},
			"scale": .1
			}
	},
	"Sediment": {
		"material" : materials["Red Rock"],
		"class": "Quarry",
		"point": 0,
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Red Rock"],
			"map": {},
			"scale": .1
			}
	},
	"Forest": {
		"material": materials["Grass"],
		"class": "Forest",
		"point": 0,
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Dirt"],
			"map": {},
			"scale": .1
			}
	},
	"Dirt": {
		"material": materials["Dirt"],
		"class": "Plain",
		"point": 0,
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Dirt"],
			"map": {},
			"scale": .1
			}
	},
	"Ash": {
		"material": materials["Ash"],
		"point": -.1,
		"class": "Plain",
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Ash"],
			"map": {},
			"scale": .1
			}
	},
	"Volcanic Rock": {
		"material": materials["Volcanic Rock"],
		"class": "Quarry",
		"point": .25,
		"scale": .1,
		"map": {},
		"side": {
			"material": materials["Volcanic Rock"],
			"map": {},
			"scale": .1
			}
	},
	"Salt": {
		"material": materials["Salt"],
		"class": "Forsaken",
		"point": 0,
		"scale": .05,
		"map": {},
		"side": {
			"material": materials["Salt"],
			"map": {},
			"scale": 1
			}
	},
}
# Elevation varies from 0 to 100
var biomes = {
	"Grassy Plains": {
		"humidity": .50,
		"elevation": .40,
		"terrainMultiplier": .8,
		"tint": {
			"Mountain": Color(0.985, 0.88, 0.828, 1.0),
			"Grass": Color (1, 1, 1)
		},
		"fog_tint": null,
		"light_energy": null,
		"fog_density": 0.001,
		"morning_fog": true,
		"evening_fog": false,
		"night_fog": .02,
	},
	"Forest Peaks": {
		"humidity": .50,
		"elevation": .55,
		"terrainMultiplier": 1,
		"tint": {
			"Grass": Color(0.622, 0.999, 0.618, 1.0),
			"Forest": Color(0.622, 0.999, 0.618, 1.0),
		},
		"fog_tint": null,
		"light_energy": null,
		"fog_density": 0.001,
		"morning_fog": true,
		"evening_fog": false,
		"night_fog": .03,
	},
	"Stone Peaks": {
		"humidity": .50,
		"elevation": .70,
		"terrainMultiplier": 2.5,
		"tint": {
			"Grass": Color(0.622, 0.999, 0.618, 1.0),
			"Forest": Color(0.622, 0.999, 0.618, 1.0),
		},
		"fog_tint": Color(0.699, 0.652, 0.578, 1.0),
		"light_energy": 1.1,
		"fog_density": 0.03,
		"morning_fog": true,
		"evening_fog": false,
		"night_fog": .03,
	},
	"Stone Plateaus": {
		"humidity": .50,
		"elevation": .71,
		"terrainMultiplier": 1,
		"tint": {
			"Grass": Color(0.622, 0.999, 0.618, 1.0),
			"Forest": Color(0.622, 0.999, 0.618, 1.0),
		},
		"fog_tint": Color(0.42, 0.42, 0.42, 1.0),
		"light_energy": 1.1,
		"fog_density": 0.04,
		"morning_fog": true,
		"evening_fog": false,
		"night_fog": .04,
	},
	"Arid Desert": {
		"humidity": .33,
		"elevation": .33,
		"terrainMultiplier": .8,
		"tint": {
			"Grass": Color(0.89, 0.71, 0.075, 1.0),
			"Forest": Color(0.89, 0.71, 0.075, 1.0),
		},
		"fog_tint": Color(0.777, 0.516, 0.237, 1.0),
		"light_energy": 1.4,
		"fog_density": 0.04,
		"morning_fog": false,
		"evening_fog": false,
		"night_fog": .04,
		"night_fog_tint": Color(0.329, 0.222, 0.014, 1.0)
	},
	"Salt Flats": {
		"humidity": .29,
		"elevation": .29,
		"terrainMultiplier": .4,
		"tint": {
			"Desert": Color(0.982, 0.982, 0.982, 1.0)
		},
		"fog_tint": Color(1.0, 1.0, 1.0, 1.0),
		"light_energy": 1.6,
		"fog_density": 0.08,
		"morning_fog": false,
		"evening_fog": false,
		"night_fog": 0.08,
	},
	"Volcanic Peaks": {
		"humidity": .35,
		"elevation": .8,
		"terrainMultiplier": 3,
		"tint": {
			"Grass":Color(0.135, 0.063, 0.042, 1.0),
			"Sand":Color(0.135, 0.063, 0.042, 1.0),
			"Forest":Color(0.135, 0.063, 0.042, 1.0),
		},
		"fog_tint": Color(0.872, 0.426, 0.341, 1.0),
		"light_energy": .8,
		"fog_density": 0.03,
		"morning_fog": false,
		"evening_fog": false,
		"night_fog": .04,
		"night_fog_tint": Color(0.392, 0.144, 0.099, 1.0),
	},
	"Bog Swamps": {
		"humidity": .70,
		"elevation": .3,
		"terrainMultiplier": 1,
		"tint": {
			"Grass":Color(0.243, 0.419, 0.267, 1.0),
			"Forest":Color(0.243, 0.419, 0.267, 1.0),
			"Mountain": Color(0.243, 0.419, 0.267, 1.0),
		},
		"fog_tint": Color(0.565, 0.606, 0.342, 1.0),
		"night_fog_tint": Color(0.403, 0.435, 0.225, 1.0),
		"light_energy": .8,
		"fog_density": 0.03,
		"morning_fog": false,
		"evening_fog": false,
		"night_fog": .04,
	},
}
var world_generator = {
	"Grassy Plains": [
		{"type": "Grass", "priority": 8},
		{"type": "Forest", "priority": 3},
		{"type": "Mountain", "priority": 1},
	],
	"Forest Peaks": [
		{"type": "Grass", "priority": 4},
		{"type": "Forest", "priority": 6},
		{"type": "Mountain", "priority": 1},
	],
	"Stone Peaks": [
		{"type": "Forest", "priority": 2},
		{"type": "Grass", "priority": 2},
		{"type": "Mountain", "priority": 5},
		{"type": "Cobble", "priority": 3},
	],
	"Stone Plateaus": [
		{"type": "Forest", "priority": 2},
		{"type": "Grass", "priority": 2},
		{"type": "Mountain", "priority": 2},
		{"type": "Cobble", "priority": 3},
	],
	"Arid Desert": [
		{"type": "Sand", "priority": 6},
		{"type": "Sediment", "priority": 2},
		{"type": "Lush Sand", "priority": 5}
	],
	"Salt Flats": [
		{"type": "Salt", "priority": 1},
	],
	"Volcanic Peaks": [
		{"type": "Volcanic Rock", "priority": 4},
		{"type": "Ash", "priority": 8},
	],
	"Bog Swamps": [
		{"type": "Forest", "priority": 8},
		{"type": "Grass", "priority": 4},
		{"type": "Mountain", "priority": 1},
	],
}
var rng
var HumidityWeight = 1
var ElevationWeight = 1
func _init(requestedSeed : int):
	rng = RandomNumberGenerator.new()
	rng.seed = requestedSeed
func generateBiome(_x, _z, humidity, elevation):
		var biome_distances = []
		var distance
		for biome_name in biomes:
			var biome = biomes[biome_name]
			var dh = humidity - biome.humidity
			var de = elevation - biome.elevation
			# Euclidean distance
			distance = sqrt(pow(dh * HumidityWeight, 2) + pow(de * ElevationWeight, 2))
			biome_distances.append({
				"name": biome_name,
				"biome": biome,
				"distance": distance
			})
		biome_distances.sort_custom(func(a, b): return a.distance < b.distance)
		var b1 = biome_distances[0].biome
		b1.name = biome_distances[0].name
		return b1
func generateTile(biome):
	var worldPool = world_generator[biome.name]
	var totalPriority: int = 0
	for hextype in worldPool:
		totalPriority += hextype.priority
			
	if (totalPriority <=0): return null
	var num = rng.randi_range(1, totalPriority)
	for tileObj in worldPool:
		var priority = tileObj["priority"]
		if (num <= priority):
			var tile = textures[tileObj["type"]]
			var hex = {
				"type": tileObj["type"],
				"biome": biome,
				"attributes": tile
			}
			return hex
		else:
			num -= priority
func getTerrainMultiplier(elevation, humidity):
	var sharpness = 20.0 # controls how “tight” biome regions are
	var weights = {}
	var total_weight = 0.0
	# STEP 1: compute weight for EVERY biome
	for biome_name in biomes:
		var biome = biomes[biome_name]
		var dh = humidity - biome.humidity
		var de = elevation - biome.elevation
		# squared distance (faster than sqrt, same behavior for weighting)
		var d2 = (dh * HumidityWeight) * (dh * HumidityWeight) + \
				 (de * ElevationWeight) * (de * ElevationWeight)
		# continuous influence function
		var w = exp(-d2 * sharpness)
		weights[biome_name] = w
		total_weight += w
	# STEP 2: normalize weights + blend
	var terrainMultiplier = 0.0
	for biome_name in weights:
		var biome = biomes[biome_name]
		var w = weights[biome_name] / total_weight
		
		terrainMultiplier += biome.terrainMultiplier * w
	return terrainMultiplier
