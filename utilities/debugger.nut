/*  10.02.27 - debugger.nut
  *
  *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
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
	function Say (ar, num) {
		if (AIController.GetSetting ("debug_log")) {
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
			AILog[type] (Assist.Join (ar, " "));
 		}
 	}

	/**
	 * No other methode found to clear last err
	 */
	function ClearErr() {
		local mode = AITestMode();
		AISign.BuildSign (AIMap.GetTileIndex (2, 2), "debugger");
	}

	/**
	 * Evaluate expression, display message,  detect last error.
	 * usable for in-line debugging Do command
	 * @param exp Expression to be displayed and returned
	 * @param [...] Message to be displayed
	 * @return Value of expression
	 */
	function ResultOf (exp, ...) {
		local txt = [];
		for (local c = 0; c < vargc; c++) txt.push (vargv[c]);
		txt.push ("[" + exp + "]");
		txt.push ("-> ");
		if (AIError.GetLastError() == AIError.ERR_NONE) {
			txt.push ("Good Job ^_^");
			Info (Assist.Join (txt, " "));
		} else {
			txt.push (AIError.GetLastErrorString().slice (4));
			Warn (Assist.Join (txt, " "));
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
	function Echo (exp, ...) {
		local txt = [];
		for (local c = 0; c < vargc; c++) txt.push (vargv[c]);
		txt.push ("[" + exp + "]");
		txt.push ("-> ");
		if (exp) {
			txt.push ("Good Job ^_^");
			Info (Assist.Join (txt, " "));
		} else {
			txt.push ("@#$%^&*()?><:; Bad Job!");
			Warn (Assist.Join (txt, " "));
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
	function Sign (tile, txt) {
		if (AIController.GetSetting ("debug_signs")) {
			local mode = AIExecMode();
			local lst = AISignList();
			lst.Valuate (AISign.GetLocation);
			lst.KeepValue (tile);
			if (lst.Count()) AISign.RemoveSign (lst.Begin());
			return AISign.BuildSign (tile, txt);
 		}
		//Debug.Say (["Build sign is disabled"], 1);
		return -1;
 	}

 	/**
	 * Unsign is to easy check wether we have build sign before
	 * @param id Suspected signID
 	 */
	function UnSign (id) {
		if (AISign.IsValidSign (id)) AISign.RemoveSign (id);
	}

	function Halt (tile) {
		local mode = AIExecMode();
		local id = AISign.BuildSign (tile, "Debugger");
		local day = AIDate.GetCurrentDate();
		AILog.Error ("Please, goto \"Debugger\" sign");
		AILog.Error ("Attach your saved game at:" + Assist.DateStr (day));
		AILog.Error ("And report to Trans AI forum");
		while (AISign.IsValidSign (id)) AIController.Sleep (1);
		AILog.Warning ("Error has been reset");
	}
 }
