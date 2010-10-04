/**
 * Evaluate current company value
 */
class Task.CurrentValue extends DailyTask
{
	constructor() {
		::DailyTask.constructor ("Current Value", 7);
		SetKey (30);
	}

	function On_Start() {
		SetResult (AICompany.GetCompanyValue (My.ID));
		local date = AIDate.GetCurrentDate();
		local upday = max(1, date - AIDate.GetDate(AIDate.GetYear(date), 1, 1));
		Warn ("===" + Assist.DateStr (date) +"===>" + GetResult());
		local lst = AIVehicleList();
		lst.Valuate(AIVehicle.GetProfitThisYear);
		My._Yearly_Profit = (Assist.SumValue(lst) * 365 / upday).tointeger();
		Info ("yearly profit:", My._Yearly_Profit);
		Info ("cash:", Money.Balance (), "loan :", AICompany.GetLoanAmount());
	}
}

