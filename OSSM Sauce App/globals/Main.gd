extends Node

var node: Control

func _get(property: StringName) -> Variant:
    return node.get(property)