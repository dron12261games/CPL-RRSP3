extends Control

@export var checkedIcon : Texture2D
@export var uncheckedIcon : Texture2D
@export var niceIcon : Texture2D
@export var errorWindow : ColorRect
@export var errorList : ItemList

@export_group("Music")
@export var musicPlayer : AudioStreamPlayer
@export var musicVolumeSlider : HSlider
var musicMute = false
var musicTempMute = false

var launcherPath = OS.get_executable_path().get_base_dir()

@export_group("Menu Buttons")
@export var welcomeBtn : Button
@export var settingsBtn : Button
@export var mapsListBtn : Button
@export var aboutBtn : Button
@export var menuBtnGroup : ButtonGroup

@export_group("Menu Tabs")
@export var tabsContainer : TabContainer
@export var welcomeTab : TabBar
@export var settingsTab : TabBar
@export var mapsListTab : TabBar
@export var aboutTab : TabBar

@export_group("Music Button")
@export var musicBtn : Button
@export var musicOnIcon : CompressedTexture2D
@export var musicOffIcon : CompressedTexture2D

@export_group("Welcome Screen")
@export var startBtn : Button
@export var versionLabel : Label

@export_group("Settings Screen")
@export var DoomUChk : CheckBox
@export var Doom2Chk : CheckBox
@export var PlutoniaChk : CheckBox
@export var TNTChk : CheckBox
@export var HereticChk : CheckBox
@export var HexenChk : CheckBox

@export_group("Maps List Screen")
@export var mappersList : OptionButton
@export var mapsList : ItemList
@export var screenshot1Map : TextureRect
@export var screenshot2Map : TextureRect
@export var txtField : CodeEdit
@export var playBtn : Button
@export var sourcePortList : OptionButton
@export var mapNameField : Label
@export var mapHoursField : Label
@export var mapIWADFields : Label
@export var mapFormatFields : Label
@export var checkCompleteBtn : Button
@export var tutorialScreen : ColorRect
@export var liteVerScreen : ColorRect
@export var playDefaultBtn : Button
@export var playLiteBtn : Button
@export var playCancelBtn : Button
@export var mapperScreen : ColorRect
@export var mapperName : Label
@export var mapperAltName : Label
@export var mapperStatus : Label
@export var mapperInfo : RichTextLabel
@export var mapperAvatar : TextureRect

@export_group("About Screen")
@export var rrsp1Btn : Button
@export var rrsp2Btn : Button
@export var gfd12261Btn : Button


class Mapper:
	var id : int
	var name : String
	var altName : String
	var status : String
	var mapperInfo : String
	var avatarPath : String
	var avatar : Texture2D
	var maps : Array
	var completed : bool

class Map:
	var id : int
	var name : String
	var sourcePorts : Array
	var recommendedSourcePort : SourcePort
	var mapPath : String
	var txtPath : String
	var txtBody : String
	var screen1Path : String
	var screen1 : Texture2D
	var screen2Path : String
	var screen2 : Texture2D
	var addWadPath : String
	var warpMap : String
	var complevel : int
	var iwad : int
	var hours : float
	var hasLiteVersion : bool
	var completed : bool

class SourcePort:
	var id : int
	var name : String
	var path : String
	var exeFile : String
	var addConfig : String

var mappersArray : Array
var mapsArray : Array
var sourcePortsArray : Array
var iwadList : Array = ["Ultimate Doom", "Doom 2", "Plutonia", "TNT", "Heretic", "Hexen"]
var formatsList : Dictionary = {
	403: "Eternity UDMF",
	281: "ZDoom UDMF",
	228: "GZDoom UDMF",
	2: "Limit-Removing",
	3: "Limit-Removing",
	4: "Limit-Removing",
	9: "Boom",
	11: "MBF",
	21: "MBF21"
}
var iwadCkecks : Array = []
var iwadsNames : Array = [ "DOOM.WAD", "DOOM2.WAD", "PLUTONIA.WAD", "TNT.WAD", "HERETIC.WAD", "HEXEN.WAD"]

var selectedMapper : Mapper
var selectedMapperIndex : int
var selectedMap : Map
var selectedMapIndex : int
var selectedSourcePort : SourcePort
var selectedSourcePortIndex : int

var lastRunnedPort = 0
var errorFound = false

var dataFile : String
var dataJson : Dictionary

