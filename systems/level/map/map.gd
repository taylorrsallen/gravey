class_name Map extends Node3D

@onready var wave_spawners: Node = $WaveSpawners
@onready var spawners: Node = $Spawners
@onready var landing_zones: Node3D = $LandingZones

@onready var power_stations: PowerStations = $PowerStations
@onready var powered_devices: Node = $PoweredDevices

@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D
