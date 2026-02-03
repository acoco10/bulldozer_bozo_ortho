extends Node

var entries : Array[String]
var entry_index: int 
@onready var text_label = $Label

func parse_obsidian_file(file_path: String) -> Array[String]:
	var entries: Array[String] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to open file: " + file_path)
		return entries
	
	var current_entry = ""
	
	while not file.eof_reached():
		var line = file.get_line()
		
		# Check if line starts with "- " (new entry)
		if line.begins_with("- "):
			# Save previous entry if it exists
			if current_entry != "":
				entries.append(current_entry.strip_edges())
			
			# Start new entry (remove the "- " prefix)
			current_entry = line.substr(2)
		else:
			# Continue current entry (could be empty line or continuation)
			if current_entry != "":
				current_entry += "\n" + line
	
	# Don't forget the last entry
	if current_entry != "":
		entries.append(current_entry.strip_edges())
	
	file.close()
	return entries


# Example usage
func _ready():
	entries = parse_obsidian_file("res://clone_memories.md")
	for i in range(entries.size()):
		print("Entry %d: %s" % [i, entries[i]])

func on_enter():
	text_label.text = entries[entry_index]
	entry_index+=1 
	