func _ready():
	var monitorSize = DisplayServer.screen_get_usable_rect().size
	var window : Window = get_tree().root.get_window()
	if monitorSize.y - 10 < window.size.y:
		window.size.y = monitorSize.y - 10
	
	window.position.y = monitorSize.y/2 - window.size.y/2 + 15
	
	if !DirAccess.dir_exists_absolute(launcherPath + "/IWADs/"):
		DirAccess.make_dir_absolute(launcherPath + "/IWADs/")
	
	iwadCkecks.append(DoomUChk)
	iwadCkecks.append(Doom2Chk)
	iwadCkecks.append(PlutoniaChk)
	iwadCkecks.append(TNTChk)
	iwadCkecks.append(HereticChk)
	iwadCkecks.append(HexenChk)
	
	musicVolumeSlider.value = musicPlayer.volume_db
	
	errorList.clear()
	checkError("/rrsp3.dat")
	if errorFound:
		return
	
	dataFile = FileAccess.get_file_as_string(launcherPath + "/rrsp3.dat")
	var tempJSON = JSON.new()
	var errorJSON = tempJSON.parse(dataFile)
	if errorJSON == ERR_PARSE_ERROR:
		errorWindow.visible = true
		errorList.add_item("/rrsp3.dat")
		errorFound = true
		return
	
	dataJson = JSON.parse_string(dataFile)
	
	versionLabel.text = dataJson["Version"]
	TranslationServer.set_locale(dataJson["Language"])
	_on_music_button_toggled(dataJson["MusicMute"])
	_on_music_volume_slider_value_changed(dataJson["MusicVolume"])
	
	var mappersData : Array = dataJson["Mappers"]
	var mapsData : Array = dataJson["Maps"]
	var sourcePortsData : Array = dataJson["SourcePorts"]
	
	for sourcePort in sourcePortsData:
		var newSourcePort = SourcePort.new()
		newSourcePort.id = sourcePort["id"]
		newSourcePort.name = sourcePort["name"]
		checkError(sourcePort["path"] + sourcePort["exeFile"])
		newSourcePort.path = sourcePort["path"]
		newSourcePort.exeFile = sourcePort["exeFile"]
		checkError(sourcePort["addConfig"])
		newSourcePort.addConfig = sourcePort["addConfig"]
		sourcePortsArray.append(newSourcePort)
	
	for map in mapsData:
		var newMap = Map.new()
		newMap.id = map["id"]
		newMap.name = map["name"]
		for i in map["sourcePorts"]:
			newMap.sourcePorts.append(sourcePortsArray[i - 1])
		newMap.recommendedSourcePort = sourcePortsArray[map["recommendedSourcePort"] - 1]
		checkError(map["mapPath"])
		newMap.mapPath = map["mapPath"]
		checkError(map["txtPath"])
		newMap.txtPath = map["txtPath"]
		checkError(map["screen1Path"])
		newMap.screen1Path = map["screen1Path"]
		checkError(map["screen2Path"])
		newMap.screen2Path = map["screen2Path"]
		if !errorFound:
			if newMap.txtPath != "":
				newMap.txtBody = FileAccess.get_file_as_string(launcherPath + newMap.txtPath)
			if newMap.screen1Path != "":
				newMap.screen1 = ImageTexture.create_from_image(Image.load_from_file(launcherPath + newMap.screen1Path))
			if newMap.screen2Path != "":
				newMap.screen2 = ImageTexture.create_from_image(Image.load_from_file(launcherPath + newMap.screen2Path))
		checkError(map["addWadPath"])
		newMap.addWadPath = map["addWadPath"]
		newMap.warpMap = map["warpMap"]
		newMap.complevel = map["complevel"]
		newMap.iwad = map["iwad"]
		newMap.hours = map["hours"]
		newMap.hasLiteVersion = map["hasLiteVersion"]
		newMap.completed = map["completed"]
		mapsArray.append(newMap)
	
	for mapper in mappersData:
		var newMapper = Mapper.new()
		newMapper.id = mapper["id"]
		newMapper.name = mapper["name"]
		newMapper.altName = mapper["altName"]
		newMapper.status = mapper["status"]
		newMapper.mapperInfo = mapper["mapperInfo"]
		checkError(mapper["avatarPath"])
		newMapper.avatarPath = mapper["avatarPath"]
		if !errorFound:
			if newMapper.avatarPath != "":
				newMapper.avatar = ImageTexture.create_from_image(Image.load_from_file(launcherPath + newMapper.avatarPath))
		newMapper.completed = true
		for i in mapper["maps"]:
			newMapper.maps.append(mapsArray[i - 1])
			if !mapsArray[i - 1].completed:
				newMapper.completed = false
		
		mappersArray.append(newMapper)
	
	if errorFound:
		return
	
	mappersList.clear()
	for i in mappersArray:
		mappersList.add_item(i.name)
		if i.completed:
			mappersList.set_item_icon(mappersList.item_count - 1, checkedIcon)
		else:
			mappersList.set_item_icon(mappersList.item_count - 1, uncheckedIcon)
	mappersList.select(0)
	_on_mappers_list_item_selected(0)
	
	if dataJson["firstLaunch"]:
		dataJson["firstLaunch"] = false
		tutorialScreen.visible = true
		saveProgress()

