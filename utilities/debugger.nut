/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Debug is now have own class
 *
 */
class Debug
{
	/**
	 * Base of logger
	 * @param ar Array of text
	 * @param num numeric code to log
	 */
	function Say(ar, num) {
		if (AIController.GetSetting("debug_log")) {
			local type = "";
			switch (num) {
				case 0 :
				case 1 :
					type = "Info";
					break;
				case 2 :
					type = "Warning";
					break;
				case 3 :
					type = "Error";
					break;
				default :
					return;
			}
			AILog[type](CLString.Join(ar, " "));
		}
	}

	/**
	 * No other methode found to clear last err
	 */
	function ClearErr() {
		local mode = AITestMode();
		AISign.BuildSign(AIMap.GetTileIndex(2, 2), "debugger");
	}

	/**
	 * Evaluate expression, display message,  detect last error.
	 * usable for in-line debugging Do command
	 * @param exp Expression to be displayed and returned
	 * @param [...] Message to be displayed
	 * @return Value of expression
	 */
	function ResultOf(exp, ...) {
		local txt = [];
		for (local c = 0; c < vargc; c++) txt.push(vargv[c]);
		txt.push("[" + exp + "]");
		txt.push("-> ");
		if (AIError.GetLastError() == AIError.ERR_NONE) {
			txt.push("Good Job ^_^");
			Info(CLString.Join(txt, " "));
		} else {
			txt.push(AIError.GetLastErrorString().slice(4));
			Warn(CLString.Join(txt, " "));
		}
		Debug.ClearErr();
		return exp;
	}

	/**
	 * Evaluate expression, display message,  detect expression.
	 * usable for in-line debugging non Do command
	 * @param exp Expression to be displayed and returned
	 * @param [...] Message to be displayed
	 * @return Value of expression
	 */
	function Echo(exp, ...) {
		local txt = [];
		for (local c = 0; c < vargc; c++) txt.push(vargv[c]);
		txt.push("[" + exp + "]");
		txt.push("-> ");
		if (exp) {
			txt.push("Good Job ^_^");
			Info(CLString.Join(txt, " "));
		} else {
			txt.push("@#$%^&*()?><:; Bad Job!");
			Warn(CLString.Join(txt, " "));
		}
		return exp;
	}

	/**
	  * Wrapper for build sign.
	  * Its used with Game.Settings
	  * @param tile TileID where to build sign
	  * @param txt Text message to be displayed
	  * @return a valid signID if its allowed by game setting
	 */
	function Sign(tile, txt) {
		if (AIController.GetSetting("debug_signs")) {
			local mode = AIExecMode();
			local lst = AISignList();
			lst.Valuate(AISign.GetLocation);
			lst.KeepValue(tile);
			if (lst.Count()) AISign.RemoveSign(lst.Begin());
			return AISign.BuildSign(tile, txt);
		}
		//Debug.Say (["Build sign is disabled"], 1);
		return -1;
	}

	/**
	* Unsign is to easy check wether we have build sign before
	* @param id Suspected signID
	 */
	function UnSign(id) {
		if (AISign.IsValidSign(id)) AISign.RemoveSign(id);
	}

	static function Pause(tile, text) {
		Debug.Sign(tile, (text.len() > 30) ? text.slice(0, 30) : text);
		Error("break on :", CLString.Tile(tile), "due to:", text);
	}

	/**
	* Function to check if the current save table is correct
	* @param table Table to save
	* @param level start level (integer - any). To indicate on what level / depth we are
	* @param id String of start ID, any string.
	*/
	static function CanSave(table, level, id) {
		if ((typeof table == "table") || (typeof table == "array")) {
			foreach(idx, val in table) {
				if (!Debug.CanSave(val, level + 1, idx)) return false;
			}
			return true;
		}

		local alo = (typeof table == "string") || (typeof table == "integer") ||
					(typeof table == "bool") || (typeof table == "null");

		if (!alo) {
			Warn("depth: " , level, " index: ", id, " value: ", table, "is", typeof table);
			throw "detected unsupported type";
		}
		return true;
	}
}
