package gamejolt;

import flixel.FlxG;
import gamejolt.formats.*;
import haxe.Http;
import haxe.Json;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;

/**
 * A completely original GameJolt Client made by GamerPablito, using Haxe Crypto Encripting and Http tools
 * to gather info about the GameJolt API with ease
 * 
 * Originally made for the game Friday Night Funkin', but it can also be used for every game made with HaxeFlixel
 * 
 * No extra extensions required (except the basic Flixel and Haxe ones)
 */
class GJClient
{
    // Private vars
    static var printPrefix:String = "GameJolt Client:"; // Command Prefix

    /*
        ----------------------------------------------------------------
        -------------> GUI = GameJolt User Information <------------------
        --> EVERY COMMAND HERE WILL WORK ONLY IF GUI PARAMETERS EXIST!! <--
        ----------------------------------------------------------------
    */

    /**
     * It tells you if you're actually logged in or not (Read Only, don't change it!)
     */
    public static var logged:Bool = false; // Logged in or not

    /**
     * If `true`, the functions will use `Md5` encriptation for data processing; if `false`, they'll use `Sha1` encriptation instead
     */
    public static var useMd5:Bool = true;

    /**
     * It tells you if you have enabled the auto-login option (Read Only, if you want to change it manually you must use `toggleAutoLogin()`)
     */
    public static var autoLogin:Bool = true;

    /**
     * Sets a new GUI in the database, the Username and the Game Token of the player respectively.
     * This command also closes the previous session (if there was one active) before replace the actual GUI.
     * 
     * If you leave the parameters with an empty string or null, you will be logged out successfully,
     * and you will be able to log in again with other user's GUI.
     * 
     * But if you just wanna log out without erase your GUI from the application, use `logout()` instead.
     * 
     * @param user The Username of the Player.
     * @param token The Game Token of the Player.
     */
    public static function setUserInfo(user:Null<String>, token:Null<String>)
    {

        var temp_user = getUser();
        var temp_token = getToken();

        if (user == '') user = null;
        if (token == '') token = null;

        logout();

        FlxG.save.data.user = user;
        FlxG.save.data.token = token;

        if (hasLoginInfo())
        {
            authUser(
                function (success:Bool)
                {
                    if (success) Sys.println('GUI Parameters Changed: New User -> ${getUser()} | New Token -> ${getToken()}');
                    else
                    {
                        FlxG.save.data.user = temp_user;
                        FlxG.save.data.token = temp_token;
                    }
                },
                function (error:String)
                {
                    FlxG.save.data.user = temp_user;
                    FlxG.save.data.token = temp_token;
                }
            );

            // login();
        }
    }

    /**
     * Run this command to make sure if the actual GUI inserted about a user really exists in GameJolt.
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function authUser(?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('users', 'auth'), onSuccess, onFail);
        if (urlData != null) urlData; else return;
    }

    /**
     * If GUI is already setted up in the application, it throws the user data in a .json format.
     * 
     * Very useful if you want to use the actual user's GUI for some parts of your game.
     * 
     * @see The `formats` folder, to get more info about how formats are setted like.
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     * @return The GUI in .json format (or `null` if any data is available in the application to use yet).
     */
    public static function getUserData(?onSuccess:Bool -> Void, ?onFail:String -> Void):Null<User>
    {
        var urlData = urlResult(urlConstruct('users'), onSuccess, onFail);
        var daFormat:Null<User> = urlData != null && logged ? cast urlData.users[0] : null;
        return daFormat;
    }

    /**
     * Fetches all the trophies available in your game,
     * all the trophies will have their own data formatted in .json.
     * 
     * It also tells you if you've already achieved them or not. Very useful if you're making a trophie screen or smth related.
     * 
     * @see The `formats` folder, to get more info about how formats are setted like.
     * 
     * @param achievedOnes  Whether you want the list to be only with achieved trophies or unachived trophies.
     *                        Leave blank if you want to see all the trophies no matter if they're achieved or not.
     *                        If your game doesn't have any trophies in its GameJolt page,
     *                        or doesn't appear according to what you choose in this variable, the result will be `null`.
     * @param onSuccess     Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail         Put a function with actions here, they'll be processed if an error has ocurred during the process.
     * @return The array with all the Trophies of the game in .json format
     *          (return `null` if there are no Trophies in the game to fetch or if there's no GUI inserted in the application yet).
     */
    public static function getTrophiesList(?achievedOnes:Bool, ?onSuccess:Bool -> Void, ?onFail:String -> Void):Null<Array<Trophie>>
    {
        var daParam:Null<Array<Array<String>>> = achievedOnes != null ? [['achieved', Std.string(achievedOnes)]] : null;
        var urlData = urlResult(urlConstruct('trophies', null, daParam), onSuccess, onFail);
        var daFormat:Null<Array<Trophie>> = urlData != null && logged ? urlData.trophies : null;
        return daFormat;
    }