func _process(delta):
	var checkDoom = FileAccess.file_exists(launcherPath + "\\IWADs\\DOOM.WAD")
	if checkDoom:
		iwadsNames[0] = "DOOM.WAD"
	var checkDoomU = FileAccess.file_exists(launcherPath + "\\IWADs\\DOOMU.WAD")
	if checkDoomU:
		iwadsNames[0] = "DOOMU.WAD"
	var checkDoom1 = FileAccess.file_exists(launcherPath + "\\IWADs\\DOOM1.WAD")
	if checkDoom1:
		iwadsNames[0] = "DOOM1.WAD"
	var isDoomU = checkDoom || checkDoomU || checkDoom1
	DoomUChk.button_pressed = isDoomU
	var isDoom2 = FileAccess.file_exists(launcherPath + "\\IWADs\\DOOM2.WAD")
	Doom2Chk.button_pressed = isDoom2
	var isPlutonia = FileAccess.file_exists(launcherPath + "\\IWADs\\PLUTONIA.WAD")
	PlutoniaChk.button_pressed = isPlutonia
	var isTNT = FileAccess.file_exists(launcherPath + "\\IWADs\\TNT.WAD")
	TNTChk.button_pressed = isTNT
	var isHeretic = FileAccess.file_exists(launcherPath + "\\IWADs\\HERETIC.WAD")
	HereticChk.button_pressed = isHeretic
	var isHexen = FileAccess.file_exists(launcherPath + "\\IWADs\\HEXEN.WAD")
	HexenChk.button_pressed = isHexen
	
	if selectedMap != null:
		if iwadCkecks[selectedMap.iwad - 1].button_pressed:
			playBtn.disabled = false
			playBtn.add_theme_color_override("font_color", Color.LIME_GREEN)
			playBtn.add_theme_color_override("font_disabled_color", Color.LIME_GREEN)
			playBtn.tooltip_text = ""
		else:
			playBtn.disabled = true
			playBtn.add_theme_color_override("font_color", Color.INDIAN_RED)
			playBtn.add_theme_color_override("font_disabled_color", Color.INDIAN_RED)
			playBtn.tooltip_text = tr("MISS_IWAD")
		

func _on_welcome_btn_toggled(toggled_on):
	tabsContainer.current_tab = 0

func _on_settings_btn_toggled(toggled_on):
	tabsContainer.current_tab = 1

func _on_maps_list_btn_toggled(toggled_on):
	tabsContainer.current_tab = 2

func _on_about_btn_toggled(toggled_on):
	tabsContainer.current_tab = 3

func _on_music_button_toggled(toggled_on):
	if (musicBtn.button_pressed):
		musicBtn.icon = musicOffIcon
		musicMute = true
		musicPlayer.volume_db = -80
	else:
		musicBtn.icon = musicOnIcon
		musicMute = false
		musicPlayer.volume_db = musicVolumeSlider.value
	
	saveProgress()

func _on_start_button_pressed():
	settingsBtn.button_pressed = true
	tabsContainer.current_tab = 1

func _on_music_volume_slider_value_changed(value):
	if (!musicMute):
		musicPlayer.volume_db = musicVolumeSlider.value
		
		if (musicVolumeSlider.value == musicVolumeSlider.min_value):
			musicPlayer.volume_db = -80
			musicBtn.icon = musicOffIcon
		else:
			musicBtn.icon = musicOnIcon

