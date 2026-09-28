class_name VoxelMeshCache
extends Resource
## Mallas de un modelo voxel ya construidas, guardadas en disco (user://voxcache/) para no
## reconstruirlas desde el JSON en cada arranque: una cabaña de 100.000 voxels tarda ~1,7 s
## en construirse y ~20 ms en cargarse de aquí.

@export var pivots := {}
@export var parents := {}                     ## parte -> parte de la que cuelga (antebrazo -> brazo)
@export var voxel_size := 0.03125
@export var roughness := 0.38
@export var specular := 0.6
@export var parts := PackedStringArray()      ## parte de cada capa
@export var layer_pivots: Array[Vector3] = []
@export var glows: Array[bool] = []
@export var meshes: Array[ArrayMesh] = []
