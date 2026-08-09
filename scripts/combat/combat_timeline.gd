extends RefCounted

var entries: Array[Dictionary] = []
var next_serial := 0


func schedule(delay: float, callback: Callable, tag := "") -> void:
	if not callback.is_valid():
		return
	if delay <= 0.0:
		callback.call()
		return
	entries.append({
		"remaining": delay,
		"callback": callback,
		"tag": tag,
		"serial": next_serial,
	})
	next_serial += 1


func advance(delta: float) -> void:
	if delta <= 0.0 or entries.is_empty():
		return
	var due: Array[Dictionary] = []
	for index in range(entries.size() - 1, -1, -1):
		var entry := entries[index]
		entry["remaining"] = float(entry["remaining"]) - delta
		if float(entry["remaining"]) <= 0.0001:
			due.append(entry)
			entries.remove_at(index)
	due.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left["serial"]) < int(right["serial"]))
	for entry in due:
		var callback: Callable = entry["callback"]
		if callback.is_valid():
			callback.call()


func clear() -> void:
	entries.clear()


func pending_count(tag := "") -> int:
	if tag.is_empty():
		return entries.size()
	var count := 0
	for entry in entries:
		count += int(str(entry["tag"]) == tag)
	return count