    /**
     * Gives a trophie from the game to the actual user logged in!
     * 
     * Won't do anything if you're not logged so don't worry, the game won't crash.
     * 
     * @param id The ID of the trophie to achieve (Required)
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function trophieAdd(id:Int, ?onSuccess:Trophie -> Void, ?onFail:String -> Void)
    {
        var daList = getTrophiesList();

        if (logged && daList != null)
        {
            var urlData = urlResult(urlConstruct('trophies', 'add-achieved', [['trophy_id', Std.string(id)]]),
            function (data:Bool)
            {
                for (troph in 0...daList.length)
                {
                    if (daList[troph].id == id)
                    {
                        if (daList[troph].achieved == false)
                        {
                            Sys.println('$printPrefix Trophie "${daList[troph].title}" has been achieved by ${getUser()}!');
                            if (onSuccess != null) onSuccess(daList[troph]);
                        }
                        else Sys.println('$printPrefix Trophie "${daList[troph].title}" is already taken by ${getUser()}!');
                        break;
                    }
                }
            },
            function (error:String)
            {
                Sys.println('$printPrefix The trophie ID "$id" was not found in the game database!');
                if (onFail != null) onFail(error);
            });
            if (urlData != null) urlData; else return;   
        }
    }

    /**
     * Removes a trophie of the game from the actual user logged in. Useful in case it was achieved by cheating or just for test it out!
     * 
     * Won't do anything if you're not logged so don't worry, the game won't crash.
     * 
     * @param id The ID of the trophie to remove (Required)
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function trophieRemove(id:Int, ?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var daList = getTrophiesList();

        if (logged && daList != null)
        {
            var urlData = urlResult(urlConstruct('trophies', 'remove-achieved', [['trophy_id', Std.string(id)]]),
            function (data:Bool)
            {
                for (troph in 0...daList.length)
                {
                    if (daList[troph].id == id)
                    {
                        if (daList[troph].achieved != false)
                        {
                            Sys.println('$printPrefix Trophie "${daList[troph].title}" has been quitted from ${getUser()}!');
                            if (onSuccess != null) onSuccess(data);
                        }
                        else Sys.println('$printPrefix Trophie "${daList[troph].title}" is not taken by ${getUser()} yet!');
                        break;
                    }
                }
            },
            function (error:String)
            {
                Sys.println('$printPrefix The trophie ID "$id" was not found in the game database!');
                if (onFail != null) onFail(error);
            });
            if (urlData != null) urlData; else return;  
        }
    }

    /**
     * Fetches all the scores submitted on a score table in your game,
     * all the scores will have their own data formatted in .json.
     * 
     * You can set if you want to fetch the scores in the table from the actual user or from the game in general!
     * 
     * @see The `formats` folder, to get more info about how formats are setted like.
     * 
     * @param fromUser This is where you can set if you want to fetch scores from the actual logged user only (`true`), or from the game itself (`false`)
     * @param table_id The score Table ID where the scores will be fetched from (if `null`, the scores will be fetched from the "Primary" score table in your game)
     * @param delimiter If you want to fetch the scores that are major or minor than a certain value, set it here, otherwise leave in blank.
     *                    (Note: If you want the scores that are ABOVE the value, set it in POSITIVE, but
     *                     if you want the scores that are BELOW the value, set it in NEGATIVE)
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     * @param limit The number of scores to return. Must be a number between 1 and 100 (Default: 10)
     * @return The array with all the Scores of the game in .json format from the settled score Table ID
     *          (return `null` if there are no Scores in the game to fetch or if there's no GUI inserted in the application yet).
     */
    public static function getScoresList(fromUser:Bool, ?table_id:Int, ?delimiter:Int, ?onSuccess:Bool -> Void, ?onFail:String -> Void, limit:Int = 10):Null<Array<Score>>
    {
        var daParams:Array<Array<String>> = [];

        if (table_id != null) daParams.push(['table_id', Std.string(table_id)]);
        if (delimiter != null) daParams.push([delimiter > 0 ? 'better_than' : 'worse_than', Std.string(Math.abs(delimiter))]);

        if (limit <= 0) limit = 1;
        if (limit > 100) limit = 100;

        if (limit != 10) daParams.push(['limit', Std.string(limit)]);

        var urlData = urlResult(urlConstruct('scores', null, daParams != [] ? daParams : null, fromUser, fromUser), onSuccess, onFail);
        var daFormat:Null<Array<Score>> = urlData != null && logged ? urlData.scores : null;
        return daFormat;
    }