func _on_iwads_button_pressed():
	OS.shell_open(launcherPath + "\\IWADs")

func _on_bg_music_finished():
	musicPlayer.play()

func _on_rrsp_1_btn_pressed():
	OS.shell_open("https://www.doomworld.com/forum/topic/141189-russian-random-speedmap-pack-1-18-totally-different-maps/")

func _on_rrsp_2_btn_pressed():
	OS.shell_open("https://www.doomworld.com/forum/topic/142098-russian-random-speedmap-pack-2-23-new-interesting-maps-happy-birthday-doom/")

func _on_gfd_12261_btn_pressed():
	OS.shell_open("https://www.doomworld.com/forum/topic/141703-mbf21-gift-for-dron12261-a-collective-megawad/")

func _on_mappers_list_item_selected(index, preselectMap = 0):
	selectedMapper = mappersArray[index]
	selectedMapperIndex = index
	
	mapsList.clear()
	var notCompleted = false
	for i in mappersArray[mappersList.get_selected_id()].maps:
		var mapIcon : Texture2D
		if i.completed:
			mapIcon = checkedIcon
		else:
			mapIcon = uncheckedIcon
			notCompleted = true
		mapsList.add_item(i.name, mapIcon)
	
	if notCompleted:
		mappersList.set_item_icon(selectedMapperIndex, uncheckedIcon)
		selectedMapper.completed = false
	else:
		mappersList.set_item_icon(selectedMapperIndex, checkedIcon)
		selectedMapper.completed = true
	
	mapperAvatar.texture = selectedMapper.avatar
	mapperName.text = selectedMapper.name
	mapperAltName.text = selectedMapper.altName
	mapperStatus.text = tr(selectedMapper.status)
	mapperInfo.text = tr(selectedMapper.mapperInfo)
	
	mapsList.select(preselectMap)
	_on_maps_list_item_selected(preselectMap)

func _on_maps_list_item_selected(index):
	selectedMap = mappersArray[mappersList.get_selected_id()].maps[index]
	selectedMapIndex = index
	
	var sourcePortSelect = 0
	
	sourcePortList.clear()
	for i in selectedMap.sourcePorts:
		sourcePortList.add_item(i.name)
		if i.id == selectedMap.recommendedSourcePort.id:
			sourcePortSelect = sourcePortList.item_count - 1
			sourcePortList.selected = sourcePortSelect
			sourcePortList.set_item_icon(sourcePortSelect, niceIcon)
	
	mapNameField.text = selectedMap.name
	mapIWADFields.text = iwadList[selectedMap.iwad - 1]
	mapHoursField.text = tr("HOURS_TITLE") + ": " + str(selectedMap.hours)
	mapFormatFields.text = formatsList[selectedMap.complevel]
	checkCompleteBtn.button_pressed = selectedMap.completed
	if selectedMap.sourcePorts.has(sourcePortsArray[5]):
		mapFormatFields.text = "Vanilla"

	txtField.text = selectedMap.txtBody
	screenshot1Map.texture = selectedMap.screen1
	screenshot2Map.texture = selectedMap.screen2
	
	_on_check_complete_toggled()
	_on_sourceport_list_item_selected(sourcePortSelect)

func _on_check_complete_toggled(toggled_on = null):
	if checkCompleteBtn.button_pressed:
		checkCompleteBtn.icon = checkedIcon
		selectedMap.completed = true
	else:
		checkCompleteBtn.icon = uncheckedIcon
		selectedMap.completed = false
	mapsList.set_item_icon(selectedMapIndex, checkCompleteBtn.icon)
	
	var notCompleted = false
	for i in mappersArray[mappersList.get_selected_id()].maps:
		if !i.completed:
			notCompleted = true
	
	if notCompleted:
		mappersList.set_item_icon(selectedMapperIndex, uncheckedIcon)
		selectedMapper.completed = false
	else:
		mappersList.set_item_icon(selectedMapperIndex, checkedIcon)
		selectedMapper.completed = true
	
	saveProgress()

func _on_russian_btn_pressed():
	TranslationServer.set_locale("ru")
	if selectedMap != null:
		mapHoursField.text = tr("HOURS_TITLE") + ": " + str(selectedMap.hours)
		
		if !iwadCkecks[selectedMap.iwad - 1].button_pressed:
			playBtn.tooltip_text = tr("MISS_IWAD")
	
	if selectedMapper != null:
		mapperStatus.text = tr(selectedMapper.status)
		mapperInfo.text = tr(selectedMapper.mapperInfo)
	
	saveProgress()

