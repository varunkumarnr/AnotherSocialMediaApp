extends Node 


enum WINFACTOR { POINTS_IN_TIME, NO_FAIL, TIME_LIMIT, NO_FAIL_TIME_TIMIT , COMPLETE }

enum DIFFICULTY {EASY, MEDIUM, HARD, VERY_HARD, EXTREMLY_HARD, IMPOSSIBLE}

enum CATEGORY {PUZZLE, PLATFORMER, LUCK, TROLLY}

class MiniGameConfig: 
    var id: String
    var scene_path: String
    var display_name: String 
    var time_limit: float
    var is_timed: bool
    var win_factor: WINFACTOR
    var success_condition: float
    var difficulty: DIFFICULTY
    var category: CATEGORY
    var hidden_weight: float
    var music_track: int = -1

    func _init(_id:String, _scene_path: String, _display_name: String, _time_limit: float, _is_timed: bool, _win_factor: WINFACTOR, _success_condition: float, _difficulty: DIFFICULTY, _category: CATEGORY, _hidden_weight: float, _music_track: int = -1):
        id= _id
        scene_path=_scene_path
        display_name=_display_name
        time_limit=_time_limit
        is_timed=_is_timed
        win_factor=_win_factor
        success_condition=_success_condition
        difficulty=_difficulty
        category=_category
        hidden_weight=_hidden_weight
        music_track=_music_track

var mini_games :Dictionary =  {}

func _ready() -> void:
    register_all_games()
    print("Game Data initialized")

func register_all_games():
    register_game(MiniGameConfig.new(
        "music_sequence",
        "res://scenes/games/skillGames/numbersequence.tscn", 
        "Flappy Guy", 
        90.0,
        true, 
        WINFACTOR.TIME_LIMIT, 
        12.0, 
        DIFFICULTY.VERY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "checkbox",
        "res://scenes/games/trollyGames/checkbox.tscn", 
        "CheckBox", 
        60.0,
        true, 
        WINFACTOR.TIME_LIMIT, 
        5.0, 
        DIFFICULTY.HARD, 
        CATEGORY.PLATFORMER, 
        10.0,
        -1
    ))
    
    register_game(MiniGameConfig.new(
        "virus_game",
        "res://scenes/games/shooting/pulsingShooter.tscn", 
        "Virus Game", 
        1000.0,
        true, 
        WINFACTOR.TIME_LIMIT, 
        10.0, 
        DIFFICULTY.EASY, 
        CATEGORY.TROLLY, 
        10.0,
        -1
    ))
    
    register_game(MiniGameConfig.new(
        "checkbox",
        "res://scenes/games/trollyGames/checkbox.tscn", 
        "CheckBox", 
        60.0,
        true, 
        WINFACTOR.TIME_LIMIT, 
        5.0, 
        DIFFICULTY.HARD, 
        CATEGORY.PLATFORMER, 
        10.0,
        -1
    ))
    register_game(MiniGameConfig.new(
        "shellgame",
        "res://scenes/games/trollyGames/shellgame.tscn", 
        "Shell Game", 
        60.0,
        true, 
        WINFACTOR.NO_FAIL_TIME_TIMIT, 
        10.0, 
        DIFFICULTY.EASY, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "whack_a_mole",
        "res://scenes/games/trollyGames/wack_a_mole.tscn", 
        "Whack a Mole", 
        60.0,
        true, 
        WINFACTOR.NO_FAIL_TIME_TIMIT, 
        8.0, 
        DIFFICULTY.HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "invincible_agree",
        "res://scenes/games/trollyGames/invincibleAgree.tscn", 
        "Invinsible Agree", 
        00.0,
        false, 
        WINFACTOR.NO_FAIL, 
        8.0, 
        DIFFICULTY.VERY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0, 
        AudioManager.MUSICTRACK.TIME_TICKING
    ))
    register_game(MiniGameConfig.new(
        "reaction_time",
        "res://scenes/games/skillGames/reaction_time.tscn", 
        "Reaction Time", 
        90.0,
        true, 
        WINFACTOR.TIME_LIMIT, 
        5.0, 
        DIFFICULTY.EXTREMLY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "coin_toss",
        "res://scenes/games/luckgames/cointoss.tscn", 
        "Coin Toss", 
        0.0,
        false, 
        WINFACTOR.NO_FAIL, 
        12.0, 
        DIFFICULTY.VERY_HARD, 
        CATEGORY.LUCK, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "simon_says",
        "res://scenes/games/skillGames/simonsays.tscn", 
        "Simon Says", 
        0.0,
        false, 
        WINFACTOR.NO_FAIL, 
        0.0, 
        DIFFICULTY.HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_8",
        "res://scenes/games/quizGames/popular_opinon.tscn", 
        "Flappy Guy", 
        120.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        12.0, 
        DIFFICULTY.HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_9",
        "res://scenes/games/skillGames/slots.tscn", 
        "Flappy Guy", 
        90.0,
        true, 
        WINFACTOR.TIME_LIMIT, 
        12.0, 
        DIFFICULTY.VERY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_10",
        "res://scenes/games/flappyGuy/flappy_guy.tscn", 
        "Flappy Guy", 
        120.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        15.0, 
        DIFFICULTY.VERY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_11",
        "res://scenes/games/trollyGames/checkbox.tscn", 
        "Flappy Guy", 
        120.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        10.0, 
        DIFFICULTY.EXTREMLY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_12",
        "res://scenes/games/flappyGuy/flappy_guy.tscn", 
        "Flappy Guy", 
        120.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        20.0, 
        DIFFICULTY.VERY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_13",
        "res://scenes/games/flappyGuy/flappy_guy_reverse.tscn", 
        "Flappy Guy", 
        180.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        15.0, 
        DIFFICULTY.EXTREMLY_HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_14",
        "res://scenes/games/flappyGuy/flappy_guy.tscn", 
        "Flappy Guy", 
        300.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        30.0, 
        DIFFICULTY.EASY, 
        CATEGORY.PLATFORMER, 
        10.0
    ))
    register_game(MiniGameConfig.new(
        "flappy_guy_normal_15",
        "res://scenes/games/flappyGuy/flappy_guy_reverse.tscn", 
        "Flappy Guy", 
        500.0,
        true, 
        WINFACTOR.POINTS_IN_TIME, 
        30.0, 
        DIFFICULTY.HARD, 
        CATEGORY.PLATFORMER, 
        10.0
    ))

    # TODO: ADD remaning



func register_game(gameConfig: MiniGameConfig):
    mini_games[gameConfig.id] = gameConfig

func get_game_config(id: String) -> MiniGameConfig: 
    if mini_games.has(id): 
        return mini_games.get(id) 
    return null

# func get_games(count: int) -> Array: 
#     var available = []
#     for game_id in mini_games: 
#         available.append(game_id)
#     return available.slice(0, min(count , available.size()))

func get_random_games(count: int, exclude: Array =[]) -> Array: 
    var available = []
    for game_id in mini_games: 
        if not exclude.has(game_id):
            available.append(game_id)
    # available.shuffle()
    return available.slice(0, min(count,available.size()))