    /**
     * Submits a new score made by the actual logged user to a specified score table in your game!
     * 
     * @param score_content The stringified version of the score. Example: 500 jumps.
     * @param score_value The score itself. Example: 500.
     * @param extraInfo If you want to, you can give extra information about how the score was obtained,
     *                    useful to make game developers know if the player obtained that score legally, but this is completely optional.
     * @param table_id The score table ID where the new score will be submitted to (if `null`, the score will be submitted from the "Primary" score table in your game)
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     *                    It will also contain the score data in order to be used for other creative purposes.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function submitNewScore(score_content:String, score_value:Int, ?extraInfo:String, ?table_id:Int, ?onSuccess:Score -> Void, ?onFail:String -> Void)
    {
        var daParams:Array<Array<String>> = [
            ['score', score_content],
            ['sort', Std.string(score_value)]
        ];

        if (extraInfo != null) daParams.push(['extra_data', extraInfo]);
        if (table_id != null) daParams.push(['table_id', Std.string(table_id)]);

        if (logged)
        {
            var urlData = urlResult(urlConstruct('scores', 'add', daParams),
            function (data:Bool)
            {
                if (logged && data)
                {
                    var exporting:Score =
                    {
                        score: score_content,
                        sort: score_value,
                        extra_data: extraInfo != null ? extraInfo : '',
                        user: getUser(),
                        user_id: getUserData().id
                    };

                    if (onSuccess != null) onSuccess(exporting);
                }
            },
            function (error:String)
            {
                Sys.println('$printPrefix Score submitting failed!');
                if (onFail != null) onFail(error);
            });
            if (urlData != null) urlData; else return;   
        }
    }

    /**
     * Gives you the global rank you got in a certain score table in your game.
     * This is given according to the top score you have in that table.
     * 
     * @param table_id The score sable ID where the rank will be obtained from (if `null`, the rank will be given from the "Primary" score table in your game)
     * @return The global rank obtained from the score table (It returns -1 if the process was failed)
     */
    public static function getGlobalRank(?table_id:Int):Int
    {
        var daTempScore = getScoresList(true, table_id, null, null, null, 1);

        if (logged && daTempScore != null)
        {
            var daParams = [['sort', Std.string(daTempScore[0].sort)]];
            if (table_id != null) daParams.push(['table_id', Std.string(table_id)]);

            var urlData = urlResult(urlConstruct('scores', 'get-rank', daParams, false, false));
            var daRank:Int = urlData != null && logged ? urlData.rank : -1;

            return daRank;
        }

        return -1;
    }