func _on_english_btn_pressed():
	TranslationServer.set_locale("en")
	if selectedMap != null:
		mapHoursField.text = tr("HOURS_TITLE") + ": " + str(selectedMap.hours)
		
		if !iwadCkecks[selectedMap.iwad - 1].button_pressed:
			playBtn.tooltip_text = tr("MISS_IWAD")
	
	if selectedMapper != null:
		mapperStatus.text = tr(selectedMapper.status)
		mapperInfo.text = tr(selectedMapper.mapperInfo)
	
	saveProgress()

func _on_end_tutorial_pressed():
	tutorialScreen.visible = false

func _on_help_pressed():
	tutorialScreen.visible = true

func _on_sourceport_list_item_selected(index):
	selectedSourcePort = selectedMap.sourcePorts[index]
	selectedSourcePortIndex = index

func _on_play_btn_pressed():
	if selectedMap.hasLiteVersion && selectedMap.addWadPath != "":
		liteVerScreen.visible = true
	else:
		run_port(false)
	
func run_port(liteVersion : bool):
	get_tree().root.mode = Window.MODE_MINIMIZED
	musicTempMute = true
	musicPlayer.volume_db = -80
	
	var parameters = "" 
	
	if liteVersion:
		parameters = "start /D \"" + launcherPath + selectedSourcePort.path + "\" " + selectedSourcePort.exeFile + " -iwad \"" + launcherPath + "/IWADs/" + iwadsNames[selectedMap.iwad - 1] + "\" -file \"" + launcherPath + selectedMap.addWadPath + "\""
	else:
		parameters = "start /D \"" + launcherPath + selectedSourcePort.path + "\" " + selectedSourcePort.exeFile + " -iwad \"" + launcherPath + "/IWADs/" + iwadsNames[selectedMap.iwad - 1] + "\" -file \"" + launcherPath + selectedMap.mapPath + "\""
	
	if selectedMap.addWadPath != "" && selectedSourcePort.id != 6 && !selectedMap.hasLiteVersion:
		if selectedMap.addWadPath[0] == '-':
			parameters += " " + selectedMap.addWadPath
		else:
			parameters += " \"" + launcherPath + selectedMap.addWadPath + "\""
	
	if selectedMap.warpMap != "":
		parameters += " -warp " + selectedMap.warpMap
	
	var thread = Thread.new()
	thread.start(startPort.bind(parameters))

func startPort(parameters : String):
	var output = []
	
	var arrayArgs = ["/C", parameters]
	var args = PackedStringArray(arrayArgs)
	var portString = "CMD.exe"
	lastRunnedPort = OS.execute(portString, args)
	
	print(output)
	print(lastRunnedPort)

func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		if musicTempMute:
			musicTempMute = false
			if !musicMute:
				musicPlayer.volume_db = musicVolumeSlider.value
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		pass

func _on_default_play_pressed():
	liteVerScreen.visible = false
	run_port(false)

func _on_lite_play_pressed():
	liteVerScreen.visible = false
	run_port(true)

func _on_cancel_play_pressed():
	liteVerScreen.visible = false

func checkError(path : String):
	if !FileAccess.file_exists(launcherPath + path) && path != "" && path[0] != '-':
		errorWindow.visible = true
		errorList.add_item(path)
		errorFound = true

func saveProgress():
	dataJson["Language"] = TranslationServer.get_locale()
	dataJson["MusicMute"] = musicMute
	dataJson["MusicVolume"] = musicVolumeSlider.value
	
	for i in range(len(mapsArray)):
		dataJson["Maps"][i]["completed"] = mapsArray[i].completed
	
	var rrsp3dat = FileAccess.open(launcherPath + "/rrsp3.dat", FileAccess.WRITE)
	rrsp3dat.store_string(JSON.stringify(dataJson, "    "))
	rrsp3dat.close()

func _on_mapper_ok_pressed():
	mapperScreen.visible = false

func _on_mapper_info_pressed():
	mapperScreen.visible = true

func _on_mapper_text_meta_clicked(meta):
	OS.shell_open(str(meta))

func _on_button_pressed():
	OS.shell_open("https://rrsp3.github.io")
