/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Evaluate current company value
 */
class Task.CurrentValue extends DailyTask
{
	constructor() {
		::DailyTask.constructor("Current Value", 30);
	}

	function On_Start() {
		local cv = AICompany.GetCompanyValue(My.ID);
		local date = AIDate.GetCurrentDate();
		local upday = max(1, date - AIDate.GetDate(AIDate.GetYear(date), 1, 1));
		Warn("===" + Assist.DateStr(date) + "===>" + cv);
		local lst = AIVehicleList();
		lst.Valuate(AIVehicle.GetProfitThisYear);
		My._Yearly_Profit = (Assist.SumValue(lst) * 365 / upday).tointeger();
		Info("yearly profit:", My._Yearly_Profit);
		Info("cash:", Money.Balance(), "loan :", AICompany.GetLoanAmount());
	}
}