    /**
     * This will open your GameJolt session.
     * 
     * Useful for re-open a session when a new GUI is setted by `setUserInfo()`,
     * or if you closed your session by decision of yours (without erasing your GUI, using `logout()`, otherwise re-use `setUserInfo()`).
     * 
     * (Do not compare with the `initialize()` function)
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully. It will also contain the new data fetched from the new logged user.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function login(?onSuccess:User -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('sessions', 'open'),
        function (data:Bool)
        {
            if (!logged && data) {Sys.println('$printPrefix Logged Successfully! Welcome back ${getUser()}!');}
            if (onSuccess != null && !logged) onSuccess(cast getUserData());
            logged = true;
            autoLogin = autoLoginToggle();
        },
        onFail);
        if (urlData != null && !logged) urlData; else return;
    }

    /**
     * If there's a session active, this command will log it out. Pretty self-explanatory isn't it?
     * 
     * But, if you want to log out, but also want to erase your data from the application,
     * you can use the function `setUserInfo()` with null or empty parameters.
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process. 
     */
    public static function logout(?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('sessions', 'close'),
        function (data:Bool)
        {
            if (logged) Sys.println('$printPrefix Logged out successfully!');
            if (onSuccess != null && logged) onSuccess(data);
            logged = false;
            autoLogin = false;
        },
        onFail);
        if (logged && urlData != null) urlData; else return;
    }

    /**
     * If there's a session active, this function keeps the session active, so it needs to be placed in somewhere it can be executed repeatedly.
     * 
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.  
     */
    public static function pingSession(?onPing:() -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('sessions', 'ping'),
        function (pinged:Bool)
        {
            if (logged && pinged)
            {
                Sys.println('$printPrefix Session pinged!');
                if (onPing != null) onPing();
            }
        },
        function (error:String)
        {
            if (logged)
            {
                Sys.println('$printPrefix Ping failed! You\'ve been disconnected!');
                if (onFail != null) onFail(error);
            }
            logged = false;
        });
        if (logged && urlData != null) urlData; else return;
    }

    /**
     * Tells you if there's a section active or not!
     * 
     * This is mostly used for confirmation, cuz the client works with the
     * variable `logged` instead of this command for a better performance.
     */
    public static function checkSessionActive():Bool
    {
        var result:Bool = false;
        var urlData = urlResult(urlConstruct('sessions', 'check'),
        function (isActive:Bool)
        {
            Sys.println('$printPrefix Is a session active? : $isActive');
            result = logged = isActive;
        });
        if (urlData != null && logged) urlData;
        return result;
    }
    
    /**
     * It toggles the autoLogin option. Pretty self-explanatory, isn't it?
     * @param toggle Want it to be active or not?
     */
    public static function toggleAutoLogin(toggle:Bool) {FlxG.save.data.autoLogin = autoLogin = toggle;}

    /**
     * This initialize the client in general.
     * It opens your session ans sync your data according to the saved GUI data for a better experience when the user comes back.
     * 
     * (Do not compare with the `login()` function)
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully. It will also contain the new data fetched from the new logged user.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function initialize(?onSuccess:User -> Void, ?onFail:() -> Void)
    {
        if (hasLoginInfo() && !logged && autoLogin)
        {
            authUser(function (success:Bool)
            {
                Sys.println('$printPrefix User authenticated successfully!');

                login(function (userData:User)
                {
                    if (onSuccess != null && !logged) onSuccess(userData);
                    logged = true;
                },
                function (error2:String)
                {
                    Sys.println('$printPrefix Login process failed!');
                    if (onFail != null) onFail();
                });
            },
            function (error1:String)
            {
                Sys.println('$printPrefix User authentication failed!');
                if (onFail != null) onFail();
            });
        }
        else return;
    }

    // INTERNAL FUNCTIONS (DON'T ALTER IF YOU DON'T KNOW WHAT YOU'RE DOING!!)

    static function hasLoginInfo():Bool
    {
        return getUser() != null && getToken() != null;
    }

    static function urlConstruct(command:String, ?action:String, ?params:Array<Array<String>>, userAllowed:Bool = true, tokenAllowed:Bool = true):Null<Http>
    {
        if (hasLoginInfo())
        {
            var mainURL:String = "http://api.gamejolt.com/api/game/v1_2/";

            mainURL += command;
            mainURL += '/' + (action != null ? '$action/?' : '?');    
            mainURL += 'game_id=${Std.string(GJKeys.id)}'; // Private Thingie (Fuck you hackers lmao)

            if (userAllowed) mainURL += '&username=${getUser()}';
            if (tokenAllowed) mainURL += '&user_token=${getToken()}';
    
            if (params != null) {for (pars in params) mainURL += '&${pars[0]}=${pars[1]}';}

            var daEncode:String = mainURL + GJKeys.key; // Private thingie (Fuck you hackers lmao)
    
            mainURL += '&signature=${useMd5 ? Md5.encode(daEncode) : Sha1.encode(daEncode)}';
    
            return new Http(mainURL);
        }

        return null;
    }

    static function urlResult(daUrl:Null<Http>, ?onSuccess:Bool -> Void, ?onFail:String -> Void):Null<Dynamic>
    {
        var result:String = '';
        var success:Bool = false;

        if (daUrl != null)
        {
            daUrl.onData = function (data:String)
            {
                result = data;
                success = true;
                if (onSuccess != null) onSuccess(Json.parse(data).response.success == 'true');
            };
            daUrl.onError = function (error:String) {if (onFail != null) onFail(error);};
            daUrl.request(false);
        }

        return success ? Json.parse(result).response : null;
    }

    static function getUser():Null<String> {return FlxG.save.data.user;}
    static function getToken():Null<String> {return FlxG.save.data.token;}
    static function autoLoginToggle():Bool
    {
        if (FlxG.save.data.autoLogin == null) toggleAutoLogin(true);
        return FlxG.save.data.autoLogin;
    }
}